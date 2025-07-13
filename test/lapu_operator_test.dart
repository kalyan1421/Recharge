import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';
import 'package:recharger/data/models/recharge_models.dart';

void main() {
  group('LAPU Authentication Diagnostics', () {
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

    test('should check LAPU wise balance for different operators', () async {
      print('🔍 Testing LAPU Balance for Different Operators');
      
      final operatorCodes = ['AT', 'JO', 'VI', 'BS'];
      final operatorNames = ['AIRTEL', 'JIO', 'VODAFONEIDEA', 'BSNL'];
      
      for (int i = 0; i < operatorCodes.length; i++) {
        final operatorCode = operatorCodes[i];
        final operatorName = operatorNames[i];
        
        print('\n📱 Testing $operatorName ($operatorCode):');
        
        try {
          final lapuBalance = await roboticsService.getLapuWiseBalance(operatorCode);
          
          if (lapuBalance != null) {
            print('✅ $operatorName - LAPU Balance Response:');
            print('   Raw Response: $lapuBalance');
            
            // Check for specific LAPU authentication errors
            final errorCode = lapuBalance['ERROR']?.toString() ?? 'N/A';
            final status = lapuBalance['STATUS']?.toString() ?? 'N/A';
            final message = lapuBalance['MESSAGE']?.toString() ?? 'N/A';
            
            print('   Error Code: $errorCode');
            print('   Status: $status');
            print('   Message: $message');
            
            // Look for LAPU-specific fields
            if (lapuBalance.containsKey('LAPU_BALANCE')) {
              print('   LAPU Balance: ${lapuBalance['LAPU_BALANCE']}');
            }
            if (lapuBalance.containsKey('LAPU_STATUS')) {
              print('   LAPU Status: ${lapuBalance['LAPU_STATUS']}');
            }
            if (lapuBalance.containsKey('LAPU_LOGIN_REQUIRED')) {
              print('   LAPU Login Required: ${lapuBalance['LAPU_LOGIN_REQUIRED']}');
            }
            
          } else {
            print('❌ $operatorName - No response received');
          }
        } catch (e) {
          print('❌ $operatorName - Error: $e');
        }
      }
    });

    test('should test small recharge for different operators', () async {
      print('\n🧪 Testing Small Recharge (₹10) for Different Operators');
      
      final testCases = [
        {'operator': 'AIRTEL', 'code': 'AT', 'mobile': '7777777777'},
        {'operator': 'JIO', 'code': 'JO', 'mobile': '8888888888'},
        {'operator': 'VODAFONEIDEA', 'code': 'VI', 'mobile': '9999999999'},
      ];
      
      for (final testCase in testCases) {
        final operatorName = testCase['operator']!;
        final operatorCode = testCase['code']!;
        final mobileNumber = testCase['mobile']!;
        
        print('\n📱 Testing $operatorName ($operatorCode):');
        
        try {
          final response = await roboticsService.performRecharge(
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            circleName: 'DELHI',
            amount: '10',
          );
          
          print('✅ $operatorName - Recharge Response:');
          print('   Error Code: ${response.error}');
          print('   Status: ${response.status}');
          print('   Message: ${response.message}');
          print('   Order ID: ${response.orderId}');
          print('   LAPU No: ${response.lapuNo ?? 'N/A'}');
          
          // Check for LAPU authentication issues
          if (response.message.toLowerCase().contains('lapu')) {
            print('⚠️  LAPU-related message detected!');
            print('   Full Message: ${response.message}');
          }
          
          if (response.message.toLowerCase().contains('login')) {
            print('🔐 Login-related message detected!');
            print('   Full Message: ${response.message}');
          }
          
        } catch (e) {
          print('❌ $operatorName - Error: $e');
        }
      }
    });

    test('should test operator balance API', () async {
      print('\n💰 Testing Operator Balance API:');
      
      try {
        final operatorBalance = await roboticsService.getOperatorBalance();
        
        print('✅ Operator Balance Response:');
        print('   Error Code: ${operatorBalance.errorCode}');
        print('   Status: ${operatorBalance.status}');
        print('   Message: ${operatorBalance.message ?? 'N/A'}');
        print('   Record: ${operatorBalance.record ?? 'N/A'}');
        
        // Check if different operators have different balance requirements
        if (operatorBalance.record != null) {
          print('📊 Operator Balance Details:');
          operatorBalance.record!.forEach((key, value) {
            print('   $key: $value');
          });
        }
        
      } catch (e) {
        print('❌ Operator Balance Error: $e');
      }
    });

    test('should check wallet balance and compare with LAPU requirements', () async {
      print('\n💳 Testing Wallet Balance:');
      
      try {
        final walletBalance = await roboticsService.getWalletBalance();
        
        print('✅ Wallet Balance Response:');
        print('   Error Code: ${walletBalance.errorCode}');
        print('   Status: ${walletBalance.status}');
        print('   Message: ${walletBalance.message}');
        print('   Buyer Balance: ${walletBalance.buyerWalletBalance ?? 'N/A'}');
        print('   Seller Balance: ${walletBalance.sellerWalletBalance ?? 'N/A'}');
        
        // Analysis
        print('\n📊 Balance Analysis:');
        final totalBalance = (walletBalance.buyerWalletBalance ?? 0) + 
                           (walletBalance.sellerWalletBalance ?? 0);
        print('   Total Balance: ₹$totalBalance');
        
        if (totalBalance == 0) {
          print('⚠️  Zero balance detected - this might cause LAPU login issues');
        }
        
      } catch (e) {
        print('❌ Wallet Balance Error: $e');
      }
    });
  });
} 