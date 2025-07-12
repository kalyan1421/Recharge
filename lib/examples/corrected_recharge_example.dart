import 'package:logger/logger.dart';
import '../data/services/operator_detection_service.dart';
import '../data/services/corrected_live_recharge_service.dart';
import '../data/services/plan_api_service.dart';
import '../core/constants/api_constants.dart';

/// Complete example demonstrating the corrected recharge flow
class CorrectedRechargeExample {
  final Logger _logger = Logger();
  final OperatorDetectionService _operatorService = OperatorDetectionService();
  final CorrectedLiveRechargeService _rechargeService = CorrectedLiveRechargeService();
  final PlanApiService _planService = PlanApiService();

  /// Complete recharge flow with proper error handling
  Future<void> performCompleteRecharge({
    required String userId,
    required String mobileNumber,
    required double amount,
  }) async {
    try {
      _logger.i('🚀 Starting complete recharge flow');
      _logger.i('User ID: $userId');
      _logger.i('Mobile: ${_maskMobileNumber(mobileNumber)}');
      _logger.i('Amount: ₹$amount');
      
      // Step 1: Detect operator and circle
      _logger.i('📡 Step 1: Detecting operator and circle...');
      final operatorInfo = await _operatorService.detectOperator(mobileNumber);
      
      if (operatorInfo == null) {
        throw Exception('Failed to detect operator for mobile number: $mobileNumber');
      }
      
      _logger.i('✅ Operator detected: ${operatorInfo.operator} (${operatorInfo.opCode})');
      _logger.i('📍 Circle: ${operatorInfo.circle} (${operatorInfo.circleCode})');
      
      // Step 2: Fetch mobile plans (optional - for validation)
      _logger.i('📋 Step 2: Fetching mobile plans...');
      final mobilePlans = await _planService.fetchMobilePlans(
        operatorInfo.opCode,
        operatorInfo.circleCode ?? '49',
      );
      
      if (mobilePlans != null && mobilePlans.allPlans.isNotEmpty) {
        _logger.i('✅ Found ${mobilePlans.allPlans.length} available plans');
        
        // Find a plan that matches the amount
        final matchingPlan = mobilePlans.allPlans.firstWhere(
          (plan) => plan.rs == amount.toInt(),
          orElse: () => mobilePlans.allPlans.first,
        );
        
        _logger.i('📝 Selected plan: ${matchingPlan.desc} - ₹${matchingPlan.rs}');
      } else {
        _logger.w('⚠️ No plans found, using default plan details');
      }
      
      // Step 3: Check wallet balance
      _logger.i('💰 Step 3: Checking wallet balance...');
      final walletResponse = await _rechargeService.checkWalletBalance();
      
      final walletBalance = double.tryParse(
        walletResponse['BuyerWalletBalance']?.toString() ?? '0'
      ) ?? 0.0;
      
      _logger.i('💳 Current wallet balance: ₹$walletBalance');
      
      if (walletBalance < amount) {
        throw Exception('Insufficient wallet balance. Available: ₹$walletBalance, Required: ₹$amount');
      }
      
      // Step 4: Process recharge
      _logger.i('🔄 Step 4: Processing recharge...');
      final rechargeResult = await _rechargeService.processLiveRecharge(
        userId: userId,
        mobileNumber: mobileNumber,
        operatorCode: operatorInfo.opCode,
        operatorName: operatorInfo.operator,
        circleCode: operatorInfo.circleCode ?? '49',
        planAmount: amount.toInt(),
        planDescription: 'Recharge for ${operatorInfo.operator}',
        validity: '30 days',
        walletBalance: walletBalance,
      );
      
      // Step 5: Handle result
      if (rechargeResult.success) {
        _logger.i('🎉 Recharge successful!');
        _logger.i('📄 Transaction ID: ${rechargeResult.transactionId}');
        _logger.i('🏢 Operator Transaction ID: ${rechargeResult.operatorTransactionId}');
        _logger.i('📊 Status: ${rechargeResult.status}');
        _logger.i('💬 Message: ${rechargeResult.message}');
        
        // If status is PROCESSING, check status after a delay
        if (rechargeResult.status == 'PROCESSING') {
          _logger.i('⏳ Recharge is processing, checking status in 30 seconds...');
          await Future.delayed(const Duration(seconds: 30));
          
          final statusResult = await _rechargeService.checkRechargeStatus(
            rechargeResult.transactionId,
          );
          
          if (statusResult != null) {
            _logger.i('📊 Updated status: ${statusResult.status}');
            _logger.i('💬 Updated message: ${statusResult.message}');
          }
        }
      } else {
        _logger.e('❌ Recharge failed!');
        _logger.e('📄 Transaction ID: ${rechargeResult.transactionId}');
        _logger.e('📊 Status: ${rechargeResult.status}');
        _logger.e('💬 Message: ${rechargeResult.message}');
        
        throw Exception('Recharge failed: ${rechargeResult.message}');
      }
      
      _logger.i('✅ Complete recharge flow finished successfully');
      
    } catch (e) {
      _logger.e('❌ Complete recharge flow failed: $e');
      rethrow;
    }
  }

