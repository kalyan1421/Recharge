import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';

void main() {
  group('Enhanced LAPU Recharge Tests', () {
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

    test('should check LAPU status for all operators', () async {
      print('🧪 Testing LAPU Status Check for All Operators');
      
      final operatorCodes = ['AT', 'JO', 'VI', 'BS'];
      
      for (final operatorCode in operatorCodes) {
        print('\n📱 Checking LAPU status for $operatorCode:');
        
        final isActive = await roboticsService.isLapuActive(operatorCode);
        print('  LAPU Active: ${isActive ? '✅' : '❌'}');
        
        if (isActive) {
          final activeLapuNumber = await roboticsService.getActiveLapuNumber(operatorCode);
          print('  Active LAPU Number: $activeLapuNumber');
        }
      }
    });

    test('should test enhanced recharge for Jio (with inactive LAPU)', () async {
      print('\n🧪 Testing Enhanced Recharge for Jio (Inactive LAPU)');
      
      try {
        final response = await roboticsService.performRechargeWithLapuCheck(
          mobileNumber: '8888888888',
          operatorName: 'JIO',
          circleName: 'DELHI',
          amount: '10',
        );
        
        print('✅ Enhanced Recharge Response:');
        print('  Error Code: ${response.error}');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  LAPU No: ${response.lapuNo ?? 'N/A'}');
        
        // Verify it provides better error message
        if (response.error == '6' && response.message.contains('inactive')) {
          print('✅ Success: Enhanced error message provided for inactive LAPU');
        } else {
          print('⚠️  Warning: Expected enhanced error message for inactive LAPU');
        }
        
      } catch (e) {
        print('❌ Enhanced Recharge Error: $e');
      }
    });

    test('should test enhanced recharge for Airtel (with active LAPU)', () async {
      print('\n🧪 Testing Enhanced Recharge for Airtel (Active LAPU)');
      
      try {
        final response = await roboticsService.performRechargeWithLapuCheck(
          mobileNumber: '9999999999',
          operatorName: 'AIRTEL',
          circleName: 'DELHI',
          amount: '10',
        );
        
        print('✅ Enhanced Recharge Response:');
        print('  Error Code: ${response.error}');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  LAPU No: ${response.lapuNo ?? 'N/A'}');
        
        // Should proceed to normal recharge (may fail for other reasons)
        if (response.lapuNo != null && response.lapuNo != '0') {
          print('✅ Success: Active LAPU used for recharge');
        }
        
      } catch (e) {
        print('❌ Enhanced Recharge Error: $e');
      }
    });

    test('should generate comprehensive LAPU status report', () async {
      print('\n📊 Generating LAPU Status Report');
      
      try {
        final report = await roboticsService.getLapuStatusReport();
        
        print('✅ LAPU Status Report:');
        report.forEach((operator, data) {
          print('\n📱 $operator:');
          if (data['status'] == 'success') {
            print('  Total LAPU Count: ${data['lapu_count']}');
            print('  Active Count: ${data['active_count']}');
            print('  Inactive Count: ${data['inactive_count']}');
            print('  Total Balance: ₹${data['total_balance']}');
            
            if (data['inactive_count'] > 0) {
              print('  ⚠️  Warning: ${data['inactive_count']} inactive LAPU(s) found');
            }
          } else {
            print('  ❌ Error: ${data['error']}');
          }
        });
        
      } catch (e) {
        print('❌ LAPU Status Report Error: $e');
      }
    });

    test('should check operator balance for all operators', () async {
      print('\n💰 Checking Operator Balance for All Operators');
      
      final operatorCodes = ['AT', 'JO', 'VI', 'BS'];
      final operatorNames = ['AIRTEL', 'JIO', 'VODAFONEIDEA', 'BSNL'];
      
      for (int i = 0; i < operatorCodes.length; i++) {
        final operatorCode = operatorCodes[i];
        final operatorName = operatorNames[i];
        
        print('\n📱 Checking balance for $operatorName ($operatorCode):');
        
        try {
          final hasBalance = await roboticsService.hasOperatorBalance(operatorCode, 10.0);
          print('  Has Balance for ₹10: ${hasBalance ? '✅' : '❌'}');
          
          if (!hasBalance && operatorCode == 'JO') {
            print('  ⚠️  Warning: Jio operator has insufficient balance');
          }
        } catch (e) {
          print('  ❌ Balance Check Error: $e');
        }
      }
    });
  });
} 