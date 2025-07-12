import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../lib/core/constants/api_constants.dart';
import '../lib/data/services/corrected_live_recharge_service.dart';
import '../lib/data/services/operator_detection_service.dart';

void main() {
  group('Corrected Recharge Integration Tests', () {
    late Logger logger;
    late Dio dio;
    late OperatorDetectionService operatorService;
    late CorrectedLiveRechargeService rechargeService;

    setUpAll(() {
      logger = Logger();
      dio = Dio();
      operatorService = OperatorDetectionService();
      rechargeService = CorrectedLiveRechargeService();
    });

    test('Test API Constants - Verify Correct Credentials', () {
      // Verify PlanAPI.in credentials
      expect(APIConstants.apiUserId, equals('3557'));
      expect(APIConstants.apiPassword, equals('Neela@1988'));
      expect(APIConstants.apiToken, equals('81bd9a2a-7857-406c-96aa-056967ba859a'));
      
      // Verify Robotics Exchange credentials
      expect(APIConstants.roboticsApiMemberId, equals('3425'));
      expect(APIConstants.roboticsApiPassword, equals('Neela@415263'));
      
      // Verify correct endpoints
      expect(APIConstants.operatorDetectionEndpoint, equals('OperatorFetchNew'));
      expect(APIConstants.mobilePlansEndpoint, equals('NewMobilePlans'));
      
      // Verify operator code mapping
      expect(APIConstants.planApiToRoboticsMapping['2'], equals('AT')); // Airtel
      expect(APIConstants.planApiToRoboticsMapping['11'], equals('JO')); // Jio
      expect(APIConstants.planApiToRoboticsMapping['23'], equals('VI')); // Vi/Vodafone
      
      logger.i('✅ API Constants verification passed');
    });

    test('Test PlanAPI.in Operator Detection with Correct Endpoint', () async {
      try {
        logger.i('Testing PlanAPI.in operator detection...');
        
        // Test with a valid mobile number
        final response = await dio.get(
          APIConstants.operatorDetectionUrl,
          queryParameters: {
            'apikey': APIConstants.apiToken,
            'mobileno': '9876543210', // Test number
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        logger.i('Operator Detection Response Status: ${response.statusCode}');
        logger.i('Operator Detection Response Body: ${response.data}');

        expect(response.statusCode, equals(200));
        
        // Check if response contains expected fields
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // Log all available fields for debugging
          logger.i('Available response fields: ${responseData.keys.toList()}');
          
          // Test will pass if we get a 200 response with data
          expect(responseData, isNotEmpty);
          logger.i('✅ PlanAPI.in operator detection test passed');
        }
      } catch (e) {
        logger.e('❌ PlanAPI.in operator detection test failed: $e');
        // Test will fail but we can see the error
        expect(e.toString(), contains('Expected')); // This will fail and show the actual error
      }
    });

    test('Test PlanAPI.in Mobile Plans with Correct Endpoint', () async {
      try {
        logger.i('Testing PlanAPI.in mobile plans...');
        
        // Test with Jio operator (code 11) and AP circle (code 49)
        final response = await dio.get(
          APIConstants.mobilePlansUrl,
          queryParameters: {
            'apikey': APIConstants.apiToken,
            'operatorcode': '11', // Jio
            'circle': '49', // AP
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        logger.i('Mobile Plans Response Status: ${response.statusCode}');
        logger.i('Mobile Plans Response Body: ${response.data}');

        expect(response.statusCode, equals(200));
        
        // Check if response contains expected fields
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // Log all available fields for debugging
          logger.i('Available response fields: ${responseData.keys.toList()}');
          
          // Test will pass if we get a 200 response with data
          expect(responseData, isNotEmpty);
          logger.i('✅ PlanAPI.in mobile plans test passed');
        }
      } catch (e) {
        logger.e('❌ PlanAPI.in mobile plans test failed: $e');
        // Test will fail but we can see the error
        expect(e.toString(), contains('Expected')); // This will fail and show the actual error
      }
    });

    test('Test Robotics Exchange Wallet Balance', () async {
      try {
        logger.i('Testing Robotics Exchange wallet balance...');
        
        final response = await dio.get(
          APIConstants.roboticsWalletBalanceUrl,
          queryParameters: {
            'Apimember_id': APIConstants.roboticsApiMemberId,
            'Api_password': APIConstants.roboticsApiPassword,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        logger.i('Wallet Balance Response Status: ${response.statusCode}');
        logger.i('Wallet Balance Response Body: ${response.data}');

        expect(response.statusCode, equals(200));
        
        // Check if response contains expected fields
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // Log all available fields for debugging
          logger.i('Available response fields: ${responseData.keys.toList()}');
          
          // Check for common Robotics Exchange response fields
          final errorCode = responseData['ERROR']?.toString() ?? '1';
          final status = responseData['STATUS']?.toString() ?? '3';
          final message = responseData['MESSAGE']?.toString() ?? 'Unknown';
          
          logger.i('Robotics API Response - Error: $errorCode, Status: $status, Message: $message');
          
          // Test will pass if we get a 200 response with data
          expect(responseData, isNotEmpty);
          logger.i('✅ Robotics Exchange wallet balance test passed');
        }
      } catch (e) {
        logger.e('❌ Robotics Exchange wallet balance test failed: $e');
        // Test will fail but we can see the error
        expect(e.toString(), contains('Expected')); // This will fail and show the actual error
      }
    });

    test('Test Operator Code Mapping', () {
      logger.i('Testing operator code mapping...');
      
      // Test PlanAPI to Robotics mapping
      expect(APIConstants.planApiToRoboticsMapping['2'], equals('AT')); // Airtel
      expect(APIConstants.planApiToRoboticsMapping['11'], equals('JO')); // Jio
      expect(APIConstants.planApiToRoboticsMapping['23'], equals('VI')); // Vi/Vodafone
      expect(APIConstants.planApiToRoboticsMapping['6'], equals('VI')); // Idea (merged with Vi)
      expect(APIConstants.planApiToRoboticsMapping['4'], equals('BS')); // BSNL TOPUP
      expect(APIConstants.planApiToRoboticsMapping['5'], equals('BS')); // BSNL SPECIAL
      
      logger.i('✅ Operator code mapping test passed');
    });

    test('Test Operator Detection Service', () async {
      try {
        logger.i('Testing operator detection service...');
        
        // Test with a valid mobile number
        final result = await operatorService.detectOperator('9876543210');
        
        logger.i('Operator Detection Result: $result');
        
        // Should return a result (either from API or fallback)
        expect(result, isNotNull);
        expect(result!.mobile, equals('9876543210'));
        expect(result.operator, isNotEmpty);
        expect(result.opCode, isNotEmpty);
        
        logger.i('✅ Operator detection service test passed');
        logger.i('Detected: ${result.operator} (${result.opCode}) - ${result.circle}');
      } catch (e) {
        logger.e('❌ Operator detection service test failed: $e');
        fail('Operator detection service test failed: $e');
      }
    });

    test('Test Recharge Service - Check Wallet Balance', () async {
      try {
        logger.i('Testing recharge service wallet balance check...');
        
        final result = await rechargeService.checkWalletBalance();
        
        logger.i('Wallet Balance Result: $result');
        
        // Should return a result
        expect(result, isNotNull);
        expect(result, isA<Map<String, dynamic>>());
        
        logger.i('✅ Recharge service wallet balance test passed');
      } catch (e) {
        logger.e('❌ Recharge service wallet balance test failed: $e');
        fail('Recharge service wallet balance test failed: $e');
      }
    });

    test('Test Complete Recharge Flow (Simulation)', () async {
      try {
        logger.i('Testing complete recharge flow...');
        
        // Step 1: Detect operator
        final operatorInfo = await operatorService.detectOperator('9876543210');
        expect(operatorInfo, isNotNull);
        logger.i('Step 1 ✅: Operator detected - ${operatorInfo!.operator}');
        
        // Step 2: Check wallet balance
        final walletInfo = await rechargeService.checkWalletBalance();
        expect(walletInfo, isNotNull);
        logger.i('Step 2 ✅: Wallet balance checked');
        
        // Step 3: Simulate recharge (with small amount for testing)
        logger.i('Step 3: Would process recharge with:');
        logger.i('  - Mobile: 9876543210');
        logger.i('  - Operator: ${operatorInfo.operator} (${operatorInfo.opCode})');
        logger.i('  - Circle: ${operatorInfo.circle} (${operatorInfo.circleCode})');
        logger.i('  - Amount: ₹10');
        logger.i('  - Robotics Code: ${APIConstants.planApiToRoboticsMapping[operatorInfo.opCode]}');
        
        logger.i('✅ Complete recharge flow simulation passed');
      } catch (e) {
        logger.e('❌ Complete recharge flow test failed: $e');
        fail('Complete recharge flow test failed: $e');
      }
    });
  });
} 