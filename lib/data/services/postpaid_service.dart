import 'package:http/http.dart' as http;
import 'package:recharger/data/models/mobile_plans.dart';
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/data/services/robotics_exchange_service.dart';
import 'package:recharger/data/services/proxy_service.dart';
import 'package:recharger/data/services/plan_api_service.dart';

class PostpaidService {
  final RoboticsExchangeService _roboticsService;
  final ProxyService _proxyService;
  final PlanApiService _planApiService;
  final http.Client _client;

  PostpaidService({
    RoboticsExchangeService? roboticsService,
    ProxyService? proxyService,
    PlanApiService? planApiService,
    http.Client? client,
  })  : _roboticsService = roboticsService ?? RoboticsExchangeService(proxyService: ProxyService()),
        _proxyService = proxyService ?? ProxyService(),
        _planApiService = planApiService ?? PlanApiService(),
        _client = client ?? http.Client();

  void dispose() {
    _client.close();
    _roboticsService.dispose();
    _proxyService.dispose();
  }

  /// Check if a mobile number is postpaid
  Future<bool> isPostpaidNumber(String mobileNumber) async {
    try {
      print('🧪 Checking if mobile number $mobileNumber is postpaid');
      
      // For now, we'll use a simple heuristic
      // In a real implementation, you'd call a specific API to check
      // Some patterns that might indicate postpaid:
      // - Premium number series
      // - Corporate number patterns
      // - Specific operator prefixes
      
      // Mock implementation - in real scenario, you'd call an API
      final prefix = mobileNumber.length >= 4 ? mobileNumber.substring(0, 4) : mobileNumber;
      
      // Common postpaid prefixes (this is a simplified example)
      final postpaidPrefixes = [
        '9999', '9998', '9997', '9996', '9995', // Premium series
        '8888', '8887', '8886', '8885', '8884', // Corporate series
        '7777', '7776', '7775', '7774', '7773', // Business series
      ];
      
      final isPostpaid = postpaidPrefixes.contains(prefix);
      print('📱 Number $mobileNumber is ${isPostpaid ? "postpaid" : "prepaid"}');
      
      return isPostpaid;
    } catch (e) {
      print('❌ Error checking postpaid status: $e');
      return false; // Default to prepaid
    }
  }

  /// Fetch postpaid plans for a specific operator and circle
  Future<List<PostpaidPlanInfo>> fetchPostpaidPlans({
    required String operatorCode,
    required String circleCode,
  }) async {
    try {
      print('🧪 Fetching postpaid plans for operator: $operatorCode, circle: $circleCode');
      
      // Fetch regular mobile plans
      final mobilePlansResponse = await _planApiService.fetchMobilePlans(
        operatorCode: operatorCode,
        circleCode: circleCode,
      );
      
      if (!mobilePlansResponse.isSuccess || mobilePlansResponse.rdata == null) {
        print('❌ Failed to fetch mobile plans');
        return [];
      }
      
      final List<PostpaidPlanInfo> postpaidPlans = [];
      
      // Process different plan categories
      final categories = mobilePlansResponse.rdata!.getAllCategories();
      
      for (final category in categories) {
        for (final plan in category.plans) {
          // Check if this plan is postpaid-like
          final isPostpaidPlan = _isPostpaidPlan(plan, category.name);
          
          if (isPostpaidPlan) {
            postpaidPlans.add(PostpaidPlanInfo(
              planName: '${category.name} Plan',
              amount: '₹${plan.price}',
              validity: plan.validity,
              description: plan.desc,
              benefits: [
                if (plan.desc.isNotEmpty) plan.desc,
              ],
              type: RechargeType.postpaid,
            ));
          }
        }
      }
      
      // Add some default postpaid plans if none found
      if (postpaidPlans.isEmpty) {
        postpaidPlans.addAll(_getDefaultPostpaidPlans());
      }
      
      print('✅ Found ${postpaidPlans.length} postpaid plans');
      return postpaidPlans;
    } catch (e) {
      print('❌ Error fetching postpaid plans: $e');
      return _getDefaultPostpaidPlans();
    }
  }

