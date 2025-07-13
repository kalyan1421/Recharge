import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';
import 'package:recharger/data/models/recharge_models.dart';

void main() {
  group('JIO LITE Solution Tests', () {
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

    test('should map JIO operators to JIO LITE (JL)', () {
      // Test operator mapping
      expect(OperatorMapping.getOperatorCode('JIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('RELIANCE JIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('RELIANCE'), 'JL');
      
      print('✅ JIO operators correctly mapped to JIO LITE (JL)');
    });

    test('should check JIO LITE LAPU balance and status', () async {
      print('🧪 Testing JIO LITE LAPU Status and Balance');
      
      try {
        // Check JIO LITE LAPU balance
        final lapuBalance = await roboticsService.getLapuWiseBalance('JL');
        
        if (lapuBalance != null) {
          print('📋 JIO LITE LAPU Response:');
          print('   Error Code: ${lapuBalance['ERROR']}');
          print('   Message: ${lapuBalance['MESSAGE']}');
          
          if (lapuBalance['ERROR'] == '0') {
            final lapuReport = lapuBalance['LAPUREPORT'] as List<dynamic>?;
            if (lapuReport != null) {
              print('   📊 JIO LITE LAPU Details:');
              
              double totalBalance = 0;
              int activeCount = 0;
              
              for (final lapu in lapuReport) {
                final lapuNumber = lapu['LapuNumber'] ?? 'N/A';
                final status = lapu['Lstatus'] ?? 'N/A';
                final balance = double.tryParse(lapu['LapuBal']?.toString() ?? '0') ?? 0.0;
                
                print('   💳 LAPU: $lapuNumber | Status: $status | Balance: ₹$balance');
                
                if (status == 'Active') {
                  activeCount++;
                  totalBalance += balance;
                }
              }
              
              print('   📈 Summary: $activeCount active LAPU(s) with total balance: ₹$totalBalance');
              
              // Verify we have active JIO LITE LAPU numbers
              expect(activeCount, greaterThan(0), reason: 'Should have active JIO LITE LAPU numbers');
              expect(totalBalance, greaterThan(0), reason: 'Should have positive balance in JIO LITE LAPU');
              
              print('✅ JIO LITE LAPU numbers are active and have balance');
            }
          }
        }
      } catch (e) {
        print('❌ Error testing JIO LITE LAPU: $e');
        fail('Failed to test JIO LITE LAPU: $e');
      }
    });

    test('should simulate JIO recharge using JIO LITE', () async {
      print('🧪 Testing JIO Recharge Simulation with JIO LITE');
      
      try {
        // Simulate a JIO recharge that should use JIO LITE
        final operatorCode = OperatorMapping.getOperatorCode('JIO');
        final circleCode = OperatorMapping.getCircleCode('TN');
        
        print('📱 Simulating JIO recharge:');
        print('   Original Operator: JIO');
        print('   Mapped Operator Code: $operatorCode (should be JL)');
        print('   Circle Code: $circleCode');
        
        // Verify the mapping
        expect(operatorCode, 'JL', reason: 'JIO should map to JIO LITE (JL)');
        
        // Check if JIO LITE is active
        final isActive = await roboticsService.isLapuActive('JL');
        print('   JIO LITE Status: ${isActive ? "Active ✅" : "Inactive ❌"}');
        
        expect(isActive, true, reason: 'JIO LITE LAPU should be active');
        
        print('✅ JIO recharge simulation successful - will use active JIO LITE LAPU');
      } catch (e) {
        print('❌ Error in JIO recharge simulation: $e');
        fail('Failed JIO recharge simulation: $e');
      }
    });
  });
} 