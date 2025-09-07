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
      // Log operator-specific LAPU information
      if (operatorCode == 'AT') {
        print('  📊 Expected to use AIRTEL LAPU numbers: 8807999388 (Active), 9600807006 (Inactive), 8220060321 (Inactive)');
        print('  💰 Available AIRTEL balances: 2509.17 (Active only)');
        print('  Status: 1 Active (8807999388), 2 Inactive (9600807006, 8220060321) ⚠️');
      } else if (operatorCode == 'JL') {
        print('  📊 Expected to use JIO LITE LAPU numbers: 8489377810, 9786468280, 9994400390, 9600888932');
        print('  💰 Available JIO LITE balances: 5.62 + 10.32 + 8.2 + 0.7 = ₹24.84');
        print('  Status: 3 Active (8489377810, 9786468280, 9994400390), 1 Inactive (9600888932) ⚠️');
      } else if (operatorCode == 'VI') {
        print('  📊 Expected to use VODAFONEIDEA LAPU number: 8489770790');
        print('  💰 Available VODAFONEIDEA balance: ₹5861.48');
        print('  Status: 1 Active (8489770790) ✅');
      } else if (operatorCode == 'BS') {
        print('  📊 Expected to use BSNL LAPU numbers: 7598163554, 7598163734');
        print('  💰 Available BSNL balances: 20.73 + 92.6 = ₹113.33');
        print('  Status: 2 Active (7598163554, 7598163734) ✅');
      }
      print('');
      
      // Check balance for different operators
      final rechargeAmount = double.tryParse(amount) ?? 0.0;
      if (operatorCode == 'JL') {
        final totalJioLiteBalance = 5.62 + 10.32 + 8.2 + 0.7; // Updated balances: 8489377810, 9786468280, 9994400390, 9600888932
        if (rechargeAmount > totalJioLiteBalance) {
          print('⚠️ Warning: Recharge amount (₹$amount) exceeds total JIO LITE balance (₹$totalJioLiteBalance)');
        }
      } else if (operatorCode == 'AT') {
        final totalAirtelBalance = 2509.17; // Only active LAPU: 8807999388
        if (rechargeAmount > totalAirtelBalance) {
          print('⚠️ Warning: Recharge amount (₹$amount) exceeds total AIRTEL balance (₹$totalAirtelBalance)');
        }
      } else if (operatorCode == 'VI') {
        final totalViBalance = 5861.48; // Active LAPU: 8489770790
        if (rechargeAmount > totalViBalance) {
          print('⚠️ Warning: Recharge amount (₹$amount) exceeds total VODAFONEIDEA balance (₹$totalViBalance)');
        }
      } else if (operatorCode == 'BS') {
        final totalBsnlBalance = 20.73 + 92.6; // Active LAPUs: 7598163554, 7598163734
        if (rechargeAmount > totalBsnlBalance) {
          print('⚠️ Warning: Recharge amount (₹$amount) exceeds total BSNL balance (₹$totalBsnlBalance)');
        }
      }

      // Ensure mobile number is 10 digits without country code
      final cleanMobileNumber = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final finalMobileNumber = cleanMobileNumber.length > 10 
          ? cleanMobileNumber.substring(cleanMobileNumber.length - 10)
          : cleanMobileNumber;
      
      // Build query parameters - ensure amount is integer format
      final queryParams = {
        'Apimember_id': _apiMemberId,
        'Api_password': _apiPassword,
        'Mobile_no': finalMobileNumber,
        'Operator_code': operatorCode,
        'Amount': (double.tryParse(amount) ?? 0).toInt().toString(),
        'Member_request_txnid': txnId,
        'Circle': circleCode,
        // Note: Group_Id is optional and only added if provided
        if (groupId != null && groupId.isNotEmpty) 'Group_Id': groupId,
      };

      // Validate parameters before sending
      if (finalMobileNumber.length != 10) {
        throw Exception('Invalid mobile number format. Expected 10 digits, got: $finalMobileNumber');
      }
      
      final amountInt = (double.tryParse(amount) ?? 0).toInt();
      if (amountInt < 10 || amountInt > 25000) {
        throw Exception('Invalid amount. Must be between 10 and 25000, got: $amountInt');
      }
      
      print('📤 Recharge Request - Endpoint: /GetMobileRecharge');
      print('📤 Recharge Request - Params: $queryParams');
      print('📤 Validation: Mobile=$finalMobileNumber (${finalMobileNumber.length} digits), Amount=$amountInt, Operator=$operatorCode, Circle=$circleCode');

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
        
        // Enhanced handling for LAPU login error (Error Code 6)
        if (rechargeResponse.error == '6') {
          print('🚨 LAPU Login Issue Detected:');
          print('  Original Message: ${rechargeResponse.message}');
          print('  Operator Code: $operatorCode');
          
          String lapuNumbers = '';
          String operatorName = '';
          
          switch (operatorCode) {
            case 'AT':
              lapuNumbers = '8807999388 (Active), 9600807006 (Inactive), 8220060321 (Inactive)';
              operatorName = 'AIRTEL';
              break;
            case 'JL':
              lapuNumbers = '8489377810, 9786468280, 9994400390 (Active), 9600888932 (Inactive)';
              operatorName = 'JIO LITE';
              break;
            case 'VI':
              lapuNumbers = '8489770790';
              operatorName = 'VODAFONEIDEA';
              break;
            case 'BS':
              lapuNumbers = '7598163554, 7598163734';
              operatorName = 'BSNL';
              break;
            default:
              lapuNumbers = 'Unknown operator';
              operatorName = 'Unknown';
          }
          
          print('  Affected $operatorName LAPU Numbers: $lapuNumbers');
          print('  Action Required: Contact Robotics Exchange support to reactivate $operatorName LAPU numbers');
          print('  📞 Support Contact: Contact support to login $operatorName LAPU numbers for operator code $operatorCode');
          
          // Create enhanced error response
          return RechargeResponse(
            error: '6',
            status: 3,
            orderId: rechargeResponse.orderId,
            memberReqId: rechargeResponse.memberReqId,
            message: '$operatorName LAPU numbers need reactivation. Please contact support to login LAPU numbers: $lapuNumbers for operator code $operatorCode.',
            opTransId: rechargeResponse.opTransId,
            commission: rechargeResponse.commission,
            mobileNo: rechargeResponse.mobileNo,
            amount: rechargeResponse.amount,
            lapuNo: rechargeResponse.lapuNo,
            openingBal: rechargeResponse.openingBal,
            closingBal: rechargeResponse.closingBal,
          );
        }
        
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
            lapuNo: '8489377810', // Primary active JIO LITE LAPU
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

  /// Process recharge with plan details
  Future<Map<String, dynamic>> processRecharge({
    required String mobileNumber,
    required double amount,
    required String operator,
    required dynamic planDetails,
  }) async {
    try {
      // Use the existing performRecharge method with proper operator mapping
      final response = await performRecharge(
        mobileNumber: mobileNumber,
        operatorName: operator, // Pass the operator name directly
        circleName: 'All India', // Default circle for now
        amount: amount.toString(),
      );

      if (response.isSuccess) {
        return {
          'success': true,
          'transactionId': response.opTransId ?? response.orderId ?? _generateTransactionId(),
          'amount': amount,
          'mobileNumber': mobileNumber,
          'operator': operator,
          'timestamp': DateTime.now().toIso8601String(),
          'planDetails': planDetails,
        };
      } else {
        throw Exception(response.message ?? 'Recharge failed');
      }
    } catch (e) {
      throw Exception('Recharge processing failed: ${e.toString()}');
    }
  }
} 