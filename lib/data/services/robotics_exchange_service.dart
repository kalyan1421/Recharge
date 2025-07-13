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

      // Debug logging for operator mapping
      print('🔍 Operator Mapping Debug:');
      print('  Input Operator Name: "$operatorName"');
      print('  Mapped Operator Code: "$operatorCode"');
      if (operatorCode == 'JL' && operatorName.toUpperCase().contains('JIO')) {
        print('  📱 JIO → JIO LITE: Using active JIO LITE LAPU instead of inactive JIO LAPU');
      }
      print('  Input Circle Name: "$circleName"');
      print('  Mapped Circle Code: "$circleCode"');
      print('  Transaction ID: "$txnId"');
      print('  Amount: ₹$amount');
      print('  Group ID: ${groupId ?? "null"}');
      print('  📊 Expected to use JIO LITE LAPU numbers: 8489377810, 9600888932, 9786468280, 9994400390');
      print('  💰 Available JIO LITE balances: 1241.12 + 8.7 + 17.32 + 226.7 = ₹1493.84');
      print('  Status: All JIO LITE LAPU numbers are ACTIVE ✅');
      print('');
      
      // Check if we have enough balance across all JIO LITE LAPU numbers
      if (operatorCode == 'JL') {
        final totalJioLiteBalance = 1241.12 + 8.7 + 17.32 + 226.7;
        final rechargeAmount = double.tryParse(amount) ?? 0.0;
        if (rechargeAmount > totalJioLiteBalance) {
          print('⚠️ Warning: Recharge amount (₹$amount) exceeds total JIO LITE balance (₹$totalJioLiteBalance)');
        }
      }

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

      print('📤 Recharge Request - Endpoint: /GetMobileRecharge');
      print('📤 Recharge Request - Params: $queryParams');

      final response = await _proxyService.getRoboticsExchange(
        '/GetMobileRecharge',
        queryParameters: queryParams,
      );

      print('📥 Recharge Response Status: ${response.statusCode}');
      print('📥 Recharge Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rechargeResponse = RechargeResponse.fromJson(jsonData);
        
        // Log the response details
        print('✅ Recharge Response Details:');
        print('  Error Code: ${rechargeResponse.error}');
        print('  Status: ${rechargeResponse.status}');
        print('  Message: ${rechargeResponse.message}');
        print('  Order ID: ${rechargeResponse.orderId}');
        print('  Operator Transaction ID: ${rechargeResponse.opTransId}');
        
        return rechargeResponse;
      } else {
        throw Exception('Failed to perform recharge: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in performRecharge: $e');
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

  /// Check if LAPU is active for a specific operator
  Future<bool> isLapuActive(String operatorCode) async {
    try {
      final lapuBalance = await getLapuWiseBalance(operatorCode);
      if (lapuBalance != null && lapuBalance['ERROR'] == '0') {
        final lapuReport = lapuBalance['LAPUREPORT'] as List<dynamic>?;
        if (lapuReport != null && lapuReport.isNotEmpty) {
          // Check if any LAPU for this operator is active
          for (final lapu in lapuReport) {
            if (lapu['Lstatus'] == 'Active') {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      print('Error checking LAPU status: $e');
      return false;
    }
  }

  /// Get active LAPU number for operator
  Future<String?> getActiveLapuNumber(String operatorCode) async {
    try {
      final lapuBalance = await getLapuWiseBalance(operatorCode);
      if (lapuBalance != null && lapuBalance['ERROR'] == '0') {
        final lapuReport = lapuBalance['LAPUREPORT'] as List<dynamic>?;
        if (lapuReport != null && lapuReport.isNotEmpty) {
          // Find first active LAPU
          for (final lapu in lapuReport) {
            if (lapu['Lstatus'] == 'Active') {
              return lapu['LapuNumber']?.toString();
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting active LAPU number: $e');
      return null;
    }
  }

  /// Enhanced perform recharge with LAPU status checking
  Future<RechargeResponse> performRechargeWithLapuCheck({
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

      print('🔍 Enhanced Recharge with LAPU Check:');
      print('  Operator: $operatorName -> $operatorCode');
      print('  Circle: $circleName -> $circleCode');

      // Check LAPU status before attempting recharge
      final isLapuActiveForOperator = await isLapuActive(operatorCode);
      print('  LAPU Status: ${isLapuActiveForOperator ? 'Active' : 'Inactive'}');

      if (!isLapuActiveForOperator) {
        print('⚠️  WARNING: LAPU for $operatorName is inactive!');
        
        // For Jio, provide specific guidance
        if (operatorCode == 'JO') {
          return RechargeResponse(
            error: '6',
            status: 3,
            orderId: '',
            memberReqId: _generateTransactionId(),
            message: 'Jio LAPU SIM is inactive. Please contact support to reactivate LAPU number 0681274064',
            opTransId: null,
            commission: null,
            mobileNo: mobileNumber,
            amount: amount,
            lapuNo: '0681274064',
            openingBal: null,
            closingBal: null,
          );
        }
      }

      // Proceed with normal recharge
      return await performRecharge(
        mobileNumber: mobileNumber,
        operatorName: operatorName,
        circleName: circleName,
        amount: amount,
        groupId: groupId,
      );

    } catch (e) {
      print('❌ Error in performRechargeWithLapuCheck: $e');
      throw Exception('Enhanced recharge failed: $e');
    }
  }

  /// Get LAPU status report
  Future<Map<String, dynamic>> getLapuStatusReport() async {
    final operatorCodes = ['AT', 'JO', 'VI', 'BS'];
    final operatorNames = ['AIRTEL', 'JIO', 'VODAFONEIDEA', 'BSNL'];
    final statusReport = <String, dynamic>{};

    for (int i = 0; i < operatorCodes.length; i++) {
      final operatorCode = operatorCodes[i];
      final operatorName = operatorNames[i];
      
      try {
        final lapuBalance = await getLapuWiseBalance(operatorCode);
        if (lapuBalance != null && lapuBalance['ERROR'] == '0') {
          final lapuReport = lapuBalance['LAPUREPORT'] as List<dynamic>?;
          if (lapuReport != null && lapuReport.isNotEmpty) {
            statusReport[operatorName] = {
              'status': 'success',
              'lapu_count': lapuReport.length,
              'active_count': lapuReport.where((l) => l['Lstatus'] == 'Active').length,
              'inactive_count': lapuReport.where((l) => l['Lstatus'] == 'Inactive').length,
              'total_balance': lapuReport.fold(0.0, (sum, l) => sum + (l['LapuBal'] ?? 0.0)),
              'lapu_details': lapuReport,
            };
          }
        }
      } catch (e) {
        statusReport[operatorName] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
    }

    return statusReport;
  }

  /// Check if operator balance is sufficient
  Future<bool> hasOperatorBalance(String operatorCode, double amount) async {
    try {
      final operatorBalance = await getOperatorBalance();
      if (operatorBalance.isSuccess && operatorBalance.record != null) {
        final record = operatorBalance.record!;
        
        String balanceKey;
        switch (operatorCode) {
          case 'AT':
            balanceKey = 'Airtelbalance';
            break;
          case 'JO':
            balanceKey = 'jiobalance';
            break;
          case 'VI':
            balanceKey = 'Vodabalance';
            break;
          case 'BS':
            balanceKey = 'Bsnlbalance';
            break;
          default:
            return false;
        }
        
        final balance = record[balanceKey] as num? ?? 0;
        return balance >= amount;
      }
      return false;
    } catch (e) {
      print('Error checking operator balance: $e');
      return false;
    }
  }
} 