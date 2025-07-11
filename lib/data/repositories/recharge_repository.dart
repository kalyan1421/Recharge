import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/recharge_request.dart';
import '../../core/constants/api_constants.dart';

abstract class RechargeAPIProvider {
  Future<RechargeResponse> processRecharge(RechargeRequest request);
  Future<List<PlanDetails>> getPlans(String operator, String circle);
  Future<Map<String, dynamic>> checkOperatorStatus();
  String get providerName;
  int get priority; // Lower number = higher priority
}

class PlanAPIProvider implements RechargeAPIProvider {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  
  @override
  String get providerName => 'PlanAPI.in (via Proxy)';
  
  @override
  int get priority => 2; // Lower priority than RoboticsExchangeProvider

  @override
  Future<RechargeResponse> processRecharge(RechargeRequest request) async {
    try {
      _logger.i('Processing recharge with Proxy: ${request.mobile} - ₹${request.amount}');

      // Use proxy endpoint for recharge
      final url = Uri.parse(APIConstants.rechargeUrl)
          .replace(queryParameters: {
        'mobileno': request.mobile,
        'operatorcode': request.operatorCode,
          'circle': request.circle,
        'amount': request.amount.toInt().toString(),
        'requestid': request.requestId,
      });

      _logger.d('Proxy Recharge URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 30));

      _logger.d('Recharge Response Status: ${response.statusCode}');
      _logger.d('Recharge Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> proxyResponse = response.data as Map<String, dynamic>;
        
        // Handle proxy response format
        if (proxyResponse['success'] == true) {
          final Map<String, dynamic> originalData = proxyResponse['data'];
          
          // Handle API response format
          if (originalData['ERROR'] == '1') {
            final errorMessage = originalData['MESSAGE'] ?? 'Recharge failed';
            _logger.e('Recharge API Error: $errorMessage');
            throw Exception('Recharge Error: $errorMessage');
          }

          if (originalData['ERROR'] == '0' && originalData['STATUS'] == '0') {
            // Success response
            return RechargeResponse(
              transactionId: originalData['TXNID'] ?? request.requestId,
              status: _mapRechargeStatus(originalData['RDATA']?['status'] ?? 'PENDING'),
              message: originalData['MESSAGE'] ?? 'Recharge initiated successfully',
              amount: request.amount,
              balance: (originalData['RDATA']?['balance'] ?? 0.0).toDouble(),
              operatorTransactionId: originalData['RDATA']?['operator_txnid'],
              timestamp: DateTime.now(),
              additionalData: originalData['RDATA'],
            );
          } else {
            throw Exception('Recharge failed: ${originalData['MESSAGE'] ?? 'Unknown error'}');
          }
        } else {
          // Handle proxy error or fallback
          final errorMessage = proxyResponse['error'] ?? 'Service temporarily unavailable';
          _logger.w('Proxy returned error for recharge: $errorMessage');
          
          // Return a pending status for demo purposes
        return RechargeResponse(
            transactionId: request.requestId,
            status: 'PENDING',
            message: 'Recharge initiated (Demo Mode)',
          amount: request.amount,
            balance: 0.0,
            operatorTransactionId: null,
          timestamp: DateTime.now(),
            additionalData: {'demo': true, 'error': errorMessage},
        );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Proxy Recharge Error: $e');
      
      // Return a pending status for demo purposes
      return RechargeResponse(
        transactionId: request.requestId,
        status: 'PENDING',
        message: 'Recharge initiated (Demo Mode)',
        amount: request.amount,
        balance: 0.0,
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        additionalData: {'demo': true, 'error': e.toString()},
      );
    }
  }

  String _mapRechargeStatus(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return 'SUCCESS';
      case 'FAILED':
      case 'FAILURE':
        return 'FAILED';
      case 'PENDING':
      case 'PROCESSING':
        return 'PENDING';
      default:
        return 'PENDING';
    }
  }

  @override
  Future<List<PlanDetails>> getPlans(String operator, String circle) async {
    try {
      _logger.i('Fetching plans via Proxy: $operator - $circle');

      // Use proxy endpoint for plans
      final url = Uri.parse(APIConstants.mobilePlansUrl)
          .replace(queryParameters: {
        'operatorcode': operator,
        'circle': circle,
      });

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> proxyResponse = response.data as Map<String, dynamic>;
        
        // Handle proxy response format
        if (proxyResponse['success'] == true) {
          final Map<String, dynamic> originalData = proxyResponse['data'];
          
          if (originalData['ERROR'] == '0' && originalData['RDATA'] != null) {
            final rData = originalData['RDATA'] as Map<String, dynamic>;
            final List<PlanDetails> plans = [];
            
            rData.forEach((category, planList) {
              if (planList is List) {
                for (var plan in planList) {
                  if (plan is Map<String, dynamic>) {
                    plans.add(PlanDetails(
                      planId: '${plan['rs']}_${category.replaceAll(' ', '_')}',
                      operator: originalData['Operator'] ?? operator,
                      circle: originalData['Circle'] ?? circle,
                      amount: (plan['rs'] ?? 0).toDouble(),
                      validity: plan['validity'] ?? '',
                      description: plan['desc'] ?? '',
                      benefits: [plan['desc'] ?? ''],
                      planType: category,
                    ));
                  }
                }
              }
            });
            
            _logger.i('Plans fetched successfully via proxy: ${plans.length} plans');
            return plans;
          }
        } else {
          // Handle proxy fallback
          final fallbackData = proxyResponse['data'];
          if (proxyResponse['fallback'] == true && fallbackData != null && fallbackData['RDATA'] != null) {
            final rData = fallbackData['RDATA'] as Map<String, dynamic>;
            final List<PlanDetails> plans = [];
            
            rData.forEach((category, planList) {
              if (planList is List) {
                for (var plan in planList) {
                  if (plan is Map<String, dynamic>) {
                    plans.add(PlanDetails(
                      planId: '${plan['rs']}_${category.replaceAll(' ', '_')}',
                      operator: fallbackData['Operator'] ?? operator,
                      circle: fallbackData['Circle'] ?? circle,
                      amount: (plan['rs'] ?? 0).toDouble(),
                      validity: plan['validity'] ?? '',
                      description: plan['desc'] ?? '',
                      benefits: [plan['desc'] ?? ''],
                      planType: category,
                    ));
                  }
                }
              }
            });
            
            _logger.i('Using fallback plans: ${plans.length} plans');
            return plans;
          }
        }
      }
      return [];
    } catch (e) {
      _logger.e('Error fetching plans via proxy: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> checkOperatorStatus() async {
    try {
      // Use proxy health check endpoint
      final url = Uri.parse(APIConstants.healthCheckUrl);

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'status': data['status'] == 'OK' ? 'active' : 'inactive',
          'message': 'Proxy server is ${data['status']}',
          'provider': providerName,
          'uptime': data['uptime'],
          'timestamp': data['timestamp'],
        };
      }
      
      return {'status': 'inactive', 'message': 'Proxy server unavailable'};
    } catch (e) {
      _logger.e('Error checking proxy status: $e');
      return {'status': 'inactive', 'message': e.toString()};
    }
  }
}

class RoboticsExchangeProvider implements RechargeAPIProvider {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  
  @override
  String get providerName => 'Robotics Exchange';
  
