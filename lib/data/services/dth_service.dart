import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';

class DthService {
  final RoboticsExchangeService _roboticsService;
  final ProxyService _proxyService;
  final http.Client _client;

  // PlanAPI Credentials
  static const String _planApiMemberId = "3557";
  static const String _planApiPassword = "Neela@1988";

  DthService({
    RoboticsExchangeService? roboticsService,
    ProxyService? proxyService,
    http.Client? client,
  })  : _roboticsService = roboticsService ?? RoboticsExchangeService(proxyService: ProxyService()),
        _proxyService = proxyService ?? ProxyService(),
        _client = client ?? http.Client();

  void dispose() {
    _client.close();
    _roboticsService.dispose();
    _proxyService.dispose();
  }

  /// Detect DTH operator from DTH number
  Future<DthOperatorResponse?> detectDthOperator(String dthNumber) async {
    try {
      print('🧪 Detecting DTH operator for: $dthNumber');
      
      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }
      print('✅ Proxy connection successful');

      // Make API request through proxy (like mobile recharge does)
      final response = await _proxyService.get(
        '/Mobile/DthOperatorFetch',
        queryParameters: {
          'apimember_id': _planApiMemberId,
          'api_password': _planApiPassword,
          'dth_number': dthNumber,
        },
        timeout: const Duration(seconds: 30),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final dthResponse = DthOperatorResponse.fromJson(jsonResponse);
        
        print('✅ DTH operator detected: ${dthResponse.dthName} (${dthResponse.dthOpCode})');
        return dthResponse;
      } else {
        print('❌ Failed to detect DTH operator: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error detecting DTH operator: $e');
      return null;
    }
  }

  /// Fetch DTH plans for a specific operator
  Future<DthPlansResponse?> fetchDthPlans(String operatorCode) async {
    try {
      print('🧪 Fetching DTH plans for operator: $operatorCode');
      
      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }
      print('✅ Proxy connection successful');

      // Make API request through proxy (like mobile recharge does)
      final response = await _proxyService.get(
        '/Mobile/DthPlans',
        queryParameters: {
          'apimember_id': _planApiMemberId,
          'api_password': _planApiPassword,
          'operatorcode': operatorCode,
        },
        timeout: const Duration(seconds: 30),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final plansResponse = DthPlansResponse.fromJson(jsonResponse);
        
        print('✅ DTH plans fetched successfully for: ${plansResponse.operator}');
        return plansResponse;
      } else {
        print('❌ Failed to fetch DTH plans: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching DTH plans: $e');
      return null;
    }
  }

  /// Check DTH info (basic info without last recharge date)
  Future<DthInfoResponse?> checkDthInfo(String dthNumber, String operatorCode) async {
    try {
      print('🧪 Checking DTH info for: $dthNumber (operator: $operatorCode)');
      
      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }
      print('✅ Proxy connection successful');

      // Make API request through proxy (like mobile recharge does)
      final response = await _proxyService.get(
        '/Mobile/DTHINFOCheck',
        queryParameters: {
          'apimember_id': _planApiMemberId,
          'api_password': _planApiPassword,
          'mobile_no': dthNumber,
          'Opcode': operatorCode,
        },
        timeout: const Duration(seconds: 30),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final infoResponse = DthInfoResponse.fromJson(jsonResponse);
        
        print('✅ DTH info checked successfully');
        return infoResponse;
      } else {
        print('❌ Failed to check DTH info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error checking DTH info: $e');
      return null;
    }
  }

  /// Check DTH info with last recharge date
  Future<DthInfoResponse?> checkDthInfoWithLastRecharge(String dthNumber, String operatorCode) async {
    try {
      print('🧪 Checking DTH info with last recharge for: $dthNumber (operator: $operatorCode)');
      
      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }
      print('✅ Proxy connection successful');

      // Make API request through proxy (like mobile recharge does)
      final response = await _proxyService.get(
        '/Mobile/DthInfoWithLastRechargeDate',
        queryParameters: {
          'apimember_id': _planApiMemberId,
          'api_password': _planApiPassword,
          'mobile_no': dthNumber,
          'Opcode': operatorCode,
        },
        timeout: const Duration(seconds: 30),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final infoResponse = DthInfoResponse.fromJson(jsonResponse);
        
        print('✅ DTH info with last recharge checked successfully');
        return infoResponse;
      } else {
        print('❌ Failed to check DTH info with last recharge: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error checking DTH info with last recharge: $e');
      return null;
    }
  }

