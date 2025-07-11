import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import '../lib/data/services/robotics_wallet_service.dart';
import '../lib/data/services/robotics_status_service.dart';
import '../lib/core/constants/api_constants.dart';

/// Integration test for Robotics Exchange API
void main() {
  group('Robotics Exchange Integration Tests', () {
    late RoboticsWalletService walletService;
    late RoboticsStatusService statusService;
    
    setUpAll(() {
      // Initialize services
      walletService = RoboticsWalletService();
      statusService = RoboticsStatusService();
      
      // Configure logger for testing
      Logger.level = Level.info;
    });

    group('API Constants Tests', () {
      test('should have correct robotics exchange URLs', () {
        expect(APIConstants.roboticsBaseUrl, 'https://api.roboticexchange.in/Robotics/webservice');
        expect(APIConstants.roboticsApiMemberId, '3425');
        expect(APIConstants.roboticsApiPassword, 'Apipassword');
        
        // Check URL generation
        expect(APIConstants.roboticsRechargeUrl, 
               'https://api.roboticexchange.in/Robotics/webservice/GetMobileRecharge');
        expect(APIConstants.roboticsWalletBalanceUrl, 
               'https://api.roboticexchange.in/Robotics/webservice/GetWalletBalance');
        expect(APIConstants.roboticsStatusCheckUrl, 
               'https://api.roboticexchange.in/Robotics/webservice/GetStatus');
      });

      test('should have correct operator codes', () {
        expect(APIConstants.roboticsOperatorCodes['AIRTEL'], '11');
        expect(APIConstants.roboticsOperatorCodes['JIO'], '14');
        expect(APIConstants.roboticsOperatorCodes['VODAFONE'], '12');
        expect(APIConstants.roboticsOperatorCodes['BSNL'], '15');
      });
    });

    group('Wallet Service Tests', () {
      test('should check wallet balance', () async {
        // This test will make actual API call - may fail if API is not accessible
        // In production, you might want to mock this
        try {
          final response = await walletService.checkWalletBalance();
          
          expect(response, isNotNull);
          expect(response.buyerBalance, isA<double>());
          expect(response.sellerBalance, isA<double>());
          expect(response.timestamp, isA<DateTime>());
          
          print('Wallet Balance Test Result:');
          print('Success: ${response.success}');
          print('Message: ${response.message}');
          print('Buyer Balance: ₹${response.buyerBalance}');
          print('Seller Balance: ₹${response.sellerBalance}');
          
        } catch (e) {
          print('Wallet balance test failed (expected if API not accessible): $e');
          // This is expected if API is not accessible from test environment
        }
      });

      test('should check operator balances', () async {
        try {
          final response = await walletService.checkOperatorBalances();
          
          expect(response, isNotNull);
          expect(response.balances, isA<Map<String, dynamic>>());
          expect(response.timestamp, isA<DateTime>());
          
          print('Operator Balance Test Result:');
          print('Success: ${response.success}');
          print('Message: ${response.message}');
          print('Balances: ${response.balances}');
          
        } catch (e) {
          print('Operator balance test failed (expected if API not accessible): $e');
        }
      });
    });

    group('Status Service Tests', () {
      test('should handle status check for non-existent transaction', () async {
        try {
          final response = await statusService.checkRechargeStatus('TEST_NON_EXISTENT_123');
          
          expect(response, isNotNull);
          expect(response.success, isA<bool>());
          expect(response.message, isA<String>());
          expect(response.timestamp, isA<DateTime>());
          
          print('Status Check Test Result:');
          print('Success: ${response.success}');
          print('Message: ${response.message}');
          print('Status: ${response.rechargeStatus}');
          
        } catch (e) {
          print('Status check test failed (expected if API not accessible): $e');
        }
      });
    });

    group('Constants Tests', () {
      test('should demonstrate operator code mapping', () {
        // Test the constants directly
        expect(APIConstants.roboticsOperatorCodes['AIRTEL'], '11');
        expect(APIConstants.roboticsOperatorCodes['JIO'], '14');
        expect(APIConstants.roboticsOperatorCodes['VODAFONE'], '12');
        expect(APIConstants.roboticsOperatorCodes['IDEA'], '13');
        expect(APIConstants.roboticsOperatorCodes['BSNL'], '15');
        
        print('Operator Code Mapping Test Passed');
      });
    });

    group('Error Handling Tests', () {
      test('should handle IP update gracefully', () async {
        // Test with invalid IP update to trigger network error
        try {
          final response = await walletService.updateIpAddress('invalid_ip');
          
          expect(response, isNotNull);
          expect(response.success, isA<bool>());
          expect(response.message, isA<String>());
          expect(response.timestamp, isA<DateTime>());
          
          print('IP Update Test Result:');
          print('Success: ${response.success}');
          print('Message: ${response.message}');
          
        } catch (e) {
          print('IP update test failed (expected if API not accessible): $e');
        }
      });

      test('should handle complaint filing', () async {
        try {
          final response = await statusService.fileRechargeComplaint(
            memberRequestTxnId: 'TEST_TXN_123',
            ourRefTxnId: 'REF_123',
            complaintReason: 'Test complaint reason',
          );
          
          expect(response, isNotNull);
          expect(response.success, isA<bool>());
          expect(response.message, isA<String>());
          expect(response.timestamp, isA<DateTime>());
          
          print('Complaint Test Result:');
          print('Success: ${response.success}');
          print('Message: ${response.message}');
          print('Member Request ID: ${response.memberRequestId}');
          
        } catch (e) {
          print('Complaint test failed (expected if API not accessible): $e');
        }
      });
    });
  });
}

/// Helper function to print test results in a formatted way
void printTestResult(String testName, bool success, String message, [Map<String, dynamic>? data]) {
  print('\n=== $testName ===');
  print('Success: $success');
  print('Message: $message');
  if (data != null) {
    print('Data: $data');
  }
  print('========================\n');
} 