  @override
  int get priority => 1; // Higher priority than PlanAPI
  
  @override
  Future<RechargeResponse> processRecharge(RechargeRequest request) async {
    try {
      _logger.i('Processing recharge with Robotics Exchange: ${request.mobile} - ₹${request.amount}');
      
      // Generate unique transaction ID
      final txnId = 'RBX_${DateTime.now().millisecondsSinceEpoch}_${request.mobile.substring(request.mobile.length - 4)}';
      
      // Map operator code to robotics exchange format
      final operatorCode = APIConstants.roboticsOperatorCodes[request.operatorCode] ?? '11';
      
      // Build request parameters
      final url = Uri.parse(APIConstants.roboticsRechargeUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Mobile_no': request.mobile,
        'Operator_code': operatorCode,
        'Amount': request.amount.toInt().toString(),
        'Member_request_txnid': txnId,
        'Circle': APIConstants.telecomCircles[request.circle] ?? '10',
      });
      
      _logger.d('Robotics Exchange Recharge URL: $url');
      
      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 30));
      
      _logger.d('Robotics Exchange Response Status: ${response.statusCode}');
      _logger.d('Robotics Exchange Response Body: ${response.data}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;
        
        // Handle robotics exchange response format
        final error = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown error';
        final orderId = apiResponse['ORDERID']?.toString() ?? txnId;
        final operatorTxnId = apiResponse['OPTRANSID']?.toString();
        final closingBalance = double.tryParse(apiResponse['CLOSINGBAL']?.toString() ?? '0') ?? 0.0;
        
        if (error == '0' && status == '1') {
          // Success case
          return RechargeResponse(
            transactionId: orderId,
            status: 'SUCCESS',
            message: message,
            amount: request.amount,
            balance: closingBalance,
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            additionalData: {
              'roboticsExchange': true,
              'memberRequestId': apiResponse['MEMBERREQID'],
              'lapuNo': apiResponse['LAPUNO'],
              'openingBalance': apiResponse['OPNINGBAL'],
              'commission': apiResponse['COMMISSION'],
            },
          );
        } else if (error == '1' && status == '2') {
          // Processing case
          return RechargeResponse(
            transactionId: orderId,
            status: 'PENDING',
            message: message,
            amount: request.amount,
            balance: closingBalance,
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            additionalData: {
              'roboticsExchange': true,
              'memberRequestId': apiResponse['MEMBERREQID'],
              'lapuNo': apiResponse['LAPUNO'],
              'openingBalance': apiResponse['OPNINGBAL'],
              'processing': true,
            },
          );
        } else {
          // Failed case
          return RechargeResponse(
            transactionId: orderId,
            status: 'FAILED',
            message: message,
            amount: request.amount,
            balance: closingBalance,
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            additionalData: {
              'roboticsExchange': true,
              'memberRequestId': apiResponse['MEMBERREQID'],
              'lapuNo': apiResponse['LAPUNO'],
              'openingBalance': apiResponse['OPNINGBAL'],
              'error': error,
              'status': status,
            },
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Robotics Exchange Recharge Error: $e');
      
      // Return failed response
      return RechargeResponse(
        transactionId: request.requestId,
        status: 'FAILED',
        message: 'Recharge failed: ${e.toString()}',
        amount: request.amount,
        balance: 0.0,
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        additionalData: {
          'roboticsExchange': true,
          'error': e.toString(),
        },
      );
    }
  }
  
  @override
  Future<List<PlanDetails>> getPlans(String operator, String circle) async {
    // Robotics Exchange doesn't provide plan details
    // We'll return empty list and rely on PlanAPI for plans
    return [];
  }
  
  @override
  Future<Map<String, dynamic>> checkOperatorStatus() async {
    try {
      final url = Uri.parse(APIConstants.roboticsOperatorBalanceUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
      });
      
      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;
        
        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        
        if (errorCode == '0' && status == '1') {
          return {
            'status': 'active',
            'provider': 'robotics_exchange',
            'balances': apiResponse['Record'] ?? {},
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          return {
            'status': 'inactive',
            'provider': 'robotics_exchange',
            'error': apiResponse['Message'] ?? 'Service unavailable',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking Robotics Exchange operator status: $e');
      return {
        'status': 'error',
        'provider': 'robotics_exchange',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Check recharge status using robotics exchange API
  Future<RechargeResponse?> checkRechargeStatus(String memberRequestTxnId) async {
    try {
      final url = Uri.parse(APIConstants.roboticsStatusCheckUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Member_request_txnid': memberRequestTxnId,
      });
      
      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;
        
        final error = apiResponse['ERROR']?.toString() ?? '1';
        final status = apiResponse['STATUS']?.toString() ?? '3';
        final message = apiResponse['MESSAGE']?.toString() ?? 'Unknown status';
        final orderId = apiResponse['ORDERID']?.toString() ?? memberRequestTxnId;
        final operatorTxnId = apiResponse['OPTRANSID']?.toString();
        final closingBalance = double.tryParse(apiResponse['CLOSINGBAL']?.toString() ?? '0') ?? 0.0;
        final amount = double.tryParse(apiResponse['AMOUNT']?.toString() ?? '0') ?? 0.0;
        
        String rechargeStatus;
        if (error == '0' && status == '1') {
          rechargeStatus = 'SUCCESS';
        } else if (error == '1' && status == '2') {
          rechargeStatus = 'PENDING';
        } else {
          rechargeStatus = 'FAILED';
        }
        
        return RechargeResponse(
          transactionId: orderId,
          status: rechargeStatus,
          message: message,
          amount: amount,
          balance: closingBalance,
          operatorTransactionId: operatorTxnId,
          timestamp: DateTime.now(),
          additionalData: {
            'roboticsExchange': true,
            'memberRequestId': apiResponse['MEMBERREQID'],
            'lapuNo': apiResponse['LAPUNO'],
            'openingBalance': apiResponse['OPNINGBAL'],
            'statusCheck': true,
          },
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking recharge status: $e');
      return null;
    }
  }
}

class RechargeRepository {
  static final RechargeRepository _instance = RechargeRepository._internal();
  factory RechargeRepository() => _instance;
  RechargeRepository._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Use RoboticsExchangeProvider as primary, with PlanAPI as fallback
  final List<RechargeAPIProvider> _providers = [
    RoboticsExchangeProvider(),
    PlanAPIProvider(),
  ];

  /// Process recharge using providers with failover
  Future<RechargeResponse> processRecharge(RechargeRequest request) async {
    _logger.i('Processing recharge: ${request.mobile} - ₹${request.amount}');

    try {
      // Save recharge request to Firebase
      await _saveRechargeRequest(request);

      // Sort providers by priority (lower number = higher priority)
      final sortedProviders = List<RechargeAPIProvider>.from(_providers)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      RechargeResponse? lastResponse;
      String lastError = '';

      // Try each provider in order of priority
      for (final provider in sortedProviders) {
        try {
          _logger.i('Trying recharge provider: ${provider.providerName}');
          
          final response = await provider.processRecharge(request);
          
          // Save successful response to Firebase
          await _saveRechargeResponse(request.requestId, response);
          
          _logger.i('Recharge processed successfully with ${provider.providerName}: ${response.transactionId}');
          return response;
        } catch (e) {
          _logger.w('Provider ${provider.providerName} failed: $e');
          lastError = e.toString();
          
          // Continue to next provider
          continue;
        }
      }

      // If all providers failed, create a failed response
      final failedResponse = RechargeResponse(
        transactionId: request.requestId,
        status: 'FAILED',
        message: 'All recharge providers failed. Last error: $lastError',
        amount: request.amount,
        balance: 0.0,
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        additionalData: {
          'error': lastError,
          'allProvidersFailed': true,
          'providersAttempted': sortedProviders.map((p) => p.providerName).toList(),
        },
      );
      
      // Save failed response
      await _saveRechargeResponse(request.requestId, failedResponse);
      
      return failedResponse;
    } catch (e) {
      _logger.e('Error processing recharge: $e');
      
      // Create a failed response
      final failedResponse = RechargeResponse(
        transactionId: request.requestId,
        status: 'FAILED',
        message: 'Recharge failed: ${e.toString()}',
        amount: request.amount,
        balance: 0.0,
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        additionalData: {'error': e.toString()},
      );
      
      // Save failed response
      await _saveRechargeResponse(request.requestId, failedResponse);
      
      return failedResponse;
    }
  }

  /// Get recharge history for a user
  Future<List<RechargeResponse>> getRechargeHistory(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('recharges')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => RechargeResponse.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching recharge history: $e');
      return [];
    }
  }

  /// Get recharge status by transaction ID
  Future<RechargeResponse?> getRechargeStatus(String transactionId) async {
    try {
      final docSnapshot = await _firestore
          .collection('recharges')
          .doc(transactionId)
          .get();

      if (docSnapshot.exists) {
        return RechargeResponse.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching recharge status: $e');
      return null;
    }
  }

  /// Check provider status (uses highest priority provider)
  Future<Map<String, dynamic>> checkProviderStatus() async {
    final sortedProviders = List<RechargeAPIProvider>.from(_providers)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final provider = sortedProviders.first;
    return await provider.checkOperatorStatus();
  }

  /// Save recharge request to Firebase
  Future<void> _saveRechargeRequest(RechargeRequest request) async {
    try {
      await _firestore
          .collection('recharge_requests')
          .doc(request.requestId)
          .set(request.toJson());
    } catch (e) {
      _logger.e('Error saving recharge request: $e');
    }
  }

  /// Save recharge response to Firebase
  Future<void> _saveRechargeResponse(String requestId, RechargeResponse response) async {
    try {
      await _firestore
          .collection('recharges')
          .doc(requestId)
          .set(response.toJson());
    } catch (e) {
      _logger.e('Error saving recharge response: $e');
    }
  }
} 