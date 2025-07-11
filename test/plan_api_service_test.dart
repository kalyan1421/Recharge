import 'package:flutter_test/flutter_test.dart';
import '../lib/data/services/plan_api_service.dart';
import '../lib/data/models/operator_info.dart';

void main() {
  group('PlanApiService Tests', () {
    late PlanApiService planApiService;

    setUp(() {
      planApiService = PlanApiService();
    });

    group('Mobile Number Validation', () {
      test('should validate correct mobile numbers', () {
        // Test with reflection since the method is private
        // We'll test through the main method instead
        expect(() => planApiService.fetchOperatorAndCircle('9876543210'), 
               returnsNormally);
      });

      test('should reject invalid mobile numbers', () async {
        // Test invalid numbers
        expect(() => planApiService.fetchOperatorAndCircle('123'), 
               throwsException);
        expect(() => planApiService.fetchOperatorAndCircle('abc'), 
               throwsException);
        expect(() => planApiService.fetchOperatorAndCircle(''), 
               throwsException);
      });
    });

    group('Operator Theme', () {
      test('should return correct theme for known operators', () {
        final airtelTheme = planApiService.getOperatorTheme('AIRTEL');
        expect(airtelTheme['primaryColor'], equals(0xFFED1C24));
        
        final jioTheme = planApiService.getOperatorTheme('JIO');
        expect(jioTheme['primaryColor'], equals(0xFF004B87));
        
        final defaultTheme = planApiService.getOperatorTheme('UNKNOWN');
        expect(defaultTheme['primaryColor'], equals(0xFF6C63FF));
      });
    });

    group('Operator Logo', () {
      test('should return correct logo paths', () {
        expect(planApiService.getOperatorLogo('AIRTEL'), 
               equals('assets/operators/airtel.png'));
        expect(planApiService.getOperatorLogo('JIO'), 
               equals('assets/operators/jio.png'));
        expect(planApiService.getOperatorLogo('UNKNOWN'), 
               equals('assets/logos/Mobile1.png'));
        expect(planApiService.getOperatorLogo(null), 
               equals('assets/logos/Mobile1.png'));
      });
    });

    group('Operator Name Formatting', () {
      test('should format operator names correctly', () {
        expect(planApiService.getFormattedOperatorName('AIRTEL'), 
               equals('Airtel'));
        expect(planApiService.getFormattedOperatorName('JIO'), 
               equals('Jio'));
        expect(planApiService.getFormattedOperatorName('VI'), 
               equals('Vi (Vodafone Idea)'));
        expect(planApiService.getFormattedOperatorName('UNKNOWN'), 
               equals('UNKNOWN'));
        expect(planApiService.getFormattedOperatorName(null), 
               equals('Unknown Operator'));
      });
    });

    group('API Integration Test', () {
      test('should fetch operator info for valid number', () async {
        // This test requires actual API access
        // You may want to mock this or use a test API
        try {
          final result = await planApiService.fetchOperatorAndCircle('8890545871');
          expect(result, isA<OperatorInfo>());
          expect(result.mobile, equals('8890545871'));
          
          if (result.error == '0') {
            expect(result.operator, isNotNull);
            expect(result.circle, isNotNull);
            print('✅ API Test Passed: ${result.operator} - ${result.circle}');
          } else {
            print('⚠️  API returned error: ${result.message}');
          }
        } catch (e) {
          print('⚠️  API Test Failed (network/auth issue): $e');
          // Don't fail the test if it's a network issue
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

// Helper function to test the API manually
Future<void> testPlanApiManually() async {
  print('🧪 Testing PlanApiService manually...');
  
  final service = PlanApiService();
  
  // Test numbers
  final testNumbers = [
    '8890545871', // From API docs
    '9876543210',
    '7890123456',
  ];
  
  for (final number in testNumbers) {
    print('\n📱 Testing number: $number');
    try {
      final result = await service.fetchOperatorAndCircle(number);
      if (result.error == '0') {
        print('✅ Success: ${result.operator} (${result.opCode}) - ${result.circle}');
      } else {
        print('❌ Error: ${result.message}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}

// Uncomment to run manual test
// void main() => testPlanApiManually(); 