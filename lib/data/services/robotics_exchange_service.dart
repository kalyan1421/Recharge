import 'package:logger/logger.dart';
import 'robotics_wallet_service.dart';
import 'robotics_status_service.dart';
import '../repositories/recharge_repository.dart';
import '../models/recharge_request.dart';

/// Comprehensive service for all Robotics Exchange API operations
class RoboticsExchangeService {
  static final RoboticsExchangeService _instance = RoboticsExchangeService._internal();
  factory RoboticsExchangeService() => _instance;
  RoboticsExchangeService._internal();

  final Logger _logger = Logger();
  final RoboticsWalletService _walletService = RoboticsWalletService();
  final RoboticsStatusService _statusService = RoboticsStatusService();
  final RechargeRepository _rechargeRepository = RechargeRepository();

  /// Process a mobile recharge using robotics exchange
  Future<RechargeServiceResult> processRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circle,
    required double amount,
    String? planId,
    String? planDescription,
    String? validity,
  }) async {
    try {
      _logger.i('Processing recharge with Robotics Exchange: $mobileNumber - ₹$amount');

      // Check wallet balance before processing
      final walletBalance = await _walletService.checkWalletBalance();
      if (!walletBalance.success) {
        return RechargeServiceResult(
          success: false,
          message: 'Failed to check wallet balance: ${walletBalance.message}',
          transactionId: null,
          status: 'FAILED',
          timestamp: DateTime.now(),
        );
      }

      if (walletBalance.buyerBalance < amount) {
        return RechargeServiceResult(
          success: false,
          message: 'Insufficient wallet balance. Available: ₹${walletBalance.buyerBalance.toStringAsFixed(2)}',
          transactionId: null,
          status: 'FAILED',
          timestamp: DateTime.now(),
        );
      }

      // Create recharge request
      final request = RechargeRequest(
        userId: userId,
        mobile: mobileNumber,
        operatorCode: operatorCode,
        operatorType: _mapOperatorCode(operatorCode),
        serviceType: ServiceType.prepaid,
        amount: amount,
        circle: circle,
        planId: planId,
        additionalParams: {
          'operatorName': operatorName,
          'planDescription': planDescription ?? '',
          'validity': validity ?? '',
        },
        requestId: 'RBX_${DateTime.now().millisecondsSinceEpoch}_${mobileNumber.substring(mobileNumber.length - 4)}',
        timestamp: DateTime.now(),
      );

      // Process recharge
      final response = await _rechargeRepository.processRecharge(request);

      return RechargeServiceResult(
        success: response.status == 'SUCCESS',
        message: response.message,
        transactionId: response.transactionId,
        status: response.status,
        timestamp: response.timestamp,
        amount: response.amount,
        operatorTransactionId: response.operatorTransactionId,
        balanceAfter: response.balance,
        additionalData: response.additionalData,
      );
    } catch (e) {
      _logger.e('Error processing recharge: $e');
      return RechargeServiceResult(
        success: false,
        message: 'Recharge failed: ${e.toString()}',
        transactionId: null,
        status: 'FAILED',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Check recharge status
  Future<RechargeServiceResult> checkRechargeStatus(String memberRequestTxnId) async {
    try {
      final response = await _statusService.checkRechargeStatus(memberRequestTxnId);
      
      return RechargeServiceResult(
        success: response.success,
        message: response.message,
        transactionId: response.orderId,
        status: response.rechargeStatus,
        timestamp: response.timestamp,
        amount: response.amount,
        operatorTransactionId: response.operatorTransactionId,
        balanceAfter: response.closingBalance,
        additionalData: response.toJson(),
      );
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return RechargeServiceResult(
        success: false,
        message: 'Status check failed: ${e.toString()}',
        transactionId: memberRequestTxnId,
        status: 'UNKNOWN',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get wallet balance
  Future<WalletBalanceResult> getWalletBalance() async {
    try {
      final response = await _walletService.checkWalletBalance();
      
      return WalletBalanceResult(
        success: response.success,
        message: response.message,
        buyerBalance: response.buyerBalance,
        sellerBalance: response.sellerBalance,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _logger.e('Error getting wallet balance: $e');
      return WalletBalanceResult(
        success: false,
        message: 'Failed to get wallet balance: ${e.toString()}',
        buyerBalance: 0.0,
        sellerBalance: 0.0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get operator balances
  Future<OperatorBalanceResult> getOperatorBalances() async {
    try {
      final response = await _walletService.checkOperatorBalances();
      
      return OperatorBalanceResult(
        success: response.success,
        message: response.message,
        balances: response.balances,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _logger.e('Error getting operator balances: $e');
      return OperatorBalanceResult(
        success: false,
        message: 'Failed to get operator balances: ${e.toString()}',
        balances: {},
        timestamp: DateTime.now(),
      );
    }
  }

  /// File a complaint for failed recharge
  Future<ComplaintResult> fileComplaint({
    required String memberRequestTxnId,
    required String ourRefTxnId,
    required String complaintReason,
  }) async {
    try {
      final response = await _statusService.fileRechargeComplaint(
        memberRequestTxnId: memberRequestTxnId,
        ourRefTxnId: ourRefTxnId,
        complaintReason: complaintReason,
      );
      
      return ComplaintResult(
        success: response.success,
        message: response.message,
        memberRequestId: response.memberRequestId,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _logger.e('Error filing complaint: $e');
      return ComplaintResult(
        success: false,
        message: 'Failed to file complaint: ${e.toString()}',
        memberRequestId: null,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Check lapu balance for operator
  Future<LapuBalanceResult> checkLapuBalance(String operatorCode) async {
    try {
      final response = await _walletService.checkLapuBalance(operatorCode);
      
      return LapuBalanceResult(
        success: response.success,
        message: response.message,
        lapuData: response.lapuData,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _logger.e('Error checking lapu balance: $e');
      return LapuBalanceResult(
        success: false,
        message: 'Failed to check lapu balance: ${e.toString()}',
        lapuData: [],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Update IP address
  Future<IpUpdateResult> updateIpAddress(String ipAddress) async {
    try {
      final response = await _walletService.updateIpAddress(ipAddress);
      
      return IpUpdateResult(
        success: response.success,
        message: response.message,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _logger.e('Error updating IP address: $e');
      return IpUpdateResult(
        success: false,
        message: 'Failed to update IP address: ${e.toString()}',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Check service health
  Future<ServiceHealthResult> checkServiceHealth() async {
    try {
      final walletCheck = await _walletService.checkWalletBalance();
      final operatorCheck = await _walletService.checkOperatorBalances();
      
      final isHealthy = walletCheck.success && operatorCheck.success;
      
      return ServiceHealthResult(
        isHealthy: isHealthy,
        message: isHealthy ? 'Service is healthy' : 'Service has issues',
        walletServiceOk: walletCheck.success,
        operatorServiceOk: operatorCheck.success,
        timestamp: DateTime.now(),
        details: {
          'walletService': walletCheck.message,
          'operatorService': operatorCheck.message,
        },
      );
    } catch (e) {
      _logger.e('Error checking service health: $e');
      return ServiceHealthResult(
        isHealthy: false,
        message: 'Health check failed: ${e.toString()}',
        walletServiceOk: false,
        operatorServiceOk: false,
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// Helper method to map operator code to enum
  OperatorType _mapOperatorCode(String operatorCode) {
    switch (operatorCode.toUpperCase()) {
      case 'AIRTEL':
        return OperatorType.airtel;
      case 'JIO':
        return OperatorType.jio;
      case 'VODAFONE':
      case 'VI':
      case 'IDEA':
        return OperatorType.vi;
      case 'BSNL':
        return OperatorType.bsnl;
      default:
        return OperatorType.airtel;
    }
  }
}

/// Result classes for unified service interface
class RechargeServiceResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String status;
  final DateTime timestamp;
  final double? amount;
  final String? operatorTransactionId;
  final double? balanceAfter;
  final Map<String, dynamic>? additionalData;

  RechargeServiceResult({
    required this.success,
    required this.message,
    this.transactionId,
    required this.status,
    required this.timestamp,
    this.amount,
    this.operatorTransactionId,
    this.balanceAfter,
    this.additionalData,
  });
}

class WalletBalanceResult {
  final bool success;
  final String message;
  final double buyerBalance;
  final double sellerBalance;
  final DateTime timestamp;

  WalletBalanceResult({
    required this.success,
    required this.message,
    required this.buyerBalance,
    required this.sellerBalance,
    required this.timestamp,
  });
}

class OperatorBalanceResult {
  final bool success;
  final String message;
  final Map<String, dynamic> balances;
  final DateTime timestamp;

  OperatorBalanceResult({
    required this.success,
    required this.message,
    required this.balances,
    required this.timestamp,
  });
}

class ComplaintResult {
  final bool success;
  final String message;
  final String? memberRequestId;
  final DateTime timestamp;

  ComplaintResult({
    required this.success,
    required this.message,
    this.memberRequestId,
    required this.timestamp,
  });
}

class LapuBalanceResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> lapuData;
  final DateTime timestamp;

  LapuBalanceResult({
    required this.success,
    required this.message,
    required this.lapuData,
    required this.timestamp,
  });
}

class IpUpdateResult {
  final bool success;
  final String message;
  final DateTime timestamp;

  IpUpdateResult({
    required this.success,
    required this.message,
    required this.timestamp,
  });
}

class ServiceHealthResult {
  final bool isHealthy;
  final String message;
  final bool walletServiceOk;
  final bool operatorServiceOk;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  ServiceHealthResult({
    required this.isHealthy,
    required this.message,
    required this.walletServiceOk,
    required this.operatorServiceOk,
    required this.timestamp,
    required this.details,
  });
} 