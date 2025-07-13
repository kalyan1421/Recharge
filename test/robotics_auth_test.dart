import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Robotics Exchange Authentication Tests', () {
    late RoboticsExchangeService roboticsService;
    late ProxyService proxyService;

    setUp(() {
      proxyService = ProxyService();
      roboticsService = RoboticsExchangeService(proxyService: proxyService);
    });

    tearDown(() {
      roboticsService.dispose();
      proxyService.dispose();
    });

    test('should test wallet balance to verify authentication', () async {
      try {
        print('🧪 Testing Robotics Exchange Authentication...');
        
        // Test wallet balance endpoint (simplest auth test)
        final response = await roboticsService.getWalletBalance();
        
        print('✅ Authentication SUCCESS');
        print('Response: ${response.toString()}');
        
        expect(response, isNotNull);
        
      } catch (e) {
        print('❌ Authentication FAILED: $e');
        
        // Check if it's specifically an auth error
        if (e.toString().contains('authentication') || 
            e.toString().contains('Agent authentication failed')) {
          print('🔍 This is an authentication error');
          print('💡 Possible causes:');
          print('   1. Invalid credentials (Member ID: 3425)');
          print('   2. IP address not whitelisted');
          print('   3. Account suspended/deactivated');
          print('   4. Incorrect parameter names');
        }
        
        // Re-throw to fail the test
        throw e;
      }
    });

    test('should test direct API call without proxy', () async {
      try {
        print('🧪 Testing Direct API Call...');
        
        // Test direct API call to isolate proxy issues
        final uri = Uri.parse('https://api.roboticexchange.in/Robotics/webservice/GetWalletBalance').replace(
          queryParameters: {
            'Apimember_id': '3425',
            'Api_password': 'Neela@415263',
          },
        );
        
        print('🔗 Direct API URL: $uri');
        
        final response = await http.get(uri).timeout(const Duration(seconds: 30));
        
        print('📥 Direct API Response Status: ${response.statusCode}');
        print('📥 Direct API Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          print('✅ Direct API call successful');
          print('Response data: $jsonData');
        } else {
          print('❌ Direct API call failed with status: ${response.statusCode}');
        }
        
      } catch (e) {
        print('❌ Direct API call error: $e');
      }
    });

    test('should test with alternative parameter names', () async {
      try {
        print('🧪 Testing Alternative Parameter Names...');
        
        // Test with different parameter name combinations
        final testCases = [
          {
            'name': 'Standard Parameters',
            'params': {
              'Apimember_id': '3425',
              'Api_password': 'Neela@415263',
            }
          },
          {
            'name': 'Lowercase Parameters',
            'params': {
              'apimember_id': '3425',
              'api_password': 'Neela@415263',
            }
          },
          {
            'name': 'Mixed Case Parameters',
            'params': {
              'ApiMember_Id': '3425',
              'Api_Password': 'Neela@415263',
            }
          },
          {
            'name': 'Alternative Names',
            'params': {
              'member_id': '3425',
              'password': 'Neela@415263',
            }
          },
        ];
        
        for (final testCase in testCases) {
          print('🔄 Testing: ${testCase['name']}');
          
          final uri = Uri.parse('https://api.roboticexchange.in/Robotics/webservice/GetWalletBalance').replace(
            queryParameters: testCase['params'] as Map<String, String>,
          );
          
          try {
            final response = await http.get(uri).timeout(const Duration(seconds: 10));
            print('   Status: ${response.statusCode}');
            print('   Response: ${response.body}');
            
            if (response.statusCode == 200) {
              final jsonData = json.decode(response.body);
              if (jsonData['Errorcode'] == '0') {
                print('   ✅ SUCCESS with ${testCase['name']}');
              } else {
                print('   ❌ Error: ${jsonData['Message']}');
              }
            }
          } catch (e) {
            print('   ❌ Exception: $e');
          }
          
          print('');
        }
        
      } catch (e) {
        print('❌ Parameter test error: $e');
      }
    });

    test('should provide authentication troubleshooting guide', () async {
      print('🔧 ROBOTICS EXCHANGE AUTHENTICATION TROUBLESHOOTING GUIDE');
      print('');
      print('Current Credentials:');
      print('  Member ID: 3425');
      print('  Password: Neela@415263');
      print('');
      print('Possible Solutions:');
      print('1. 🔐 Verify credentials with Robotics Exchange support');
      print('2. 📍 Check IP whitelisting (current server IP needs to be whitelisted)');
      print('3. 💰 Verify account status and balance');
      print('4. 📞 Contact support: 8386900033');
      print('5. 🌐 Check network connectivity to api.roboticexchange.in');
      print('');
      print('Common Error Codes:');
      print('  - "Agent authentication failed from OID" = Invalid credentials/IP');
      print('  - "User Not Active" = Account suspended');
      print('  - "Insufficient Balance" = Low API balance');
      print('  - "Invalid Request From IP" = IP not whitelisted');
      print('');
      print('Next Steps:');
      print('1. Contact Robotics Exchange support to verify account status');
      print('2. Request IP whitelisting for your server');
      print('3. Verify credentials are still valid');
      print('4. Check if account needs reactivation');
    });
  });
} 