  /// Test operator detection with various mobile numbers
  Future<void> testOperatorDetection() async {
    final testNumbers = [
      '9876543210', // Generic test
      '6012345678', // Jio pattern
      '7012345678', // Airtel pattern
      '9012345678', // Vi pattern
      '9456789012', // BSNL pattern
    ];
    
    _logger.i('🧪 Testing operator detection with various numbers...');
    
    for (final number in testNumbers) {
      try {
        _logger.i('📞 Testing number: ${_maskMobileNumber(number)}');
        
        final result = await _operatorService.detectOperator(number);
        
        if (result != null) {
          _logger.i('✅ Detected: ${result.operator} (${result.opCode}) - ${result.circle}');
          _logger.i('🔄 Robotics Code: ${APIConstants.planApiToRoboticsMapping[result.opCode] ?? 'Unknown'}');
        } else {
          _logger.w('⚠️ No operator detected for $number');
        }
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _logger.e('❌ Error testing $number: $e');
      }
    }
  }

  /// Test wallet balance and operator balances
  Future<void> testWalletAndOperatorBalances() async {
    try {
      _logger.i('💰 Testing wallet balance...');
      
      // Test wallet balance
      final walletResult = await _rechargeService.checkWalletBalance();
      _logger.i('💳 Wallet response: $walletResult');
      
      final errorCode = walletResult['ERROR']?.toString() ?? '1';
      final status = walletResult['STATUS']?.toString() ?? '3';
      final message = walletResult['MESSAGE']?.toString() ?? 'Unknown';
      
      _logger.i('🔍 Wallet API Response:');
      _logger.i('  - Error Code: $errorCode');
      _logger.i('  - Status: $status');
      _logger.i('  - Message: $message');
      
      if (errorCode == '0' && status == '1') {
        final balance = walletResult['BuyerWalletBalance']?.toString() ?? '0';
        _logger.i('💰 Current Balance: ₹$balance');
      } else {
        _logger.w('⚠️ Wallet check failed: $message');
      }
      
    } catch (e) {
      _logger.e('❌ Error testing wallet balance: $e');
    }
  }

  /// Test mobile plans fetching
  Future<void> testMobilePlansFetching() async {
    final testOperators = [
      {'name': 'Jio', 'code': '11'},
      {'name': 'Airtel', 'code': '2'},
      {'name': 'Vi', 'code': '23'},
      {'name': 'BSNL', 'code': '5'},
    ];
    
    _logger.i('📋 Testing mobile plans fetching...');
    
    for (final operator in testOperators) {
      try {
        _logger.i('📱 Testing plans for ${operator['name']} (${operator['code']})...');
        
        final plans = await _planService.fetchMobilePlans(
          operator['code']!,
          '49', // AP circle
        );
        
        if (plans != null && plans.allPlans.isNotEmpty) {
          _logger.i('✅ Found ${plans.allPlans.length} plans for ${operator['name']}');
          
          // Show first 3 plans
          for (int i = 0; i < plans.allPlans.length && i < 3; i++) {
            final plan = plans.allPlans[i];
            _logger.i('  📝 Plan ${i + 1}: ₹${plan.rs} - ${plan.desc}');
          }
        } else {
          _logger.w('⚠️ No plans found for ${operator['name']}');
        }
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _logger.e('❌ Error testing plans for ${operator['name']}: $e');
      }
    }
  }

  /// Debug API credentials and endpoints
  void debugAPIConfiguration() {
    _logger.i('🔧 API Configuration Debug:');
    _logger.i('');
    _logger.i('📡 PlanAPI.in Configuration:');
    _logger.i('  - User ID: ${APIConstants.apiUserId}');
    _logger.i('  - Password: ${APIConstants.apiPassword}');
    _logger.i('  - Token: ${APIConstants.apiToken}');
    _logger.i('  - Operator Detection URL: ${APIConstants.operatorDetectionUrl}');
    _logger.i('  - Mobile Plans URL: ${APIConstants.mobilePlansUrl}');
    _logger.i('');
    _logger.i('🤖 Robotics Exchange Configuration:');
    _logger.i('  - Member ID: ${APIConstants.roboticsApiMemberId}');
    _logger.i('  - Password: ${APIConstants.roboticsApiPassword}');
    _logger.i('  - Recharge URL: ${APIConstants.roboticsRechargeUrl}');
    _logger.i('  - Wallet Balance URL: ${APIConstants.roboticsWalletBalanceUrl}');
    _logger.i('  - Status Check URL: ${APIConstants.roboticsStatusCheckUrl}');
    _logger.i('');
    _logger.i('🔄 Operator Code Mapping:');
    APIConstants.planApiToRoboticsMapping.forEach((planCode, roboticsCode) {
      _logger.i('  - PlanAPI $planCode → Robotics $roboticsCode');
    });
  }

  /// Run all tests
  Future<void> runAllTests() async {
    try {
      _logger.i('🧪 Running all recharge integration tests...');
      
      // Debug configuration
      debugAPIConfiguration();
      
      // Test operator detection
      await testOperatorDetection();
      
      // Test wallet balance
      await testWalletAndOperatorBalances();
      
      // Test mobile plans
      await testMobilePlansFetching();
      
      _logger.i('✅ All tests completed');
      
    } catch (e) {
      _logger.e('❌ Test suite failed: $e');
    }
  }

  /// Example usage with a real recharge
  Future<void> exampleRecharge() async {
    try {
      _logger.i('💡 Example: Performing a test recharge...');
      
      // Example recharge with test data
      await performCompleteRecharge(
        userId: 'user123',
        mobileNumber: '9876543210',
        amount: 10.0, // Small amount for testing
      );
      
    } catch (e) {
      _logger.e('❌ Example recharge failed: $e');
    }
  }

  /// Utility method to mask mobile number
  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }
}

/// Main function to demonstrate usage
void main() async {
  final example = CorrectedRechargeExample();
  
  // Run all tests
  await example.runAllTests();
  
  // Uncomment below to test actual recharge (be careful with real money!)
  // await example.exampleRecharge();
} 