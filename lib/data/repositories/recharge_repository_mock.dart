

import '../../data/models/recharge_request.dart';
import '../../domain/entities/recharge.dart';


class RechargeRepositoryMock {
  // Mock data storage
  static final List<RechargeHistory> _rechargeHistory = [];
  static final List<PlanDetails> _mockPlans = [];
  static final List<Operator> _mockOperators = [];

  // Initialize with demo data
  RechargeRepositoryMock() {
    _initializeDemoData();
  }

  void _initializeDemoData() {
    if (_mockPlans.isEmpty) {
      // Add demo plans
      _mockPlans.addAll([
        const PlanDetails(
          planId: 'plan_001',
          operator: 'AIRTEL',
          circle: 'Delhi',
          amount: 199.0,
          validity: '28 days',
          benefits: ['1.5GB/day', 'Unlimited calls', '100 SMS/day'],
          description: 'Popular plan with daily data',
          planType: 'Full Talktime',
        ),
        const PlanDetails(
          planId: 'plan_002',
          operator: 'AIRTEL',
          circle: 'Delhi',
          amount: 299.0,
          validity: '28 days',
          benefits: ['2GB/day', 'Unlimited calls', '100 SMS/day', 'Disney+ Hotstar'],
          description: 'Premium plan with OTT benefits',
          planType: 'Full Talktime',
        ),
        const PlanDetails(
          planId: 'plan_003',
          operator: 'AIRTEL',
          circle: 'Delhi',
          amount: 399.0,
          validity: '56 days',
          benefits: ['2.5GB/day', 'Unlimited calls', '100 SMS/day', 'Amazon Prime'],
          description: 'Long validity with premium benefits',
          planType: 'Full Talktime',
        ),
        const PlanDetails(
          planId: 'plan_004',
          operator: 'AIRTEL',
          circle: 'Delhi',
          amount: 599.0,
          validity: '84 days',
          benefits: ['2GB/day', 'Unlimited calls', '100 SMS/day', 'Netflix + Prime'],
          description: 'Ultimate entertainment plan',
          planType: 'Full Talktime',
        ),
        const PlanDetails(
          planId: 'plan_005',
          operator: 'AIRTEL',
          circle: 'Delhi',
          amount: 99.0,
          validity: '28 days',
          benefits: ['6GB total', '200 mins', '300 SMS'],
          description: 'Budget plan for light users',
          planType: 'Data',
        ),
      ]);

      // Add demo operators
      _mockOperators.addAll([
        const Operator(code: 'AIRTEL', name: 'Airtel', type: ServiceType.prepaid),
        const Operator(code: 'JIO', name: 'Jio', type: ServiceType.prepaid),
        const Operator(code: 'VODAFONE', name: 'Vi', type: ServiceType.prepaid),
        const Operator(code: 'BSNL', name: 'BSNL', type: ServiceType.prepaid),
      ]);

      // Add demo recharge history
      _rechargeHistory.addAll([
        RechargeHistory(
          rechargeId: 'rch_001',
          userId: 'user_demo_001',
          mobile: '9876543210',
          operatorCode: 'AIRTEL',
          operatorName: 'Airtel',
          serviceType: ServiceType.prepaid,
          amount: 199.0,
          status: RechargeStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          operatorTransactionId: 'OP123456789',
          planId: 'plan_001',
          circle: 'Delhi',
        ),
        RechargeHistory(
          rechargeId: 'rch_002',
          userId: 'user_demo_001',
          mobile: '9876543210',
          operatorCode: 'AIRTEL',
          operatorName: 'Airtel',
          serviceType: ServiceType.prepaid,
          amount: 299.0,
          status: RechargeStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 35)),
          operatorTransactionId: 'OP987654321',
          planId: 'plan_002',
          circle: 'Delhi',
        ),
        RechargeHistory(
          rechargeId: 'rch_003',
          userId: 'user_demo_001',
          mobile: '8765432109',
          operatorCode: 'JIO',
          operatorName: 'Jio',
          serviceType: ServiceType.prepaid,
          amount: 399.0,
          status: RechargeStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 12)),
          operatorTransactionId: 'OP555666777',
          planId: 'plan_003',
          circle: 'Mumbai',
        ),
      ]);
    }
  }

  // Get plans for operator and circle
  Future<List<PlanDetails>> getPlans({
    required String operatorCode,
    required String circle,
    required ServiceType serviceType,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Filter plans by operator
    return _mockPlans.where((plan) => plan.operator == operatorCode).toList();
  }

  // Perform recharge
  Future<RechargeResponse> performRecharge(RechargeRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success/failure (90% success rate)
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      final rechargeHistory = RechargeHistory(
        rechargeId: request.requestId,
        userId: request.userId,
        mobile: request.mobile,
        operatorCode: request.operatorCode,
        operatorName: _getOperatorName(request.operatorCode),
        serviceType: request.serviceType,
        amount: request.amount,
        status: RechargeStatus.success,
        timestamp: DateTime.now(),
        operatorTransactionId: 'OP${DateTime.now().millisecondsSinceEpoch}',
        planId: request.planId,
        circle: request.circle,
      );

      _rechargeHistory.insert(0, rechargeHistory);

      return RechargeResponse(
        transactionId: request.requestId,
        status: 'SUCCESS',
        message: 'Recharge completed successfully',
        operatorTransactionId: rechargeHistory.operatorTransactionId!,
        amount: request.amount,
        balance: 1500.0, // Mock balance
        timestamp: DateTime.now(),
      );
    } else {
      return RechargeResponse(
        transactionId: request.requestId,
        status: 'FAILED',
        message: 'Recharge failed due to operator issue',
        operatorTransactionId: null,
        amount: request.amount,
        balance: 1500.0, // Mock balance
        timestamp: DateTime.now(),
      );
    }
  }

  // Get recharge history
  Future<List<RechargeHistory>> getRechargeHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _rechargeHistory.where((history) => history.userId == userId).toList();
  }

  // Check recharge status
  Future<RechargeStatus> checkRechargeStatus(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final history = _rechargeHistory.firstWhere(
      (h) => h.rechargeId == transactionId,
      orElse: () => RechargeHistory(
        rechargeId: transactionId,
        userId: '',
        mobile: '',
        operatorCode: '',
        operatorName: '',
        serviceType: ServiceType.prepaid,
        amount: 0.0,
        status: RechargeStatus.failed,
        timestamp: DateTime.now(),
        circle: '',
      ),
    );

    return history.status;
  }

  // Get operators
  Future<List<Operator>> getOperators(ServiceType serviceType) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return _mockOperators.where((op) => op.type == serviceType).toList();
  }

  // Helper method to get operator name
  String _getOperatorName(String operatorCode) {
    final operator = _mockOperators.firstWhere(
      (op) => op.code == operatorCode,
      orElse: () => const Operator(code: '', name: 'Unknown', type: ServiceType.prepaid),
    );
    return operator.name;
  }
} 