  /// Perform DTH recharge using robotics exchange
  Future<Map<String, dynamic>?> performDthRecharge({
    required String dthNumber,
    required String operatorName,
    required String amount,
    required String planName,
    required String duration,
    required String channels,
  }) async {
    try {
      print('🧪 Starting DTH recharge process');
      print('   DTH Number: $dthNumber');
      print('   Operator: $operatorName');
      print('   Amount: ₹$amount');
      print('   Plan: $planName');
      print('   Duration: $duration');
      print('   Channels: $channels');

      // Get robotics exchange operator code
      final roboticsOperatorCode = DthOperatorMapping.getRoboticsOperatorCode(operatorName);
      print('   Robotics Operator Code: $roboticsOperatorCode');

      // Check if LAPU is active for this operator
      final isLapuActive = await _roboticsService.isLapuActive(roboticsOperatorCode);
      print('   LAPU Status: ${isLapuActive ? "Active ✅" : "Inactive ❌"}');

      if (!isLapuActive) {
        print('❌ LAPU is not active for operator: $operatorName');
        return {
          'success': false,
          'message': 'LAPU is not active for $operatorName. Please contact support.',
          'error_code': 'LAPU_INACTIVE'
        };
      }

      // Perform DTH recharge via robotics exchange
      final rechargeResponse = await _roboticsService.performRecharge(
        mobileNumber: dthNumber,
        operatorName: operatorName,
        circleName: 'ALL', // DTH doesn't use circles
        amount: amount,
      );

      print('📡 Robotics Exchange Response:');
      print('   Error: ${rechargeResponse.error}');
      print('   Status: ${rechargeResponse.status}');
      print('   Message: ${rechargeResponse.message}');
      print('   Order ID: ${rechargeResponse.orderId}');

      if (rechargeResponse.isSuccess) {
        print('✅ DTH recharge successful!');
        return {
          'success': true,
          'message': 'DTH recharge successful',
          'order_id': rechargeResponse.orderId,
          'op_trans_id': rechargeResponse.opTransId,
          'amount': rechargeResponse.amount,
          'dth_number': dthNumber,
          'operator': operatorName,
          'plan_name': planName,
          'duration': duration,
          'channels': channels,
          'commission': rechargeResponse.commission,
          'lapu_no': rechargeResponse.lapuNo,
          'opening_balance': rechargeResponse.openingBal,
          'closing_balance': rechargeResponse.closingBal,
        };
      } else {
        print('❌ DTH recharge failed: ${rechargeResponse.message}');
        return {
          'success': false,
          'message': rechargeResponse.message,
          'error_code': rechargeResponse.error,
          'order_id': rechargeResponse.orderId,
        };
      }
    } catch (e) {
      print('❌ Error performing DTH recharge: $e');
      return {
        'success': false,
        'message': 'An error occurred during DTH recharge: $e',
        'error_code': 'RECHARGE_ERROR'
      };
    }
  }

  /// Get all available DTH operators
  List<Map<String, String>> getAvailableDthOperators() {
    return [
      {'name': 'AIRTEL DTH', 'planApiCode': '24', 'roboticsCode': 'AD'},
      {'name': 'DISH TV', 'planApiCode': '25', 'roboticsCode': 'DT'},
      {'name': 'RELIANCE BIGTV', 'planApiCode': '26', 'roboticsCode': 'VD'},
      {'name': 'SUN DIRECT', 'planApiCode': '27', 'roboticsCode': 'SD'},
      {'name': 'TATA SKY', 'planApiCode': '28', 'roboticsCode': 'TS'},
      {'name': 'VIDEOCON D2H', 'planApiCode': '29', 'roboticsCode': 'VD'},
    ];
  }

