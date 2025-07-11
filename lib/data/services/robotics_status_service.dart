import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';

class RoboticsStatusService {
  static final RoboticsStatusService _instance = RoboticsStatusService._internal();
  factory RoboticsStatusService() => _instance;
  RoboticsStatusService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  /// Check recharge status using robotics exchange API
  Future<StatusCheckResponse> checkRechargeStatus(String memberRequestTxnId) async {
    try {
      _logger.i('Checking recharge status for transaction: $memberRequestTxnId');

      final url = Uri.parse(APIConstants.roboticsStatusCheckUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Member_request_txnid': memberRequestTxnId,
      });

      _logger.d('Status Check URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Status Check Response Status: ${response.statusCode}');
      _logger.d('Status Check Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final error = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown status';
        final orderId = apiResponse['ORDERID']?.toString() ?? memberRequestTxnId;
        final operatorTxnId = apiResponse['OPTRANSID']?.toString();
        final memberReqId = apiResponse['MEMBERREQID']?.toString();
        final closingBalance = double.tryParse(apiResponse['CLOSINGBAL']?.toString() ?? '0') ?? 0.0;
        final amount = double.tryParse(apiResponse['AMOUNT']?.toString() ?? '0') ?? 0.0;
        final lapuNo = apiResponse['LAPUNO']?.toString();
        final openingBalance = double.tryParse(apiResponse['OPNINGBAL']?.toString() ?? '0') ?? 0.0;

        String rechargeStatus;
        if (error == '0' && status == '1') {
          rechargeStatus = 'SUCCESS';
        } else if (error == '1' && status == '2') {
          rechargeStatus = 'PENDING';
        } else {
          rechargeStatus = 'FAILED';
        }

        return StatusCheckResponse(
          success: true,
          rechargeStatus: rechargeStatus,
          message: message,
          orderId: orderId,
          operatorTransactionId: operatorTxnId,
          memberRequestId: memberReqId,
          amount: amount,
          lapuNumber: lapuNo,
          openingBalance: openingBalance,
          closingBalance: closingBalance,
          timestamp: DateTime.now(),
          error: error,
          status: status,
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return StatusCheckResponse(
        success: false,
        rechargeStatus: 'UNKNOWN',
        message: 'Failed to check status: ${e.toString()}',
        orderId: memberRequestTxnId,
        operatorTransactionId: null,
        memberRequestId: null,
        amount: 0.0,
        lapuNumber: null,
        openingBalance: 0.0,
        closingBalance: 0.0,
        timestamp: DateTime.now(),
        error: '999',
        status: '3',
      );
    }
  }

  /// File a complaint for failed recharge
  Future<ComplaintResponse> fileRechargeComplaint({
    required String memberRequestTxnId,
    required String ourRefTxnId,
    required String complaintReason,
  }) async {
    try {
      _logger.i('Filing recharge complaint for transaction: $memberRequestTxnId');

      final url = Uri.parse(APIConstants.roboticsComplaintUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Member_request_txnid': memberRequestTxnId,
        'OurRefTxnId': ourRefTxnId,
        'ComplaintReason': complaintReason,
      });

      _logger.d('Complaint URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Complaint Response Status: ${response.statusCode}');
      _logger.d('Complaint Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final error = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown error';
        final memberReqId = apiResponse['MEMBERREQID']?.toString();

        return ComplaintResponse(
          success: error == '0' && status == '1',
          message: message,
          memberRequestId: memberReqId,
          timestamp: DateTime.now(),
          error: error,
          status: status,
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error filing recharge complaint: $e');
      return ComplaintResponse(
        success: false,
        message: 'Failed to file complaint: ${e.toString()}',
        memberRequestId: null,
        timestamp: DateTime.now(),
        error: '999',
        status: '3',
      );
    }
  }

  /// Check multiple recharge statuses in batch
  Future<List<StatusCheckResponse>> checkMultipleRechargeStatuses(
    List<String> memberRequestTxnIds,
  ) async {
    final List<StatusCheckResponse> responses = [];
    
    for (String txnId in memberRequestTxnIds) {
      try {
        final response = await checkRechargeStatus(txnId);
        responses.add(response);
        
        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _logger.e('Error checking status for $txnId: $e');
        responses.add(StatusCheckResponse(
          success: false,
          rechargeStatus: 'ERROR',
          message: 'Failed to check status',
          orderId: txnId,
          operatorTransactionId: null,
          memberRequestId: null,
          amount: 0.0,
          lapuNumber: null,
          openingBalance: 0.0,
          closingBalance: 0.0,
          timestamp: DateTime.now(),
          error: '999',
          status: '3',
        ));
      }
    }
    
    return responses;
  }

  /// Get pending recharges that need status checking
  Future<List<String>> getPendingRecharges() async {
    // This would typically query Firebase or local storage
    // for recharges with PENDING status
    // For now, returning empty list
    return [];
  }

  /// Update recharge status in local storage/Firebase
  Future<void> updateRechargeStatus(String txnId, StatusCheckResponse response) async {
    // This would typically update Firebase or local storage
    // with the new status information
    _logger.i('Updating recharge status for $txnId: ${response.rechargeStatus}');
  }
}

/// Response classes for status operations
class StatusCheckResponse {
  final bool success;
  final String rechargeStatus;
  final String message;
  final String orderId;
  final String? operatorTransactionId;
  final String? memberRequestId;
  final double amount;
  final String? lapuNumber;
  final double openingBalance;
  final double closingBalance;
  final DateTime timestamp;
  final String error;
  final String status;

  StatusCheckResponse({
    required this.success,
    required this.rechargeStatus,
    required this.message,
    required this.orderId,
    this.operatorTransactionId,
    this.memberRequestId,
    required this.amount,
    this.lapuNumber,
    required this.openingBalance,
    required this.closingBalance,
    required this.timestamp,
    required this.error,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'rechargeStatus': rechargeStatus,
      'message': message,
      'orderId': orderId,
      'operatorTransactionId': operatorTransactionId,
      'memberRequestId': memberRequestId,
      'amount': amount,
      'lapuNumber': lapuNumber,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'status': status,
    };
  }
}

class ComplaintResponse {
  final bool success;
  final String message;
  final String? memberRequestId;
  final DateTime timestamp;
  final String error;
  final String status;

  ComplaintResponse({
    required this.success,
    required this.message,
    this.memberRequestId,
    required this.timestamp,
    required this.error,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'memberRequestId': memberRequestId,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'status': status,
    };
  }
} 