import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/recharge_models.dart';
import '../models/operator_info.dart';
import '../../core/constants/api_constants.dart';
import 'proxy_service.dart';

class RoboticsExchangeService {
  static const String _baseUrl = 'https://api.roboticexchange.in/Robotics/webservice';
  static const String _apiMemberId = '3425';
  static const String _apiPassword = 'Neela@415263';
  static const String _callbackUrl = 'https://samypay.com/Callback/310';
  
  final ProxyService _proxyService;

  RoboticsExchangeService({ProxyService? proxyService}) 
      : _proxyService = proxyService ?? ProxyService();

  void dispose() {
    _proxyService.dispose();
  }

  /// Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'TXN${timestamp}_$random';
  }

  /// Perform mobile recharge
  Future<RechargeResponse> performRecharge({
    required String mobileNumber,
    required String operatorName,
    required String circleName,
    required String amount,
    String? groupId,
  }) async {
    try {
      // Map operator and circle names to codes
      final operatorCode = OperatorMapping.getOperatorCode(operatorName);
      final circleCode = OperatorMapping.getCircleCode(circleName);
      final txnId = _generateTransactionId();

      // Build query parameters
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Mobile_no': mobileNumber,
        'Operator_code': operatorCode,
        'Amount': amount,
        'Member_request_txnid': txnId,
        'Circle': circleCode,
        if (groupId != null) 'Group_Id': groupId,
      };

      print('Recharge Request - Endpoint: /GetMobileRecharge');
      print('Recharge Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetMobileRecharge',
        queryParameters: queryParams,
      );

      print('Recharge Response Status: ${response.statusCode}');
      print('Recharge Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RechargeResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to perform recharge: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in performRecharge: $e');
      throw Exception('Recharge failed: $e');
    }
  }

  /// Check recharge status
  Future<StatusCheckResponse> checkRechargeStatus({
    required String memberRequestTxnId,
  }) async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Member_request_txnid': memberRequestTxnId,
      };

      print('Status Check Request - Endpoint: /GetStatus');
      print('Status Check Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetStatus',
        queryParameters: queryParams,
      );

      print('Status Check Response Status: ${response.statusCode}');
      print('Status Check Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return StatusCheckResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in checkRechargeStatus: $e');
      throw Exception('Status check failed: $e');
    }
  }

  /// Get wallet balance
  Future<WalletBalanceResponse> getWalletBalance() async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
      };

      print('Wallet Balance Request - Endpoint: /GetWalletBalance');
      print('Wallet Balance Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetWalletBalance',
        queryParameters: queryParams,
      );

      print('Wallet Balance Response Status: ${response.statusCode}');
      print('Wallet Balance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return WalletBalanceResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to get wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getWalletBalance: $e');
      throw Exception('Wallet balance check failed: $e');
    }
  }

  /// Get operator balance
  Future<OperatorBalanceResponse> getOperatorBalance() async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
      };

      print('Operator Balance Request - Endpoint: /OperatorBalance');
      print('Operator Balance Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/OperatorBalance',
        queryParameters: queryParams,
      );

      print('Operator Balance Response Status: ${response.statusCode}');
      print('Operator Balance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OperatorBalanceResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to get operator balance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOperatorBalance: $e');
      throw Exception('Operator balance check failed: $e');
    }
  }

  /// Submit recharge complaint
  Future<RechargeComplaintResponse> submitRechargeComplaint({
    required String memberRequestTxnId,
    required String ourRefTxnId,
    required String complaintReason,
  }) async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Member_request_txnid': memberRequestTxnId,
        'OurRefTxnId': ourRefTxnId,
        'ComplaintReason': complaintReason,
      };

      print('Recharge Complaint Request - Endpoint: /RechargeComplaint');
      print('Recharge Complaint Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/RechargeComplaint',
        queryParameters: queryParams,
      );

      print('Recharge Complaint Response Status: ${response.statusCode}');
      print('Recharge Complaint Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RechargeComplaintResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to submit complaint: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in submitRechargeComplaint: $e');
      throw Exception('Complaint submission failed: $e');
    }
  }

  /// Update IP address for auto IP update
  Future<bool> updateIpAddress(String ipAddress) async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Ipaddress': ipAddress,
      };

      print('IP Update Request - Endpoint: /GetIpUpdate');
      print('IP Update Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetIpUpdate',
        queryParameters: queryParams,
      );

      print('IP Update Response Status: ${response.statusCode}');
      print('IP Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['status'] == 1;
      } else {
        return false;
      }
    } catch (e) {
      print('Error in updateIpAddress: $e');
      return false;
    }
  }

  /// Get LAPU wise balance (for Airtel and Idea)
  Future<Map<String, dynamic>?> getLapuWiseBalance(String operatorCode) async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Operator_code': operatorCode,
      };

      print('LAPU Balance Request - Endpoint: /GetLapuWiseBal');
      print('LAPU Balance Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetLapuWiseBal',
        queryParameters: queryParams,
      );

      print('LAPU Balance Response Status: ${response.statusCode}');
      print('LAPU Balance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return null;
      }
    } catch (e) {
      print('Error in getLapuWiseBalance: $e');
      return null;
    }
  }

  /// Check LAPU purchase (for Airtel and Idea)
  Future<Map<String, dynamic>?> checkLapuPurchase({
    required String lapuNumber,
    required String operatorCode,
  }) async {
    try {
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'LapuNumber': lapuNumber,
        'Operator_code': operatorCode,
      };

      print('LAPU Purchase Request - Endpoint: /GetPurchase');
      print('LAPU Purchase Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetPurchase',
        queryParameters: queryParams,
      );

      print('LAPU Purchase Response Status: ${response.statusCode}');
      print('LAPU Purchase Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return null;
      }
    } catch (e) {
      print('Error in checkLapuPurchase: $e');
      return null;
    }
  }

  /// Perform recharge with OperatorInfo object
  Future<RechargeResponse> performRechargeWithOperatorInfo({
    required String mobileNumber,
    required OperatorInfo operatorInfo,
    required String amount,
    String? groupId,
  }) async {
    return performRecharge(
      mobileNumber: mobileNumber,
      operatorName: operatorInfo.operator,
      circleName: operatorInfo.circle,
      amount: amount,
      groupId: groupId,
    );
  }

  /// Validate recharge amount
  bool validateRechargeAmount(String amount) {
    try {
      final amountValue = double.parse(amount);
      return amountValue >= 10 && amountValue <= 25000;
    } catch (e) {
      return false;
    }
  }

  /// Get recharge status from response
  RechargeStatus getRechargeStatusFromResponse(RechargeResponse response) {
    if (response.isSuccess) {
      return RechargeStatus.success;
    } else if (response.isFailed) {
      return RechargeStatus.failed;
    } else if (response.isProcessing) {
      return RechargeStatus.processing;
    } else {
      return RechargeStatus.pending;
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(String errorCode) {
    return RechargeErrorCodes.getErrorMessage(errorCode);
  }

  /// Check if operator supports R-offers
  bool supportsROffers(String operatorName) {
    final supportedOperators = ['AIRTEL', 'VODAFONEIDEA', 'VI'];
    return supportedOperators.contains(operatorName.toUpperCase());
  }

  /// Get callback URL with parameters
  String getCallbackUrl({
    required String status,
    required String operatorId,
    required String memberTxnId,
    required String txnId,
    required String number,
    required String amount,
    required String message,
  }) {
    return '$_callbackUrl?status=$status&operatorid=$operatorId&agentid=$memberTxnId&txnid=$txnId&number=$number&amount=$amount&message=${Uri.encodeComponent(message)}';
  }
} 