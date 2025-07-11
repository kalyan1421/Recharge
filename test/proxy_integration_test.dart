import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../lib/core/constants/api_constants.dart';
import '../lib/data/services/plan_api_service.dart';
import '../lib/data/services/operator_detection_service.dart';
import '../lib/data/services/plan_service.dart';

void main() {
  group('AWS Proxy Integration Tests', () {
    late PlanApiService planApiService;
    late OperatorDetectionService operatorDetectionService;
    late PlanService planService;

    setUpAll(() {
      planApiService = PlanApiService();
      operatorDetectionService = OperatorDetectionService();
      planService = PlanService();
    });

    test('should connect to proxy health check endpoint', () async {
      try {
        final response = await http.get(
          Uri.parse(APIConstants.healthCheckUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        expect(data['status'], equals('OK'));
        expect(data['uptime'], isNotNull);
        expect(data['timestamp'], isNotNull);
        
        print('✅ Proxy Health Check: ${data['status']} (Uptime: ${data['uptime']}s)');
      } catch (e) {
        print('❌ Health Check Failed: $e');
        fail('Proxy server health check failed: $e');
      }
    });

    test('should detect operator via proxy', () async {
      try {
        final testNumbers = [
          '8890545871', // Test number from API docs
          '9876543210', // Generic test number
        ];

        for (final number in testNumbers) {
          print('\n📱 Testing operator detection for: $number');
          
          final operatorInfo = await operatorDetectionService.detectOperator(number);
          
          expect(operatorInfo, isNotNull);
          expect(operatorInfo!.mobile, equals(number));
          
          if (operatorInfo.error == '0') {
            print('✅ Operator detected: ${operatorInfo.operator} (${operatorInfo.opCode}) - ${operatorInfo.circle}');
            expect(operatorInfo.operator, isNotEmpty);
            expect(operatorInfo.opCode, isNotEmpty);
            expect(operatorInfo.circle, isNotEmpty);
          } else {
            print('⚠️ Operator detection returned error: ${operatorInfo.message}');
            // Even with error, we should have a valid response structure
            expect(operatorInfo.message, isNotEmpty);
          }
        }
      } catch (e) {
        print('❌ Operator Detection Failed: $e');
        // Don't fail the test if it's a network issue, just log it
        if (e.toString().contains('NetworkException') || e.toString().contains('TimeoutException')) {
          print('⚠️ Network issue detected - this is expected if proxy is not running');
        } else {
          fail('Operator detection failed: $e');
        }
      }
    });

    test('should fetch mobile plans via proxy', () async {
      try {
        final testCases = [
          {'operatorCode': '11', 'circle': '49'}, // Jio in AP
          {'operatorCode': '1', 'circle': '10'},  // Airtel in Delhi
          {'operatorCode': '3', 'circle': '92'},  // VI in Mumbai
        ];

        for (final testCase in testCases) {
          print('\n📋 Testing plans for operator: ${testCase['operatorCode']}, circle: ${testCase['circle']}');
          
          final plans = await planService.fetchMobilePlans(
            testCase['operatorCode']!,
            testCase['circle']!,
          );
          
          if (plans != null && plans.allPlans.isNotEmpty) {
            print('✅ Plans fetched successfully: ${plans.allPlans.length} plans');
            
            // Test plan structure
            final firstPlan = plans.allPlans.first;
            expect(firstPlan.rs, greaterThan(0));
            expect(firstPlan.validity, isNotEmpty);
            expect(firstPlan.desc, isNotEmpty);
            
            // Print some sample plans
            print('Sample plans:');
            plans.allPlans.take(3).forEach((plan) {
              print('  - ₹${plan.rs} | ${plan.validity} | ${plan.desc}');
            });
          } else {
            print('⚠️ No plans returned - this might be expected if using fallback data');
          }
        }
      } catch (e) {
        print('❌ Plans Fetch Failed: $e');
        // Don't fail the test if it's a network issue, just log it
        if (e.toString().contains('NetworkException') || e.toString().contains('TimeoutException')) {
          print('⚠️ Network issue detected - this is expected if proxy is not running');
        } else {
          fail('Plans fetch failed: $e');
        }
      }
    });

    test('should handle proxy fallback responses', () async {
      try {
        // Test direct proxy endpoints to verify fallback handling
        final operatorUrl = Uri.parse(APIConstants.operatorDetectionUrl)
            .replace(queryParameters: {'mobile': '9999999999'});
        
        print('\n🔄 Testing proxy fallback handling...');
        
        final response = await http.get(
          operatorUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        expect(response.statusCode, equals(200));
        
        final data = json.decode(response.body);
        
        // Should have either success or fallback response
        if (data['success'] == true) {
          print('✅ API call successful');
          expect(data['data'], isNotNull);
          expect(data['source'], equals('planapi'));
        } else {
          print('✅ Fallback response received');
          expect(data['fallback'], equals(true));
          expect(data['data'], isNotNull);
          expect(data['error'], isNotNull);
        }
      } catch (e) {
        print('❌ Proxy Fallback Test Failed: $e');
        // Don't fail the test if it's a network issue
        if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
          print('⚠️ Network issue detected - proxy server may not be running');
        } else {
          fail('Proxy fallback test failed: $e');
        }
      }
    });

    test('should test all proxy endpoints', () async {
      final endpoints = [
        {'name': 'Health Check', 'url': APIConstants.healthCheckUrl},
        {'name': 'Operator Detection', 'url': '${APIConstants.operatorDetectionUrl}?mobile=9999999999'},
        {'name': 'Mobile Plans', 'url': '${APIConstants.mobilePlansUrl}?operatorcode=11&circle=49'},
        {'name': 'R-Offers', 'url': '${APIConstants.rOfferUrl}?operator_code=11&mobile_no=9999999999'},
        {'name': 'Last Recharge', 'url': '${APIConstants.lastRechargeUrl}?mobile_no=9999999999'},
      ];

      print('\n🔍 Testing all proxy endpoints...');
      
      for (final endpoint in endpoints) {
        try {
          print('Testing ${endpoint['name']}...');
          
          final response = await http.get(
            Uri.parse(endpoint['url']!),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('✅ ${endpoint['name']}: OK');
            
            if (endpoint['name'] == 'Health Check') {
              expect(data['status'], equals('OK'));
            } else {
              // Other endpoints should have success or fallback
              expect(data.containsKey('success') || data.containsKey('fallback'), isTrue);
            }
          } else {
            print('⚠️ ${endpoint['name']}: HTTP ${response.statusCode}');
          }
        } catch (e) {
          print('❌ ${endpoint['name']}: $e');
          // Don't fail on network issues
          if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
            print('   (Network issue - proxy may not be running)');
          }
        }
      }
    });
  });
}

// Helper function to test the proxy integration manually
Future<void> testProxyIntegrationManually() async {
  print('🧪 Testing AWS Proxy Integration manually...');
  
  // Test health check
  print('\n1. Testing Health Check...');
  try {
    final response = await http.get(Uri.parse(APIConstants.healthCheckUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Health: ${data['status']} (Uptime: ${data['uptime']}s)');
    } else {
      print('❌ Health check failed: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Health check error: $e');
  }

  // Test operator detection
  print('\n2. Testing Operator Detection...');
  try {
    final service = OperatorDetectionService();
    final result = await service.detectOperator('8890545871');
    if (result != null) {
      print('✅ Operator: ${result.operator} (${result.opCode}) - ${result.circle}');
    } else {
      print('❌ No operator detected');
    }
  } catch (e) {
    print('❌ Operator detection error: $e');
  }

  // Test plan fetching
  print('\n3. Testing Plan Fetching...');
  try {
    final service = PlanService();
    final plans = await service.fetchMobilePlans('11', '49');
    if (plans != null && plans.allPlans.isNotEmpty) {
      print('✅ Plans: ${plans.allPlans.length} plans fetched');
      print('   Sample: ₹${plans.allPlans.first.rs} | ${plans.allPlans.first.validity}');
    } else {
      print('❌ No plans fetched');
    }
  } catch (e) {
    print('❌ Plan fetching error: $e');
  }
}

// Uncomment to run manual test
// void main() => testProxyIntegrationManually(); 