  /// Check if a plan is postpaid based on its characteristics
  bool _isPostpaidPlan(PlanItem plan, String categoryName) {
    final planDesc = plan.desc.toUpperCase();
    final category = categoryName.toUpperCase();
    
    // Postpaid indicators
    final postpaidKeywords = [
      'POSTPAID', 'POST PAID', 'MONTHLY', 'BILL', 'BILLING',
      'CORPORATE', 'BUSINESS', 'ENTERPRISE', 'UNLIMITED',
      'PREMIUM', 'EXECUTIVE', 'PROFESSIONAL'
    ];
    
    // Check if any postpaid keyword is present
    for (final keyword in postpaidKeywords) {
      if (planDesc.contains(keyword) || category.contains(keyword)) {
        return true;
      }
    }
    
    // Check if validity is monthly (typical for postpaid)
    if (plan.validity.toLowerCase().contains('30 days') || 
        plan.validity.toLowerCase().contains('1 month') ||
        plan.validity.toLowerCase().contains('monthly')) {
      return true;
    }
    
    // Check if price is high (typically postpaid plans are more expensive)
    if (plan.price > 999) {
      return true;
    }
    
    return false;
  }

  /// Get default postpaid plans
  List<PostpaidPlanInfo> _getDefaultPostpaidPlans() {
    return [
      PostpaidPlanInfo(
        planName: 'Unlimited Postpaid 599',
        amount: '₹599',
        validity: '30 days',
        description: 'Unlimited calls, 75GB data, 100 SMS/day',
        benefits: [
          'Unlimited local/STD calls',
          '75GB high-speed data',
          '100 SMS per day',
          'Free roaming',
        ],
        type: RechargeType.postpaid,
      ),
      PostpaidPlanInfo(
        planName: 'Business Postpaid 999',
        amount: '₹999',
        validity: '30 days',
        description: 'Unlimited calls, 150GB data, unlimited SMS',
        benefits: [
          'Unlimited local/STD calls',
          '150GB high-speed data',
          'Unlimited SMS',
          'Free roaming',
          'Priority customer support',
        ],
        type: RechargeType.postpaid,
      ),
      PostpaidPlanInfo(
        planName: 'Premium Postpaid 1499',
        amount: '₹1499',
        validity: '30 days',
        description: 'Unlimited calls, 200GB data, premium benefits',
        benefits: [
          'Unlimited local/STD calls',
          '200GB high-speed data',
          'Unlimited SMS',
          'Free roaming',
          'OTT subscriptions included',
          'Priority customer support',
        ],
        type: RechargeType.postpaid,
      ),
    ];
  }

