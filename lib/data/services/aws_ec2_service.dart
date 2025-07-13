import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/operator_info.dart';
import '../models/mobile_plans.dart';

class AwsEc2Service {
  static final AwsEc2Service _instance = AwsEc2Service._internal();
  factory AwsEc2Service() => _instance;
  AwsEc2Service._internal() {
    _configureDio();
  }

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: APIConstants.awsEc2BackendUrl,
      connectTimeout: APIConstants.requestTimeout,
      receiveTimeout: APIConstants.requestTimeout,
      sendTimeout: APIConstants.requestTimeout,
      validateStatus: (status) => status! < 500,
    );

    if (APIConstants.enableApiLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: APIConstants.enableRequestLogging,
        responseBody: APIConstants.enableResponseLogging,
        logPrint: (object) => _logger.d('AWS EC2: $object'),
      ));
    }
  }

  /// Test EC2 backend connectivity
  Future<bool> testConnectivity() async {
    try {
      _logger.i('🔌 Testing AWS EC2 backend connectivity...');
      
      final response = await _dio.get('/health').timeout(const Duration(seconds: 10));
      
      _logger.i('✅ AWS EC2 connectivity test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ AWS EC2 connectivity test failed: $e');
      return false;
    }
  }

  /// Proxy operator detection request through EC2 backend
  Future<OperatorInfo?> detectOperatorViaProxy(String mobileNumber) async {
    try {
      _logger.i('🔄 Proxying operator detection through AWS EC2...');
      
      final response = await _dio.post('/api/detect-operator', data: {
        'mobile_number': mobileNumber,
        'credentials': {
          'user_id': APIConstants.planApiUserId,
          'password': APIConstants.planApiPassword,
        },
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final operatorData = responseData['data'];
          return OperatorInfo(
            operator: operatorData['operator']?.toString(),
            opCode: operatorData['operator_code']?.toString(),
            circle: operatorData['circle']?.toString(),
            circleCode: operatorData['circle_code']?.toString(),
            mobile: mobileNumber,
            status: 'EC2_PROXY',
            message: 'Detected via AWS EC2 proxy',
            error: '0',
          );
        }
      }
      
      throw Exception('Invalid response from EC2 backend');
    } catch (e) {
      _logger.e('❌ EC2 operator detection failed: $e');
      return null;
    }
  }

  /// Proxy mobile plans request through EC2 backend
  Future<MobilePlans?> getMobilePlansViaProxy({
    required String operatorCode,
    required String circleCode,
  }) async {
    try {
      _logger.i('🔄 Proxying mobile plans request through AWS EC2...');
      
      final response = await _dio.post('/api/get-plans', data: {
        'operator_code': operatorCode,
        'circle_code': circleCode,
        'credentials': {
          'user_id': APIConstants.planApiUserId,
          'password': APIConstants.planApiPassword,
        },
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final plansData = responseData['data'];
          return _parsePlansFromEc2Response(plansData);
        }
      }
      
      throw Exception('Invalid response from EC2 backend');
    } catch (e) {
      _logger.e('❌ EC2 plans fetch failed: $e');
      return null;
    }
  }

  /// Proxy recharge request through EC2 backend (for reliability)
  Future<Map<String, dynamic>?> processRechargeViaProxy({
    required String mobileNumber,
    required String operatorCode,
    required String circleCode,
    required int amount,
    required String transactionId,
  }) async {
    try {
      _logger.i('🔄 Proxying recharge request through AWS EC2...');
      
      final response = await _dio.post('/api/process-recharge', data: {
        'mobile_number': mobileNumber,
        'operator_code': operatorCode,
        'circle_code': circleCode,
        'amount': amount,
        'transaction_id': transactionId,
        'robotics_credentials': {
          'member_id': APIConstants.roboticsApiMemberId,
          'password': APIConstants.roboticsApiPassword,
        },
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return responseData['data'];
        }
      }
      
      throw Exception('Recharge failed via EC2 backend');
    } catch (e) {
      _logger.e('❌ EC2 recharge failed: $e');
      return null;
    }
  }

  /// Store transaction logs in EC2 backend
  Future<bool> logTransaction({
    required String userId,
    required String transactionId,
    required String mobileNumber,
    required String operatorCode,
    required int amount,
    required String status,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _logger.i('📝 Logging transaction to AWS EC2...');
      
      final response = await _dio.post('/api/log-transaction', data: {
        'user_id': userId,
        'transaction_id': transactionId,
        'mobile_number': mobileNumber,
        'operator_code': operatorCode,
        'amount': amount,
        'status': status,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': additionalData,
      });

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      _logger.e('❌ EC2 transaction logging failed: $e');
      return false;
    }
  }

  /// Get transaction history from EC2 backend
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId) async {
    try {
      _logger.i('📚 Getting transaction history from AWS EC2...');
      
      final response = await _dio.get('/api/transaction-history', queryParameters: {
        'user_id': userId,
        'limit': 100,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true && responseData['data'] is List) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      
      return [];
    } catch (e) {
      _logger.e('❌ EC2 transaction history fetch failed: $e');
      return [];
    }
  }

  /// Check recharge status via EC2 backend
  Future<Map<String, dynamic>?> checkRechargeStatus(String transactionId) async {
    try {
      _logger.i('🔍 Checking recharge status via AWS EC2...');
      
      final response = await _dio.get('/api/check-status', queryParameters: {
        'transaction_id': transactionId,
        'robotics_credentials': json.encode({
          'member_id': APIConstants.roboticsApiMemberId,
          'password': APIConstants.roboticsApiPassword,
        }),
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return responseData['data'];
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ EC2 status check failed: $e');
      return null;
    }
  }

  /// Get API health status from EC2 backend
  Future<Map<String, dynamic>> getApiHealthStatus() async {
    try {
      _logger.i('🏥 Getting API health status from AWS EC2...');
      
      final response = await _dio.get('/api/health-status');

      if (response.statusCode == 200) {
        return response.data;
      }
      
      return {
        'planapi_status': 'unknown',
        'robotics_status': 'unknown',
        'backend_status': 'unknown',
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('❌ EC2 health status failed: $e');
      return {
        'planapi_status': 'error',
        'robotics_status': 'error',
        'backend_status': 'error',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Parse plans from EC2 response
  MobilePlans _parsePlansFromEc2Response(Map<String, dynamic> plansData) {
    try {
      List<PlanItem> fullTTPlans = [];
      List<PlanItem> topupPlans = [];
      List<PlanItem> dataPlans = [];
      List<PlanItem> smsPlans = [];
      List<PlanItem> roamingPlans = [];
      List<PlanItem> frcPlans = [];
      List<PlanItem> stvPlans = [];

      // Parse different plan categories
      if (plansData['fulltt'] != null) {
        fullTTPlans = _parsePlanItemsFromList(plansData['fulltt'], 'unlimited');
      }
      
      if (plansData['topup'] != null) {
        topupPlans = _parsePlanItemsFromList(plansData['topup'], 'talktime');
      }
      
      if (plansData['data'] != null) {
        dataPlans = _parsePlanItemsFromList(plansData['data'], 'data');
      }
      
      if (plansData['sms'] != null) {
        smsPlans = _parsePlanItemsFromList(plansData['sms'], 'sms');
      }
      
      if (plansData['roaming'] != null) {
        roamingPlans = _parsePlanItemsFromList(plansData['roaming'], 'roaming');
      }
      
      if (plansData['frc'] != null) {
        frcPlans = _parsePlanItemsFromList(plansData['frc'], 'smart');
      }
      
      if (plansData['stv'] != null) {
        stvPlans = _parsePlanItemsFromList(plansData['stv'], 'smart');
      }

      return MobilePlans(
        operator: plansData['operator']?.toString() ?? '',
        circle: plansData['circle']?.toString() ?? '',
        fullTTPlans: fullTTPlans,
        topupPlans: topupPlans,
        dataPlans: dataPlans,
        smsPlans: smsPlans,
        roamingPlans: roamingPlans,
        frcPlans: frcPlans,
        stvPlans: stvPlans,
      );
    } catch (e) {
      _logger.e('❌ Error parsing EC2 plans response: $e');
      throw Exception('Failed to parse plans from EC2 backend: $e');
    }
  }

  /// Parse plan items from a list
  List<PlanItem> _parsePlanItemsFromList(List<dynamic> plansList, String defaultType) {
    return plansList.map((plan) {
      return PlanItem(
        rs: plan['rs'] ?? plan['amount'] ?? 0,
        validity: plan['validity']?.toString() ?? '',
        desc: plan['desc']?.toString() ?? plan['description']?.toString() ?? '',
        type: plan['type']?.toString() ?? defaultType,
      );
    }).toList();
  }

  /// Upload app logs to EC2 backend for monitoring
  Future<bool> uploadLogs(List<String> logs) async {
    try {
      _logger.i('📤 Uploading logs to AWS EC2...');
      
      final response = await _dio.post('/api/upload-logs', data: {
        'logs': logs,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      });

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      _logger.e('❌ EC2 log upload failed: $e');
      return false;
    }
  }

  /// Get app configuration from EC2 backend
  Future<Map<String, dynamic>?> getAppConfiguration() async {
    try {
      _logger.i('⚙️ Getting app configuration from AWS EC2...');
      
      final response = await _dio.get('/api/app-config');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          return responseData['config'];
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ EC2 config fetch failed: $e');
      return null;
    }
  }

  /// Update EC2 backend with latest API credentials (for dynamic updates)
  Future<bool> updateApiCredentials() async {
    try {
      _logger.i('🔄 Updating API credentials on AWS EC2...');
      
      final response = await _dio.post('/api/update-credentials', data: {
        'planapi': {
          'user_id': APIConstants.planApiUserId,
          'password': APIConstants.planApiPassword,
          'token': APIConstants.planApiToken,
        },
        'robotics': {
          'member_id': APIConstants.roboticsApiMemberId,
          'password': APIConstants.roboticsApiPassword,
        },
      });

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      _logger.e('❌ EC2 credential update failed: $e');
      return false;
    }
  }
} 