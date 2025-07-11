import 'package:flutter/material.dart';
import '../../data/repositories/recharge_repository_mock.dart';
import '../../data/repositories/wallet_repository_mock.dart';
import '../../data/models/recharge_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/recharge.dart';
import '../../domain/entities/wallet_transaction.dart';

enum RechargeState { initial, loading, loaded, processing, success, error }

class RechargeViewModel extends ChangeNotifier {
  final RechargeRepositoryMock _rechargeRepository = RechargeRepositoryMock();
  final WalletRepositoryMock _walletRepository = WalletRepositoryMock();
  
  RechargeState _state = RechargeState.initial;
  List<PlanDetails> _plans = [];
  List<RechargeHistory> _transactionHistory = [];
  String? _errorMessage;
  String? _successMessage;
  
  // AI Recommendations
  List<PlanDetails> _recommendedPlans = [];
  Map<String, dynamic> _usageInsights = {};
  
  // Form data
  String _selectedOperator = '';
  String _selectedCircle = '';
  String _mobileNumber = '';
  double _amount = 0.0;
  PlanDetails? _selectedPlan;
  
  // Getters
  RechargeState get state => _state;
  List<PlanDetails> get plans => _plans;
  List<PlanDetails> get recommendedPlans => _recommendedPlans;
  List<RechargeHistory> get transactionHistory => _transactionHistory;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, dynamic> get usageInsights => _usageInsights;
  bool get isLoading => _state == RechargeState.loading;
  bool get isProcessing => _state == RechargeState.processing;
  
  // Form getters
  String get selectedOperator => _selectedOperator;
  String get selectedCircle => _selectedCircle;
  String get mobileNumber => _mobileNumber;
  double get amount => _amount;
  PlanDetails? get selectedPlan => _selectedPlan;

  // Load plans for operator and circle
  Future<void> loadPlans(String operator, String circle) async {
    _setState(RechargeState.loading);
    
    try {
      _selectedOperator = operator;
      _selectedCircle = circle;
      
      _plans = await _rechargeRepository.getPlans(
        operatorCode: operator,
        circle: circle,
        serviceType: ServiceType.prepaid,
      );
      _generateAIRecommendations();
      _setState(RechargeState.loaded);
    } catch (e) {
      _setError('Failed to load plans: $e');
    }
  }

  // Generate AI-powered plan recommendations
  void _generateAIRecommendations() {
    if (_plans.isEmpty || _transactionHistory.isEmpty) {
      _recommendedPlans = _plans.take(3).toList();
      return;
    }

    // Analyze user's recharge history
    final rechargeAmounts = _transactionHistory
        .where((t) => t.status == RechargeStatus.success)
        .map((t) => t.amount)
        .toList();
    
    if (rechargeAmounts.isEmpty) {
      _recommendedPlans = _plans.take(3).toList();
      return;
    }

    // Calculate user's preferred amount range
    final averageAmount = rechargeAmounts.reduce((a, b) => a + b) / rechargeAmounts.length;
    final minAmount = averageAmount * 0.8;
    final maxAmount = averageAmount * 1.2;

    // Filter plans based on user preferences
    final filteredPlans = _plans.where((plan) {
      return plan.amount >= minAmount && plan.amount <= maxAmount;
    }).toList();

    // Sort by popularity and value
    filteredPlans.sort((a, b) {
      // Prioritize plans with more benefits
      final aBenefits = a.benefits.length;
      final bBenefits = b.benefits.length;
      
      if (aBenefits != bBenefits) {
        return bBenefits.compareTo(aBenefits);
      }
      
      // Then by amount (lower to higher)
      return a.amount.compareTo(b.amount);
    });

    _recommendedPlans = filteredPlans.take(5).toList();
    _generateUsageInsights(rechargeAmounts);
  }

