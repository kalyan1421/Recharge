import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/recharge_request.dart';
import '../repositories/recharge_repository.dart';
import '../../domain/entities/user.dart';

class RechargeService {
  static final RechargeService _instance = RechargeService._internal();
  factory RechargeService() => _instance;
  RechargeService._internal();

  final Logger _logger = Logger();
  final RechargeRepository _repository = RechargeRepository();

  /// Process a mobile recharge
  Future<RechargeResult> processRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circle,
    required int planAmount,
    required String planDescription,
    required String validity,
  }) async {
    try {
      _logger.i('Processing recharge for: $mobileNumber - ₹$planAmount');

      // Generate unique request ID
      final requestId = 'REQ_${DateTime.now().millisecondsSinceEpoch}_${mobileNumber.substring(mobileNumber.length - 4)}';

      // Create recharge request
      final request = RechargeRequest(
        userId: userId,
        mobile: mobileNumber,
        operatorCode: operatorCode,
        operatorType: _mapOperatorName(operatorName),
        serviceType: ServiceType.prepaid,
        amount: planAmount.toDouble(),
        circle: circle,
        planId: '${planAmount}_plan',
        additionalParams: {
          'description': planDescription,
          'validity': validity,
          'operatorName': operatorName,
        },
        requestId: requestId,
        timestamp: DateTime.now(),
      );

      // Process recharge through repository
      final response = await _repository.processRecharge(request);

      _logger.i('Recharge response: ${response.status} - ${response.message}');

      return RechargeResult(
        success: response.status == 'SUCCESS',
        transactionId: response.transactionId,
        status: response.status,
        message: response.message,
        amount: response.amount,
        operatorTransactionId: response.operatorTransactionId,
        timestamp: response.timestamp,
        mobileNumber: mobileNumber,
        operatorName: operatorName,
        planDescription: planDescription,
        validity: validity,
      );
    } catch (e) {
      _logger.e('Error processing recharge: $e');
      
      return RechargeResult(
        success: false,
        transactionId: '',
        status: 'FAILED',
        message: 'Recharge failed: ${e.toString()}',
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

  /// Get recharge history for a user
  Future<List<RechargeResult>> getRechargeHistory(String userId, {int limit = 20}) async {
    try {
      final responses = await _repository.getRechargeHistory(userId, limit: limit);
      
      return responses.map((response) => RechargeResult(
        success: response.status == 'SUCCESS',
        transactionId: response.transactionId,
        status: response.status,
        message: response.message,
        amount: response.amount,
        operatorTransactionId: response.operatorTransactionId,
        timestamp: response.timestamp,
        mobileNumber: response.additionalData?['mobile'] ?? '',
        operatorName: response.additionalData?['operatorName'] ?? '',
        planDescription: response.additionalData?['description'] ?? '',
        validity: response.additionalData?['validity'] ?? '',
      )).toList();
    } catch (e) {
      _logger.e('Error fetching recharge history: $e');
      return [];
    }
  }

  /// Check recharge status
  Future<RechargeResult?> checkRechargeStatus(String transactionId) async {
    try {
      final response = await _repository.getRechargeStatus(transactionId);
      
      if (response != null) {
        return RechargeResult(
          success: response.status == 'SUCCESS',
          transactionId: response.transactionId,
          status: response.status,
          message: response.message,
          amount: response.amount,
          operatorTransactionId: response.operatorTransactionId,
          timestamp: response.timestamp,
          mobileNumber: response.additionalData?['mobile'] ?? '',
          operatorName: response.additionalData?['operatorName'] ?? '',
          planDescription: response.additionalData?['description'] ?? '',
          validity: response.additionalData?['validity'] ?? '',
        );
      }
      return null;
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return null;
    }
  }

  /// Check if recharge service is available
  Future<bool> isServiceAvailable() async {
    try {
      final status = await _repository.checkProviderStatus();
      return status['status'] == 'active';
    } catch (e) {
      _logger.e('Error checking service availability: $e');
      return false;
    }
  }

  /// Map operator name to enum
  OperatorType _mapOperatorName(String operatorName) {
    switch (operatorName.toLowerCase()) {
      case 'jio':
        return OperatorType.jio;
      case 'airtel':
        return OperatorType.airtel;
      case 'vi':
      case 'vodafone':
      case 'idea':
        return OperatorType.vi;
      case 'bsnl':
        return OperatorType.bsnl;
      default:
        return OperatorType.jio; // Default fallback
    }
  }
}

/// Result class for recharge operations
class RechargeResult {
  final bool success;
  final String transactionId;
  final String status;
  final String message;
  final double amount;
  final String? operatorTransactionId;
  final DateTime timestamp;
  final String mobileNumber;
  final String operatorName;
  final String planDescription;
  final String validity;

  const RechargeResult({
    required this.success,
    required this.transactionId,
    required this.status,
    required this.message,
    required this.amount,
    this.operatorTransactionId,
    required this.timestamp,
    required this.mobileNumber,
    required this.operatorName,
    required this.planDescription,
    required this.validity,
  });

  /// Get status color
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF4CAF50); // Green
      case 'FAILED':
        return const Color(0xFFF44336); // Red
      case 'PENDING':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get status icon
  IconData get statusIcon {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.error;
      case 'PENDING':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  /// Get formatted amount
  String get formattedAmount => '₹${amount.toInt()}';

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
} 