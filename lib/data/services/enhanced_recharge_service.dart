import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/wallet_models.dart';
import '../models/recharge_models.dart';
import '../../core/constants/api_constants.dart';
import 'wallet_service.dart';
import 'robotics_exchange_service.dart';

class EnhancedRechargeService {
  final WalletService _walletService;
  final RoboticsExchangeService _roboticsService;
  final Logger _logger = Logger();
  
  EnhancedRechargeService({
    WalletService? walletService,
    RoboticsExchangeService? roboticsService,
  }) : _walletService = walletService ?? WalletService(),
       _roboticsService = roboticsService ?? RoboticsExchangeService();

  /// Main recharge processing method with complete wallet integration
  Future<RechargeResult> processRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorName,
    required String circleName,
    required double amount,
  }) async {
    String? walletTransactionId;
    bool walletDeducted = false; // Track if wallet was actually deducted
    
    try {
      _logger.i('Starting recharge process: userId=$userId, mobile=$mobileNumber, operator=$operatorName, circle=$circleName, amount=₹$amount');
      
      // Step 1: Validate inputs
      _validateRechargeInputs(mobileNumber, operatorName, circleName, amount);
      
      // Step 2: Clean mobile number
      final cleanMobileNumber = APIConstants.cleanMobileNumber(mobileNumber);
      
      // Step 3: Generate transaction ID
      final rechargeTransactionId = _generateTransactionId();
      walletTransactionId = rechargeTransactionId;
      
      _logger.i('Generated transaction ID: $rechargeTransactionId');
      
      // Step 4: Check if recharge can be processed (only user wallet)
      final userBalance = await _walletService.getUserWalletBalance(userId);
      if (userBalance < amount) {
        throw InsufficientBalanceException(
          message: 'Insufficient wallet balance. Available: ₹$userBalance, Required: ₹$amount',
          availableBalance: userBalance,
          requiredAmount: amount,
        );
      }
      
      // Step 5: Process wallet deduction
      _logger.i('Processing wallet deduction for user: $userId, amount: ₹$amount');
      final walletDeduction = await _walletService.processWalletDeduction(
        userId: userId,
        amount: amount,
        purpose: 'Mobile Recharge: $cleanMobileNumber ($operatorName)',
        transactionId: walletTransactionId,
      );
      
      walletDeducted = true; // Mark that wallet was successfully deducted
      _logger.i('Wallet deduction successful: ${walletDeduction.transactionId}, newBalance: ₹${walletDeduction.newBalance}');
      
      // Step 6: Get operator and circle codes
      final operatorCode = APIConstants.getRoboticsOperatorCode(operatorName);
      final circleCode = APIConstants.getCircleCode(circleName);
      
      _logger.i('Mapped codes: operator=$operatorName->$operatorCode, circle=$circleName->$circleCode');
      
      // Step 7: Perform recharge via Robotics Exchange
      _logger.i('Initiating recharge via Robotics Exchange');
      final rechargeResponse = await _roboticsService.performRecharge(
        mobileNumber: cleanMobileNumber,
        operatorName: operatorName,
        circleName: circleName,
        amount: amount.toString(),
      );
      
      _logger.i('Recharge response: status=${rechargeResponse.status}, message=${rechargeResponse.message}');
      
      // Step 8: Update transaction status based on recharge response
      await _walletService.updateTransactionStatus(
        transactionId: walletTransactionId,
        status: _getTransactionStatus(rechargeResponse),
        rechargeResponse: rechargeResponse.toJson(),
        operatorTransactionId: rechargeResponse.opTransId,
      );
      
      // Step 9: Handle recharge response
      if (rechargeResponse.isSuccess) {
        _logger.i('Recharge successful: orderId=${rechargeResponse.orderId}');
        
        return RechargeResult(
          success: true,
          transactionId: rechargeResponse.orderId ?? rechargeTransactionId,
          message: rechargeResponse.message,
          operatorTransactionId: rechargeResponse.opTransId,
          status: 'SUCCESS',
          amount: amount,
          mobileNumber: cleanMobileNumber,
        );
      } else if (rechargeResponse.isProcessing) {
        _logger.i('Recharge is processing: orderId=${rechargeResponse.orderId}');
        
        // For processing status, we keep the amount deducted
        // and will check status later
        return RechargeResult(
          success: true,
          transactionId: rechargeResponse.orderId ?? rechargeTransactionId,
          message: 'Recharge is being processed. You will receive confirmation shortly.',
          operatorTransactionId: rechargeResponse.opTransId,
          status: 'PROCESSING',
          amount: amount,
          mobileNumber: cleanMobileNumber,
        );
      } else {
        _logger.w('Recharge failed: ${rechargeResponse.message}');
        
        // Recharge failed - initiate refund
        await _walletService.refundToUserWallet(
          userId: userId,
          originalTransactionId: walletTransactionId,
          amount: amount,
          reason: rechargeResponse.message,
        );
        
        return RechargeResult(
          success: false,
          transactionId: rechargeResponse.orderId ?? rechargeTransactionId,
          message: rechargeResponse.message,
          operatorTransactionId: rechargeResponse.opTransId,
          status: 'FAILED',
          amount: amount,
          mobileNumber: cleanMobileNumber,
        );
      }
    } catch (e) {
      _logger.e('Error in recharge process: $e');
      
      // Only refund if wallet was actually deducted and it's not an insufficient balance error
      if (walletDeducted && walletTransactionId != null && e is! InsufficientBalanceException) {
        try {
          _logger.i('Initiating refund for failed recharge');
          await _walletService.refundToUserWallet(
            userId: userId,
            originalTransactionId: walletTransactionId,
            amount: amount,
            reason: 'Recharge failed: ${e.toString()}',
          );
          _logger.i('Refund processed successfully');
        } catch (refundError) {
          _logger.e('Error processing refund: $refundError');
        }
      }
      
      // Re-throw specific exceptions
      if (e is InsufficientBalanceException || 
          e is ValidationException) {
        rethrow;
      }
      
      throw RechargeException('Recharge failed: ${e.toString()}');
    }
  }
  
  /// Check recharge status and update transaction accordingly
  Future<RechargeResult> checkRechargeStatus(String memberRequestTxnId) async {
    try {
      _logger.i('Checking recharge status for transaction: $memberRequestTxnId');
      
      final statusResponse = await _roboticsService.checkRechargeStatus(
        memberRequestTxnId: memberRequestTxnId,
      );
      
      // Update transaction status in Firestore
      return RechargeResult(
        success: statusResponse.isSuccess,
        transactionId: statusResponse.orderId,
        message: statusResponse.message,
        operatorTransactionId: statusResponse.opTransId,
        status: statusResponse.isSuccess ? 'SUCCESS' 
               : statusResponse.isProcessing ? 'PROCESSING' 
               : 'FAILED',
        amount: double.tryParse(statusResponse.amount),
        mobileNumber: statusResponse.mobileNo,
      );
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return RechargeResult(
        success: false,
        transactionId: memberRequestTxnId,
        message: 'Status check failed: ${e.toString()}',
        status: 'FAILED',
      );
    }
  }
  
  /// Get user's recharge history
  Future<List<WalletTransaction>> getRechargeHistory(String userId, {int limit = 50}) async {
    try {
      return await _walletService.getTransactionHistory(userId, limit: limit);
    } catch (e) {
      _logger.e('Error getting recharge history: $e');
      throw RechargeException('Failed to get recharge history: ${e.toString()}');
    }
  }
  
  /// Validate recharge inputs
  void _validateRechargeInputs(String mobileNumber, String operatorName, String circleName, double amount) {
    // Validate mobile number
    if (!APIConstants.isValidMobileNumber(mobileNumber)) {
      throw ValidationException('Invalid mobile number. Please enter a valid 10-digit Indian mobile number.', field: 'mobileNumber');
    }
    
    // Validate operator name
    if (operatorName.isEmpty) {
      throw ValidationException('Operator name is required.', field: 'operatorName');
    }
    
    // Validate circle name
    if (circleName.isEmpty) {
      throw ValidationException('Circle name is required.', field: 'circleName');
    }
    
    // Validate amount
    if (!APIConstants.isValidRechargeAmount(amount)) {
      throw ValidationException(APIConstants.getRechargeAmountError(amount), field: 'amount');
    }
  }
  
  /// Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'TXN${timestamp}_$random';
  }
  
  /// Get transaction status from recharge response
  String _getTransactionStatus(RechargeResponse response) {
    if (response.isSuccess) {
      return 'completed';
    } else if (response.isProcessing) {
      return 'processing';
    } else {
      return 'failed';
    }
  }
  
  /// Get transaction status from status check response
  String _getTransactionStatusFromStatusResponse(StatusCheckResponse response) {
    if (response.isSuccess) {
      return 'completed';
    } else if (response.isProcessing) {
      return 'processing';
    } else {
      return 'failed';
    }
  }
  
  /// Process pending recharges (for background processing)
  Future<void> processPendingRecharges() async {
    try {
      _logger.i('Processing pending recharges');
      
      final pendingQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('status', isEqualTo: 'processing')
          .where('type', isEqualTo: 'debit')
          .limit(10)
          .get();
      
      for (final doc in pendingQuery.docs) {
        final data = doc.data();
        final transactionId = data['transactionId'] as String;
        
        try {
          await checkRechargeStatus(transactionId);
          _logger.i('Updated status for transaction: $transactionId');
        } catch (e) {
          _logger.e('Error updating transaction $transactionId: $e');
        }
      }
    } catch (e) {
      _logger.e('Error processing pending recharges: $e');
    }
  }
  
  /// Get operator balance from Robotics Exchange
  Future<OperatorBalanceResponse> getOperatorBalance() async {
    try {
      return await _roboticsService.getOperatorBalance();
    } catch (e) {
      _logger.e('Error getting operator balance: $e');
      throw RechargeException('Failed to get operator balance: ${e.toString()}');
    }
  }
  
  /// Submit complaint for failed recharge
  Future<RechargeComplaintResponse> submitComplaint({
    required String memberRequestTxnId,
    required String ourRefTxnId,
    required String complaintReason,
  }) async {
    try {
      return await _roboticsService.submitRechargeComplaint(
        memberRequestTxnId: memberRequestTxnId,
        ourRefTxnId: ourRefTxnId,
        complaintReason: complaintReason,
      );
    } catch (e) {
      _logger.e('Error submitting complaint: $e');
      throw RechargeException('Failed to submit complaint: ${e.toString()}');
    }
  }
  
  /// Get wallet balance (only from Firebase)
  Future<Map<String, dynamic>> getWalletBalances(String userId) async {
    try {
      final userBalance = await _walletService.getUserWalletBalance(userId);
      
      return {
        'userBalance': userBalance,
        'apiBalance': userBalance, // Use same balance for compatibility
        'apiBalanceResponse': {
          'buyerWalletBalance': userBalance,
          'sellerWalletBalance': 0.0,
          'message': 'Firebase wallet balance',
          'isSuccess': true,
        },
      };
    } catch (e) {
      _logger.e('Error getting wallet balances: $e');
      throw RechargeException('Failed to get wallet balances: ${e.toString()}');
    }
  }
  
  /// Test recharge with validation (for testing purposes)
  Future<Map<String, dynamic>> testRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorName,
    required String circleName,
    required double amount,
  }) async {
    try {
      _logger.i('Testing recharge parameters');
      
      // Validate inputs
      _validateRechargeInputs(mobileNumber, operatorName, circleName, amount);
      
      // Clean mobile number
      final cleanMobileNumber = APIConstants.cleanMobileNumber(mobileNumber);
      
      // Get operator and circle codes
      final operatorCode = APIConstants.getRoboticsOperatorCode(operatorName);
      final circleCode = APIConstants.getCircleCode(circleName);
      
      // Check wallet balances
      final walletBalances = await getWalletBalances(userId);
      
      return {
        'isValid': true,
        'cleanMobileNumber': cleanMobileNumber,
        'operatorCode': operatorCode,
        'circleCode': circleCode,
        'walletBalances': walletBalances,
        'canProcessRecharge': await _walletService.canProcessRecharge(userId, amount),
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Validate recharge amount
  bool validateRechargeAmount(double amount) {
    return _roboticsService.validateRechargeAmount(amount.toString());
  }
  
  /// Perform recharge with operator info
  Future<RechargeResult> performRechargeWithOperatorInfo({
    required String userId,
    required String mobileNumber,
    required String operatorName,
    required String circleName,
    required double amount,
  }) async {
    return processRecharge(
      userId: userId,
      mobileNumber: mobileNumber,
      operatorName: operatorName,
      circleName: circleName,
      amount: amount,
    );
  }
  
  /// Get recharge status from response
  String getRechargeStatusFromResponse(RechargeResult result) {
    return result.status;
  }
  
  /// Submit recharge complaint
  Future<RechargeComplaintResponse> submitRechargeComplaint({
    required String transactionId,
    required String reason,
  }) async {
    return _roboticsService.submitRechargeComplaint(
      memberRequestTxnId: transactionId,
      ourRefTxnId: transactionId,
      complaintReason: reason,
    );
  }
  
  /// Dispose resources
  void dispose() {
    _walletService.dispose();
    _roboticsService.dispose();
  }
} 