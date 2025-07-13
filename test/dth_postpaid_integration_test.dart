import 'package:flutter_test/flutter_test.dart';
import 'package:recharger/data/services/dth_service.dart';
import 'package:recharger/data/services/postpaid_service.dart';
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/data/models/recharge_models.dart';

void main() {
  group('DTH and Postpaid Integration Tests', () {
    late DthService dthService;
    late PostpaidService postpaidService;

    setUp(() {
      dthService = DthService();
      postpaidService = PostpaidService();
    });

    tearDown(() {
      dthService.dispose();
      postpaidService.dispose();
    });

    group('DTH Service Tests', () {
      test('should validate DTH number format correctly', () {
        // Valid DTH numbers
        expect(dthService.validateDthNumber('1234567890'), true);
        expect(dthService.validateDthNumber('12345678901'), true);
        expect(dthService.validateDthNumber('123456789012'), true);
        
        // Invalid DTH numbers
        expect(dthService.validateDthNumber('123456789'), false); // Too short
        expect(dthService.validateDthNumber('1234567890123'), false); // Too long
        expect(dthService.validateDthNumber('123456789a'), false); // Contains letters
        expect(dthService.validateDthNumber(''), false); // Empty
        
        print('✅ DTH number validation tests passed');
      });

      test('should get available DTH operators', () {
        final operators = dthService.getAvailableDthOperators();
        
        expect(operators.length, greaterThan(0));
        expect(operators.any((op) => op['name'] == 'AIRTEL DTH'), true);
        expect(operators.any((op) => op['name'] == 'DISH TV'), true);
        expect(operators.any((op) => op['name'] == 'TATA SKY'), true);
        
        print('✅ Available DTH operators: ${operators.length}');
        for (final op in operators) {
          print('   - ${op['name']} (${op['roboticsCode']})');
        }
      });

      test('should get DTH operator suggestions', () {
        final suggestions1 = dthService.getDthOperatorSuggestions('100');
        expect(suggestions1.any((s) => s['name'] == 'AIRTEL DTH'), true);
        
        final suggestions2 = dthService.getDthOperatorSuggestions('200');
        expect(suggestions2.any((s) => s['name'] == 'DISH TV'), true);
        
        final suggestions3 = dthService.getDthOperatorSuggestions('300');
        expect(suggestions3.any((s) => s['name'] == 'TATA SKY'), true);
        
        print('✅ DTH operator suggestions working correctly');
      });

      test('should parse DTH plans correctly', () {
        // Create a mock DTH plans response
        final mockPlansResponse = DthPlansResponse(
          error: '0',
          status: '0',
          operator: 'AIRTEL DTH',
          message: 'Success',
          rdata: DthRData(
            combo: [
              DthCombo(
                language: 'Hindi',
                packCount: '1',
                details: [
                  DthPlanDetail(
                    planName: 'Hindi Entertainment',
                    channels: '361 Channels',
                    paidChannels: '360 Paid Channels',
                    hdChannels: '1 HD Channels',
                    lastUpdate: '05-10-2024',
                    pricingList: [
                      DthPricing(amount: '₹279', month: '1 Months'),
                      DthPricing(amount: '₹1549', month: '6 Months'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        final parsedPlans = dthService.parseDthPlans(mockPlansResponse);
        
        expect(parsedPlans.length, 2); // Two pricing options
        expect(parsedPlans[0]['plan_name'], 'Hindi Entertainment');
        expect(parsedPlans[0]['language'], 'Hindi');
        expect(parsedPlans[0]['operator'], 'AIRTEL DTH');
        expect(parsedPlans[0]['type'], 'DTH');
        
        print('✅ DTH plan parsing working correctly');
        print('   Parsed ${parsedPlans.length} plans');
      });
    });

    group('Postpaid Service Tests', () {
      test('should check postpaid number status', () async {
        // Test postpaid number detection
        final isPostpaid1 = await postpaidService.isPostpaidNumber('9999123456');
        expect(isPostpaid1, true); // Premium series
        
        final isPostpaid2 = await postpaidService.isPostpaidNumber('8888123456');
        expect(isPostpaid2, true); // Corporate series
        
        final isPostpaid3 = await postpaidService.isPostpaidNumber('9876543210');
        expect(isPostpaid3, false); // Regular number
        
        print('✅ Postpaid number detection working correctly');
      });

      test('should check operator postpaid support', () {
        expect(postpaidService.supportsPostpaid('AIRTEL'), true);
        expect(postpaidService.supportsPostpaid('JIO'), true);
        expect(postpaidService.supportsPostpaid('VODAFONE'), true);
        expect(postpaidService.supportsPostpaid('BSNL'), true);
        expect(postpaidService.supportsPostpaid('UNKNOWN'), false);
        
        print('✅ Postpaid operator support check working correctly');
      });

      test('should get postpaid plan types', () {
        final planTypes = postpaidService.getPostpaidPlanTypes();
        
        expect(planTypes.contains('Individual'), true);
        expect(planTypes.contains('Corporate'), true);
        expect(planTypes.contains('Business'), true);
        expect(planTypes.contains('Family'), true);
        
        print('✅ Postpaid plan types: ${planTypes.join(', ')}');
      });

      test('should fetch postpaid plans', () async {
        final plans = await postpaidService.fetchPostpaidPlans(
          operatorCode: 'AT',
          circleCode: '10',
        );
        
        expect(plans.length, greaterThan(0));
        
        for (final plan in plans) {
          expect(plan.type, RechargeType.postpaid);
          expect(plan.numericAmount, greaterThan(0));
        }
        
        print('✅ Fetched ${plans.length} postpaid plans');
        for (final plan in plans) {
          print('   - ${plan.planName}: ${plan.amount}');
        }
      });
    });

    group('DTH Operator Mapping Tests', () {
      test('should map DTH operators correctly', () {
        // PlanAPI to Robotics mapping
        expect(DthOperatorMapping.getPlanApiOperatorCode('AIRTEL DTH'), '24');
        expect(DthOperatorMapping.getPlanApiOperatorCode('DISH TV'), '25');
        expect(DthOperatorMapping.getPlanApiOperatorCode('TATA SKY'), '28');
        
        expect(DthOperatorMapping.getRoboticsOperatorCode('AIRTEL DTH'), 'AD');
        expect(DthOperatorMapping.getRoboticsOperatorCode('DISH TV'), 'DT');
        expect(DthOperatorMapping.getRoboticsOperatorCode('TATA SKY'), 'TS');
        
        // Direct mapping
        expect(DthOperatorMapping.mapPlanApiToRobotics('24'), 'AD');
        expect(DthOperatorMapping.mapPlanApiToRobotics('25'), 'DT');
        expect(DthOperatorMapping.mapPlanApiToRobotics('28'), 'TS');
        
        print('✅ DTH operator mapping working correctly');
      });
    });

    group('Enhanced Operator Mapping Tests', () {
      test('should detect DTH operators correctly', () {
        expect(OperatorMapping.isDthOperator('AIRTEL DTH'), true);
        expect(OperatorMapping.isDthOperator('DISH TV'), true);
        expect(OperatorMapping.isDthOperator('TATA SKY'), true);
        expect(OperatorMapping.isDthOperator('VIDEOCON D2H'), true);
        expect(OperatorMapping.isDthOperator('AIRTEL'), false);
        expect(OperatorMapping.isDthOperator('JIO'), false);
        
        print('✅ DTH operator detection working correctly');
      });

      test('should detect mobile operators correctly', () {
        expect(OperatorMapping.isMobileOperator('AIRTEL'), true);
        expect(OperatorMapping.isMobileOperator('JIO'), true);
        expect(OperatorMapping.isMobileOperator('VODAFONE'), true);
        expect(OperatorMapping.isMobileOperator('AIRTEL DTH'), false);
        expect(OperatorMapping.isMobileOperator('DISH TV'), false);
        
        print('✅ Mobile operator detection working correctly');
      });

      test('should determine plan types correctly', () {
        expect(OperatorMapping.getPlanType('Postpaid Plan', 'Monthly billing'), 'postpaid');
        expect(OperatorMapping.getPlanType('DTH Plan', 'DTH recharge'), 'dth');
        expect(OperatorMapping.getPlanType('Regular Plan', 'Prepaid recharge'), 'prepaid');
        
        print('✅ Plan type detection working correctly');
      });
    });

    group('Integration Tests', () {
      test('should handle complete DTH flow simulation', () {
        print('🧪 Testing complete DTH flow simulation');
        
        // 1. Validate DTH number
        const dthNumber = '1234567890';
        expect(dthService.validateDthNumber(dthNumber), true);
        print('   ✅ DTH number validation passed');
        
        // 2. Get operator suggestions
        final suggestions = dthService.getDthOperatorSuggestions(dthNumber);
        expect(suggestions.length, greaterThan(0));
        print('   ✅ Operator suggestions retrieved');
        
        // 3. Check available operators
        final operators = dthService.getAvailableDthOperators();
        expect(operators.length, greaterThan(0));
        print('   ✅ Available operators retrieved');
        
        print('✅ DTH flow simulation completed successfully');
      });

      test('should handle complete postpaid flow simulation', () async {
        print('🧪 Testing complete postpaid flow simulation');
        
        // 1. Check postpaid number
        const mobileNumber = '9999123456';
        final isPostpaid = await postpaidService.isPostpaidNumber(mobileNumber);
        expect(isPostpaid, true);
        print('   ✅ Postpaid number detection passed');
        
        // 2. Check operator support
        const operatorName = 'AIRTEL';
        expect(postpaidService.supportsPostpaid(operatorName), true);
        print('   ✅ Operator postpaid support confirmed');
        
        // 3. Get plan types
        final planTypes = postpaidService.getPostpaidPlanTypes();
        expect(planTypes.length, greaterThan(0));
        print('   ✅ Plan types retrieved');
        
        // 4. Fetch plans
        final plans = await postpaidService.fetchPostpaidPlans(
          operatorCode: 'AT',
          circleCode: '10',
        );
        expect(plans.length, greaterThan(0));
        print('   ✅ Postpaid plans fetched');
        
        print('✅ Postpaid flow simulation completed successfully');
      });
    });

    group('Error Handling Tests', () {
      test('should handle DTH service errors gracefully', () {
        // Test with empty DTH number
        expect(dthService.validateDthNumber(''), false);
        
        // Test with invalid DTH number
        expect(dthService.validateDthNumber('invalid'), false);
        
        // Test operator suggestions with empty input
        final suggestions = dthService.getDthOperatorSuggestions('');
        expect(suggestions.length, greaterThan(0)); // Should return all operators
        
        print('✅ DTH error handling working correctly');
      });

      test('should handle postpaid service errors gracefully', () async {
        // Test with unknown operator
        expect(postpaidService.supportsPostpaid('UNKNOWN_OPERATOR'), false);
        
        // Test plan types (should always return some types)
        final planTypes = postpaidService.getPostpaidPlanTypes();
        expect(planTypes.length, greaterThan(0));
        
        print('✅ Postpaid error handling working correctly');
      });
    });
  });
} 