  /// Check DTH recharge status
  Future<Map<String, dynamic>?> checkDthRechargeStatus(String orderId) async {
    try {
      print('🧪 Checking DTH recharge status for order: $orderId');
      
      final statusResponse = await _roboticsService.checkRechargeStatus(memberRequestTxnId: orderId);
      
      if (statusResponse != null) {
        print('✅ DTH recharge status checked successfully');
        return {
          'success': true,
          'order_id': statusResponse.orderId,
          'status': statusResponse.status,
          'message': statusResponse.message,
          'op_trans_id': statusResponse.opTransId,
        };
      } else {
        print('❌ Failed to check DTH recharge status');
        return {
          'success': false,
          'message': 'Failed to check recharge status',
        };
      }
    } catch (e) {
      print('❌ Error checking DTH recharge status: $e');
      return {
        'success': false,
        'message': 'Error checking recharge status: $e',
      };
    }
  }

  /// Parse DTH plans into simplified format
  List<Map<String, dynamic>> parseDthPlans(DthPlansResponse plansResponse) {
    final List<Map<String, dynamic>> simplifiedPlans = [];
    
    if (plansResponse.rdata?.combo != null) {
      for (final combo in plansResponse.rdata!.combo!) {
        for (final detail in combo.details) {
          for (final pricing in detail.pricingList) {
            simplifiedPlans.add({
              'plan_name': detail.planName,
              'language': combo.language,
              'channels': detail.channels,
              'paid_channels': detail.paidChannels,
              'hd_channels': detail.hdChannels,
              'amount': pricing.amount,
              'numeric_amount': pricing.numericAmount,
              'duration': pricing.month,
              'last_update': detail.lastUpdate,
              'operator': plansResponse.operator,
              'type': 'DTH',
            });
          }
        }
      }
    }
    
    // Sort by amount (lowest first)
    simplifiedPlans.sort((a, b) => 
      (a['numeric_amount'] as double).compareTo(b['numeric_amount'] as double)
    );
    
    return simplifiedPlans;
  }

  /// Validate DTH number format
  bool validateDthNumber(String dthNumber) {
    // Remove any spaces or special characters
    final cleanNumber = dthNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // DTH numbers are typically 10-12 digits
    if (cleanNumber.length < 10 || cleanNumber.length > 12) {
      return false;
    }
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return false;
    }
    
    return true;
  }

  /// Get DTH operator suggestions based on partial number
  List<Map<String, String>> getDthOperatorSuggestions(String partialNumber) {
    final suggestions = <Map<String, String>>[];
    
    // Add common DTH operator prefixes
    if (partialNumber.length >= 3) {
      final prefix = partialNumber.substring(0, 3);
      
      switch (prefix) {
        case '100':
        case '101':
        case '102':
          suggestions.add({'name': 'AIRTEL DTH', 'code': '24'});
          break;
        case '200':
        case '201':
        case '202':
          suggestions.add({'name': 'DISH TV', 'code': '25'});
          break;
        case '300':
        case '301':
        case '302':
          suggestions.add({'name': 'TATA SKY', 'code': '28'});
          break;
        case '400':
        case '401':
        case '402':
          suggestions.add({'name': 'VIDEOCON D2H', 'code': '29'});
          break;
        case '500':
        case '501':
        case '502':
          suggestions.add({'name': 'SUN DIRECT', 'code': '27'});
          break;
        default:
          // Return all operators if no specific prefix matches
          suggestions.addAll(getAvailableDthOperators().map((op) => {
            'name': op['name']!,
            'code': op['planApiCode']!,
          }));
      }
    } else {
      // Return all operators for short numbers
      suggestions.addAll(getAvailableDthOperators().map((op) => {
        'name': op['name']!,
        'code': op['planApiCode']!,
      }));
    }
    
    return suggestions;
  }
} 