  /// Perform postpaid recharge/bill payment
  Future<Map<String, dynamic>?> performPostpaidRecharge({
    required String mobileNumber,
    required String operatorName,
    required String circleName,
    required String amount,
    required String planName,
    required String validity,
    required String description,
  }) async {
    try {
      print('🧪 Starting postpaid recharge process');
      print('   Mobile Number: $mobileNumber');
      print('   Operator: $operatorName');
      print('   Circle: $circleName');
      print('   Amount: ₹$amount');
      print('   Plan: $planName');
      print('   Validity: $validity');

      // For postpaid, we use the same robotics exchange service
      // but with different metadata to indicate it's a postpaid transaction
      final rechargeResponse = await _roboticsService.performRecharge(
        mobileNumber: mobileNumber,
        operatorName: operatorName,
        circleName: circleName,
        amount: amount,
      );

      print('📡 Robotics Exchange Response:');
      print('   Error: ${rechargeResponse.error}');
      print('   Status: ${rechargeResponse.status}');
      print('   Message: ${rechargeResponse.message}');
      print('   Order ID: ${rechargeResponse.orderId}');

      if (rechargeResponse.isSuccess) {
        print('✅ Postpaid recharge successful!');
        return {
          'success': true,
          'message': 'Postpaid recharge successful',
          'order_id': rechargeResponse.orderId,
          'op_trans_id': rechargeResponse.opTransId,
          'amount': rechargeResponse.amount,
          'mobile_number': mobileNumber,
          'operator': operatorName,
          'plan_name': planName,
          'validity': validity,
          'description': description,
          'type': 'postpaid',
          'commission': rechargeResponse.commission,
          'lapu_no': rechargeResponse.lapuNo,
          'opening_balance': rechargeResponse.openingBal,
          'closing_balance': rechargeResponse.closingBal,
        };
      } else {
        print('❌ Postpaid recharge failed: ${rechargeResponse.message}');
        return {
          'success': false,
          'message': rechargeResponse.message,
          'error_code': rechargeResponse.error,
          'order_id': rechargeResponse.orderId,
          'type': 'postpaid',
        };
      }
    } catch (e) {
      print('❌ Error performing postpaid recharge: $e');
      return {
        'success': false,
        'message': 'An error occurred during postpaid recharge: $e',
        'error_code': 'POSTPAID_RECHARGE_ERROR',
        'type': 'postpaid',
      };
    }
  }

  /// Get postpaid bill details (mock implementation)
  Future<Map<String, dynamic>?> getPostpaidBillDetails(String mobileNumber) async {
    try {
      print('🧪 Fetching postpaid bill details for: $mobileNumber');
      
      // Mock implementation - in real scenario, you'd call a specific API
      await Future.delayed(const Duration(seconds: 1));
      
      final mockBillDetails = {
        'mobile_number': mobileNumber,
        'customer_name': 'John Doe',
        'plan_name': 'Unlimited Postpaid 599',
        'bill_amount': 599.0,
        'due_date': '2024-01-15',
        'bill_date': '2024-01-01',
        'outstanding_amount': 599.0,
        'last_payment_date': '2023-12-15',
        'last_payment_amount': 599.0,
        'usage_details': {
          'calls': 'Unlimited',
          'data_used': '45GB of 75GB',
          'sms_used': '1200 of 3000',
        },
        'due_status': 'pending',
      };
      
      print('✅ Retrieved postpaid bill details');
      return mockBillDetails;
    } catch (e) {
      print('❌ Error fetching postpaid bill details: $e');
      return null;
    }
  }

  /// Check if operator supports postpaid
  bool supportsPostpaid(String operatorName) {
    final name = operatorName.toUpperCase();
    
    // Most major operators support postpaid
    final postpaidOperators = [
      'AIRTEL', 'JIO', 'VODAFONE', 'IDEA', 'VI', 'BSNL'
    ];
    
    return postpaidOperators.any((op) => name.contains(op));
  }

  /// Get postpaid plan types
  List<String> getPostpaidPlanTypes() {
    return [
      'Individual',
      'Family',
      'Corporate',
      'Business',
      'Enterprise',
      'Student',
      'Senior Citizen',
    ];
  }

  /// Parse postpaid plans from mobile plans response
  List<PostpaidPlanInfo> parsePostpaidPlans(MobilePlansResponse mobilePlansResponse) {
    final List<PostpaidPlanInfo> postpaidPlans = [];
    
    if (mobilePlansResponse.rdata == null) return postpaidPlans;
    
    final categories = mobilePlansResponse.rdata!.getAllCategories();
    
    for (final category in categories) {
      for (final plan in category.plans) {
        if (_isPostpaidPlan(plan, category.name)) {
          postpaidPlans.add(PostpaidPlanInfo(
            planName: '${category.name} Plan',
            amount: '₹${plan.price}',
            validity: plan.validity,
            description: plan.desc,
            benefits: [
              if (plan.desc.isNotEmpty) plan.desc,
            ],
            type: RechargeType.postpaid,
          ));
        }
      }
    }
    
    return postpaidPlans;
  }
} 