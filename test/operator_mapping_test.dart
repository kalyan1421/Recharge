import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/models/recharge_models.dart';

void main() {
  group('OperatorMapping Tests', () {
    test('should map Jio operator variations to JIO LITE (JL)', () {
      // Test various Jio operator names - all should map to JIO LITE (JL)
      expect(OperatorMapping.getOperatorCode('JIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('RELIANCE JIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('RELIANCE'), 'JL');
      expect(OperatorMapping.getOperatorCode('RJI'), 'JL');
      expect(OperatorMapping.getOperatorCode('RJIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('jio'), 'JL'); // lowercase
      expect(OperatorMapping.getOperatorCode('Reliance Jio'), 'JL'); // mixed case
    });

    test('should map Airtel operator variations correctly', () {
      expect(OperatorMapping.getOperatorCode('AIRTEL'), 'AT');
      expect(OperatorMapping.getOperatorCode('airtel'), 'AT'); // lowercase
      expect(OperatorMapping.getOperatorCode('BHARTI AIRTEL'), 'AT');
    });

    test('should map Vi/Vodafone/Idea operator variations correctly', () {
      expect(OperatorMapping.getOperatorCode('VODAFONEIDEA'), 'VI');
      expect(OperatorMapping.getOperatorCode('VODAFONE'), 'VI');
      expect(OperatorMapping.getOperatorCode('IDEA'), 'VI');
      expect(OperatorMapping.getOperatorCode('VI'), 'VI');
    });

    test('should map BSNL operator variations correctly', () {
      expect(OperatorMapping.getOperatorCode('BSNL'), 'BS');
    });

    test('should handle unknown operators', () {
      // Should default to AIRTEL for unknown operators
      expect(OperatorMapping.getOperatorCode('UNKNOWN_OPERATOR'), 'AT');
      expect(OperatorMapping.getOperatorCode(''), 'AT');
    });
  });

  group('Circle Mapping Tests', () {
    test('should map circle names to codes correctly', () {
      expect(OperatorMapping.getCircleCode('DELHI'), '10');
      expect(OperatorMapping.getCircleCode('MUMBAI'), '92');
      expect(OperatorMapping.getCircleCode('KOLKATTA'), '31');
      expect(OperatorMapping.getCircleCode('CHENNAI'), '20');
      expect(OperatorMapping.getCircleCode('BENGALURU'), '06');
      expect(OperatorMapping.getCircleCode('HYDERABAD'), '49');
      expect(OperatorMapping.getCircleCode('ANDHRA PRADESH'), '49');
      expect(OperatorMapping.getCircleCode('AP'), '49');
    });

    test('should handle unknown circles', () {
      // Should default to Delhi
      expect(OperatorMapping.getCircleCode('UNKNOWN_CIRCLE'), '10');
      expect(OperatorMapping.getCircleCode(''), '10');
    });
  });

  group('Real-world Operator Name Tests', () {
    test('should handle common PlanAPI operator names', () {
      // These are typical operator names returned by PlanAPI
      // JIO operators now map to JIO LITE (JL) due to inactive JIO LAPU
      expect(OperatorMapping.getOperatorCode('RELIANCE JIO'), 'JL');
      expect(OperatorMapping.getOperatorCode('BHARTI AIRTEL'), 'AT');
      expect(OperatorMapping.getOperatorCode('VODAFONE IDEA'), 'VI');
      expect(OperatorMapping.getOperatorCode('BSNL'), 'BS');
    });

    test('should prioritize Jio LITE for Jio patterns', () {
      // Test that Jio patterns get mapped to JIO LITE (JL)
      expect(OperatorMapping.getOperatorCode('JIO AIRTEL'), 'JL'); // Should match JIO first -> JIO LITE
      expect(OperatorMapping.getOperatorCode('RELIANCE SOMETHING'), 'JL'); // Should match RELIANCE -> JIO LITE
    });

    test('should handle DTH operators correctly', () {
      expect(OperatorMapping.getOperatorCode('SUN TV'), 'SD');
      expect(OperatorMapping.getOperatorCode('DISH TV'), 'DT');
      expect(OperatorMapping.getOperatorCode('TATASKY'), 'TS');
      expect(OperatorMapping.getOperatorCode('VIDEOCON'), 'VD');
    });
  });
} 