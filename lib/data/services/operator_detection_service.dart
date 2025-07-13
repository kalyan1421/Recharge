import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/operator_info.dart';
import 'proxy_service.dart';

class OperatorDetectionService {
  final ProxyService _proxyService;
  final Logger _logger = Logger();

  OperatorDetectionService({ProxyService? proxyService}) 
      : _proxyService = proxyService ?? ProxyService();

  Future<OperatorInfo> detectOperator(String mobileNumber) async {
    try {
      _logger.i('Detecting operator for mobile: ${_maskMobileNumber(mobileNumber)}');

      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }
      _logger.i('✅ Proxy connection successful');

      // Clean mobile number
      String cleanNumber = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanNumber.startsWith('91')) {
        cleanNumber = cleanNumber.substring(2);
      }
      if (cleanNumber.length != 10) {
        throw Exception('Invalid mobile number length');
      }

      // Make API request through proxy
      final response = await _proxyService.get(
        '/Mobile/OperatorFetchNew',
        queryParameters: {
          'ApiUserID': APIConstants.planApiUserId,
          'ApiPassword': APIConstants.planApiPassword,
          'Mobileno': cleanNumber,
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Check for API-level errors
        if (data['ERROR'] == '3') {
          throw Exception('Authentication failed: ${data['Message'] ?? 'Invalid credentials'}');
        }
        
        if (data['ERROR'] != '0' || data['STATUS'] != '1') {
          throw Exception(data['Message'] ?? 'Failed to detect operator');
        }

        // Map response to OperatorInfo
        final operatorInfo = OperatorInfo.fromJson(data);
        
        // Validate operator and circle codes
        if (operatorInfo.opCode.isEmpty || operatorInfo.opCode == 'null') {
          throw Exception('Invalid operator code received: ${operatorInfo.opCode}');
        }
        if (operatorInfo.circleCode.isEmpty || operatorInfo.circleCode == 'null') {
          throw Exception('Invalid circle code received: ${operatorInfo.circleCode}');
        }

        _logger.i('✅ Operator detected: ${operatorInfo.operator} (${operatorInfo.opCode})');
        _logger.i('✅ Circle detected: ${operatorInfo.circle} (${operatorInfo.circleCode})');
        
        return operatorInfo;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('❌ Operator detection failed: $e');
      throw Exception('Failed to detect operator: $e');
    }
  }

  void dispose() {
    _proxyService.dispose();
  }

  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }
} 