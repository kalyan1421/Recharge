import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/api_constants.dart';
import 'recharge_service.dart';

class CorrectedLiveRechargeService {
  static final CorrectedLiveRechargeService _instance = CorrectedLiveRechargeService._internal();
  factory CorrectedLiveRechargeService() => _instance;
  CorrectedLiveRechargeService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Enhanced recharge processing with comprehensive error handling
  Future<RechargeResult> processLiveRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int planAmount,
    required String planDescription,
    required String validity,
    required double walletBalance,
  }) async {
    try {
      _logger.i('🚀 Starting live recharge process');
      _logger.i('Mobile: ${_maskMobileNumber(mobileNumber)}');
      _logger.i('Operator: $operatorName ($operatorCode)');
      _logger.i('Amount: ₹$planAmount');
      _logger.i('Circle: $circleCode');

      // Validate input parameters
      if (planAmount <= 0) {
        throw Exception('Invalid recharge amount: ₹$planAmount');
      }

      if (walletBalance < planAmount) {
        throw Exception('Insufficient wallet balance. Available: ₹$walletBalance, Required: ₹$planAmount');
      }

      // Generate unique transaction ID
      final transactionId = _generateTransactionId();
      _logger.i('Generated Transaction ID: $transactionId');

      // Convert operator code to Robotics Exchange format
      final roboticsOperatorCode = _convertOperatorCodeToRobotics(operatorCode);
      _logger.i('Converted operator code: $operatorCode -> $roboticsOperatorCode');

      // Attempt recharge with retry logic
      RechargeResult result = await _processRechargeWithRetry(
        userId: userId,
        mobileNumber: mobileNumber,
        operatorCode: roboticsOperatorCode,
        operatorName: operatorName,
        circleCode: circleCode,
        planAmount: planAmount,
        planDescription: planDescription,
        validity: validity,
        transactionId: transactionId,
      );

      // Save transaction to Firebase
      await _saveTransactionToFirebase(
        userId: userId,
        transactionId: transactionId,
        mobileNumber: mobileNumber,
        operatorCode: operatorCode,
        operatorName: operatorName,
        planAmount: planAmount,
        planDescription: planDescription,
        validity: validity,
        status: result.status,
        message: result.message,
        operatorTransactionId: result.operatorTransactionId,
        apiResponse: {
          'success': result.success,
          'status': result.status,
          'message': result.message,
        },
      );

      return result;

    } catch (e) {
      _logger.e('❌ Live recharge failed: $e');
      
      // Return failed result
      return RechargeResult(
        success: false,
        status: 'FAILED',
        message: 'Recharge failed: ${e.toString()}',
        transactionId: _generateTransactionId(),
        amount: planAmount.toDouble(),
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        mobileNumber: mobileNumber,
        operatorName: operatorName,
        planDescription: planDescription,
        validity: validity,
      );
    }
  }

  /// Process recharge with retry logic
  Future<RechargeResult> _processRechargeWithRetry({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int planAmount,
    required String planDescription,
    required String validity,
    required String transactionId,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        _logger.i('Recharge attempt ${retryCount + 1}/$_maxRetries');
        
        return await _processRoboticsRecharge(
          mobileNumber: mobileNumber,
          operatorCode: operatorCode,
          operatorName: operatorName,
          circleCode: circleCode,
          planAmount: planAmount,
          planDescription: planDescription,
          validity: validity,
          transactionId: transactionId,
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        retryCount++;
        
        _logger.w('Recharge attempt ${retryCount} failed: $e');
        
        if (retryCount < _maxRetries) {
          _logger.i('Retrying in ${_retryDelay.inSeconds} seconds...');
          await Future.delayed(_retryDelay);
        }
      }
    }

    // All retries failed
    throw lastException ?? Exception('Recharge failed after $retryCount attempts');
  }

  /// Process recharge using Robotics Exchange API
  Future<RechargeResult> _processRoboticsRecharge({
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int planAmount,
    required String planDescription,
    required String validity,
    required String transactionId,
  }) async {
    try {
      _logger.i('Processing recharge with Robotics Exchange API');
      
      // Build the recharge URL with correct parameters
      final uri = Uri.parse(APIConstants.roboticsRechargeUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Mobile_no': mobileNumber,
        'Operator_code': operatorCode,
        'Amount': planAmount.toString(),
        'Member_request_txnid': transactionId,
        'Circle': circleCode,
      });

      _logger.d('Recharge URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      _logger.d('Robotics Response Status: ${response.statusCode}');
      _logger.d('Robotics Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);
        
        // Parse response based on Robotics Exchange API format
        final errorCode = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown error';
        final orderId = apiResponse['ORDERID']?.toString() ?? transactionId;
        final operatorTxnId = apiResponse['OPTRANSID']?.toString();
        final balance = apiResponse['CLOSINGBAL']?.toString();
        final commission = apiResponse['COMMISSION']?.toString();

        _logger.i('Robotics API Response - Error: $errorCode, Status: $status, Message: $message');

        if (errorCode == '0' && status == '1') {
          // Success case
          return RechargeResult(
            success: true,
            status: 'SUCCESS',
            message: message,
            transactionId: orderId,
            amount: planAmount.toDouble(),
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            planDescription: planDescription,
            validity: validity,
          );
        } else if (errorCode == '1' && status == '2') {
          // Processing case
          return RechargeResult(
            success: true,
            status: 'PROCESSING',
            message: 'Recharge is being processed',
            transactionId: orderId,
            amount: planAmount.toDouble(),
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            planDescription: planDescription,
            validity: validity,
          );
        } else {
          // Failed case
          return RechargeResult(
            success: false,
            status: 'FAILED',
            message: message,
            transactionId: orderId,
            amount: planAmount.toDouble(),
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            planDescription: planDescription,
            validity: validity,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

    } catch (e) {
      _logger.e('Error in robotics recharge: $e');
      rethrow;
    }
  }

  /// Convert PlanAPI operator code to Robotics Exchange format
  String _convertOperatorCodeToRobotics(String operatorCode) {
    return APIConstants.planApiToRoboticsMapping[operatorCode] ?? 'JO'; // Default to Jio
  }

  /// Check recharge status
  Future<RechargeResult?> checkRechargeStatus(String transactionId) async {
    try {
      _logger.i('Checking recharge status for transaction: $transactionId');
      
      final uri = Uri.parse(APIConstants.roboticsStatusCheckUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Member_request_txnid': transactionId,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      _logger.d('Status Check Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);
        
        final errorCode = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown status';
        final orderId = apiResponse['ORDERID']?.toString() ?? transactionId;
        final operatorTxnId = apiResponse['OPTRANSID']?.toString();

        String rechargeStatus = 'UNKNOWN';
        bool isSuccess = false;

        if (errorCode == '0' && status == '1') {
          rechargeStatus = 'SUCCESS';
          isSuccess = true;
        } else if (errorCode == '1' && status == '2') {
          rechargeStatus = 'PROCESSING';
          isSuccess = true;
        } else {
          rechargeStatus = 'FAILED';
          isSuccess = false;
        }

        return RechargeResult(
          success: isSuccess,
          status: rechargeStatus,
          message: message,
          transactionId: orderId,
          amount: 0.0, // Amount not returned in status check
          operatorTransactionId: operatorTxnId,
          timestamp: DateTime.now(),
          mobileNumber: '',
          operatorName: '',
          planDescription: '',
          validity: '',
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return null;
    }
  }

  /// Check wallet balance
  Future<Map<String, dynamic>> checkWalletBalance() async {
    try {
      _logger.i('Checking wallet balance');
      
      final uri = Uri.parse(APIConstants.roboticsWalletBalanceUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      _logger.d('Wallet Balance Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);
        return apiResponse;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('Error checking wallet balance: $e');
      return {
        'ERROR': '1',
        'MESSAGE': 'Failed to check wallet balance: ${e.toString()}',
      };
    }
  }

  /// Save transaction to Firebase
  Future<void> _saveTransactionToFirebase({
    required String userId,
    required String transactionId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required int planAmount,
    required String planDescription,
    required String validity,
    required String status,
    required String message,
    String? operatorTransactionId,
    Map<String, dynamic>? apiResponse,
  }) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).set({
        'userId': userId,
        'transactionId': transactionId,
        'mobileNumber': mobileNumber,
        'operatorCode': operatorCode,
        'operatorName': operatorName,
        'amount': planAmount,
        'planDescription': planDescription,
        'validity': validity,
        'status': status,
        'message': message,
        'operatorTransactionId': operatorTransactionId,
        'timestamp': FieldValue.serverTimestamp(),
        'apiResponse': apiResponse,
      });
      
      _logger.i('✅ Transaction saved to Firebase');
    } catch (e) {
      _logger.e('Error saving transaction to Firebase: $e');
      // Don't throw error as transaction might still be successful
    }
  }

  /// Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'TXN_${timestamp}_$random';
  }

  /// Mask mobile number for privacy
  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }
} 