  // Generate usage insights
  void _generateUsageInsights(List<double> amounts) {
    if (amounts.isEmpty) return;

    final totalSpent = amounts.reduce((a, b) => a + b);
    final averageAmount = totalSpent / amounts.length;
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    final minAmount = amounts.reduce((a, b) => a < b ? a : b);

    // Calculate recharge frequency
    final last30Days = _transactionHistory.where((t) {
      return t.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30)));
    }).length;

    _usageInsights = {
      'averageRecharge': averageAmount,
      'totalSpent': totalSpent,
      'maxRecharge': maxAmount,
      'minRecharge': minAmount,
      'monthlyFrequency': last30Days,
      'preferredRange': '₹${minAmount.toInt()} - ₹${maxAmount.toInt()}',
      'savingsOpportunity': _calculateSavingsOpportunity(averageAmount),
    };
  }

  // Calculate potential savings
  double _calculateSavingsOpportunity(double averageAmount) {
    if (_plans.isEmpty) return 0.0;

    // Find plans with better value (more benefits for similar price)
    final similarPlans = _plans.where((plan) {
      return (plan.amount - averageAmount).abs() <= 50;
    }).toList();

    if (similarPlans.isEmpty) return 0.0;

    // Find plan with most benefits
    final bestPlan = similarPlans.reduce((a, b) {
      return a.benefits.length > b.benefits.length ? a : b;
    });

    return (averageAmount - bestPlan.amount).abs();
  }

  // Process recharge
  Future<void> processRecharge({
    required String userId,
    required String walletId,
    required String mobile,
    required String operatorCode,
    required OperatorType operatorType,
    required ServiceType serviceType,
    required double amount,
    required String circle,
    String? planId,
  }) async {
    _setState(RechargeState.processing);

    try {
      // Check wallet balance first
      final hasBalance = await _walletRepository.debitWallet(
        walletId: walletId,
        amount: amount,
        purpose: 'Recharge for $mobile',
        transactionId: _generateTransactionId(),
      );

      if (!hasBalance) {
        _setError('Insufficient wallet balance');
        return;
      }

      // Create recharge request
      final request = RechargeRequest(
        userId: userId,
        mobile: mobile,
        operatorCode: operatorCode,
        operatorType: operatorType,
        serviceType: serviceType,
        amount: amount,
        circle: circle,
        planId: planId,
        requestId: _generateTransactionId(),
        timestamp: DateTime.now(),
      );

      // Process recharge with multi-API failover
      final response = await _rechargeRepository.performRecharge(request);
      
      if (response.status == 'SUCCESS' || response.status == 'PENDING') {
        _successMessage = 'Recharge ${response.status.toLowerCase()} for $mobile';
        _setState(RechargeState.success);
        
        // Refresh transaction history
        await loadTransactionHistory(userId);
        
        // Update AI recommendations based on new transaction
        _generateAIRecommendations();
      } else {
        // Refund wallet on failure
        await _walletRepository.creditWallet(
          walletId: walletId,
          amount: amount,
          type: WalletTransactionType.refund,
          description: 'Recharge failed refund',
          transactionId: response.transactionId,
        );
        
        _setError('Recharge failed: ${response.message}');
      }
    } catch (e) {
      _setError('Recharge failed: $e');
      
      // Attempt to refund on error
      try {
        await _walletRepository.creditWallet(
          walletId: walletId,
          amount: amount,
          type: WalletTransactionType.refund,
          description: 'Recharge error refund',
          transactionId: _generateTransactionId(),
        );
      } catch (refundError) {
        print('Refund failed: $refundError');
      }
    }
  }

  // Load transaction history
  Future<void> loadTransactionHistory(String userId) async {
    try {
      _transactionHistory = await _rechargeRepository.getRechargeHistory(userId);
      notifyListeners();
    } catch (e) {
      print('Failed to load transaction history: $e');
    }
  }

  // Check transaction status
  Future<String> checkTransactionStatus(String transactionId) async {
    try {
      final status = await _rechargeRepository.checkRechargeStatus(transactionId);
      return status.toString().split('.').last;
    } catch (e) {
      print('Failed to check transaction status: $e');
      return 'failed';
    }
  }

  // Dispute transaction
  Future<void> disputeTransaction({
    required String transactionId,
    required String userId,
    required String reason,
    required String description,
  }) async {
    try {
      // Dispute functionality would be implemented in full version
      // await _rechargeRepository.disputeTransaction(
      //   transactionId: transactionId,
      //   userId: userId,
      //   reason: reason,
      //   description: description,
      // );
      _successMessage = 'Dispute submitted successfully (Demo)';
      notifyListeners();
    } catch (e) {
      _setError('Failed to submit dispute: $e');
    }
  }

  // Smart plan recommendations based on usage pattern
  List<PlanDetails> getSmartRecommendations(String usageType) {
    switch (usageType.toLowerCase()) {
      case 'heavy':
        return _plans.where((p) => 
          p.benefits.any((b) => b.toLowerCase().contains('unlimited')) &&
          p.amount > 400
        ).take(3).toList();
      
      case 'moderate':
        return _plans.where((p) => 
          p.amount >= 200 && p.amount <= 400
        ).take(3).toList();
      
      case 'light':
        return _plans.where((p) => 
          p.amount < 200
        ).take(3).toList();
      
      default:
        return _recommendedPlans;
    }
  }

  // Get best value plans
  List<PlanDetails> getBestValuePlans() {
    if (_plans.isEmpty) return [];
    
    return _plans.where((p) => 
      p.benefits.length >= 3 && 
      p.validity.contains('28') || p.validity.contains('30')
    ).take(3).toList();
  }

  // Form management
  void setMobileNumber(String mobile) {
    _mobileNumber = mobile;
    notifyListeners();
  }

  void setAmount(double amount) {
    _amount = amount;
    notifyListeners();
  }

  void selectPlan(PlanDetails plan) {
    _selectedPlan = plan;
    _amount = plan.amount;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlan = null;
    _amount = 0.0;
    notifyListeners();
  }

  // Helper methods
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}';
  }

  void _setState(RechargeState newState) {
    _state = newState;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = RechargeState.error;
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 