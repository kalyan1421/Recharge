import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../config/firebase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/operator_detection_service.dart';
import '../../data/models/operator_info.dart';
import '../../domain/entities/recharge.dart';
import 'wallet_provider.dart';

enum RechargeState { loading, loaded, error }

class RechargeProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final OperatorDetectionService _operatorService = OperatorDetectionService();
  
  // State variables
  RechargeState _state = RechargeState.loaded;
  List<dynamic> _rechargeHistory = [];
  String _errorMessage = '';
  bool _isLoading = false;
  OperatorInfo? _detectedOperator;
  List<MobilePlan> _availablePlans = [];
  String _selectedCategory = AppConstants.rechargePrepaid;
  
  // Getters
  RechargeState get state => _state;
  List<dynamic> get rechargeHistory => _rechargeHistory;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  OperatorInfo? get detectedOperator => _detectedOperator;
  List<MobilePlan> get availablePlans => _availablePlans;
  String get selectedCategory => _selectedCategory;
  
  // Filtered history
  List<dynamic> get recentRecharges => _rechargeHistory.take(10).toList();
  List<dynamic> get successfulRecharges => 
      _rechargeHistory.where((r) => r?.status == AppConstants.statusSuccess).toList();
  List<dynamic> get pendingRecharges => 
      _rechargeHistory.where((r) => r?.status == AppConstants.statusPending).toList();
  
  RechargeProvider() {
    _initializeRechargeData();
  }
  
  /// Initialize recharge data
  void _initializeRechargeData() {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      loadRechargeHistory(currentUser.uid);
    }
  }
  
  /// Set selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  /// Load recharge history
  Future<void> loadRechargeHistory(String userId, {int limit = 50}) async {
    try {
      _setLoading(true);
      _clearError();
      
      _logger.i('Loading recharge history for user: $userId');
      
      final querySnapshot = await FirebaseConfig.firestore
          .collection(AppConstants.rechargesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      _rechargeHistory = querySnapshot.docs.map((doc) {
        // TODO: Implement Recharge.fromFirestore once entity is created
        return null;
      }).toList();
      
      _state = RechargeState.loaded;
      _logger.i('Loaded ${_rechargeHistory.length} recharge records');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to load recharge history: $e');
      _setError('Failed to load recharge history');
      _state = RechargeState.error;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Detect operator from mobile number
  Future<bool> detectOperator(String mobileNumber) async {
    try {
      _setLoading(true);
      _clearError();
      
      _logger.i('Detecting operator for: ${_maskMobileNumber(mobileNumber)}');
      
      final operatorInfo = await _operatorService.detectOperator(mobileNumber);
      
      if (operatorInfo != null) {
        _detectedOperator = operatorInfo;
        _logger.i('Operator detected: ${operatorInfo.operator}');
        
        // Load plans for detected operator
        await _loadPlansForOperator(operatorInfo.operator ?? 'UNKNOWN');
        
        return true;
      } else {
        _setError('Unable to detect operator for this number');
        _detectedOperator = null;
        return false;
      }
      
    } catch (e, stackTrace) {
      _logger.e('Operator detection failed: $e');
      _setError('Failed to detect operator');
      _detectedOperator = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load plans for operator
  Future<void> _loadPlansForOperator(String operator) async {
    try {
      _logger.i('Loading plans for operator: $operator');
      
      // For demo purposes, using static plans
      // In production, this would fetch from an API
      _availablePlans = _getStaticPlans(operator);
      
      _logger.i('Loaded ${_availablePlans.length} plans');
      
    } catch (e) {
      _logger.e('Failed to load plans: $e');
      _availablePlans = [];
    }
  }
  
  /// Get static plans for demo
  List<MobilePlan> _getStaticPlans(String operator) {
    // Static plans for demo - replace with API call
    return [
      MobilePlan(
        id: '1',
        operator: operator,
        amount: 199,
        validity: '28 days',
        data: '2GB/day',
        calls: 'Unlimited',
        sms: '100/day',
        type: AppConstants.planTypeUnlimited,
        description: 'Unlimited calls + 2GB data per day',
      ),
      MobilePlan(
        id: '2',
        operator: operator,
        amount: 399,
        validity: '56 days',
        data: '2.5GB/day',
        calls: 'Unlimited',
        sms: '100/day',
        type: AppConstants.planTypeUnlimited,
        description: 'Unlimited calls + 2.5GB data per day',
      ),
      MobilePlan(
        id: '3',
        operator: operator,
        amount: 599,
        validity: '84 days',
        data: '2GB/day',
        calls: 'Unlimited',
        sms: '100/day',
        type: AppConstants.planTypeUnlimited,
        description: 'Unlimited calls + 2GB data per day',
      ),
      MobilePlan(
        id: '4',
        operator: operator,
        amount: 155,
        validity: '24 days',
        data: '1GB',
        calls: 'NA',
        sms: 'NA',
        type: AppConstants.planTypeData,
        description: 'Data only plan',
      ),
      MobilePlan(
        id: '5',
        operator: operator,
        amount: 79,
        validity: '28 days',
        data: 'NA',
        calls: 'Unlimited',
        sms: '100/day',
        type: AppConstants.planTypeTalktime,
        description: 'Unlimited calls only',
      ),
    ];
  }
  
  /// Process recharge
  Future<bool> processRecharge({
    required BuildContext context,
    required String mobileNumber,
    required double amount,
    required String operator,
    String? planId,
    MobilePlan? selectedPlan,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Check wallet balance
      final walletProvider = context.read<WalletProvider>();
      if (walletProvider.balance < amount) {
        _setError(AppConstants.errorInsufficientBalance);
        return false;
      }
      
      _logger.i('Processing recharge: ₹$amount for ${_maskMobileNumber(mobileNumber)}');
      
      // Create recharge record
      final rechargeData = {
        'userId': currentUser.uid,
        'mobileNumber': mobileNumber,
        'operator': operator,
        'amount': amount,
        'category': _selectedCategory,
        'planId': planId,
        'planDetails': selectedPlan?.toMap(),
        'status': AppConstants.statusPending,
        'description': 'Mobile recharge for $mobileNumber',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final rechargeRef = await FirebaseConfig.firestore
          .collection(AppConstants.rechargesCollection)
          .add(rechargeData);
      
      // Deduct amount from wallet
      final walletSuccess = await walletProvider.deductMoney(
        amount: amount,
        purpose: 'Mobile recharge for $mobileNumber',
        referenceId: rechargeRef.id,
      );
      
      if (!walletSuccess) {
        // Delete recharge record if wallet deduction failed
        await rechargeRef.delete();
        _setError('Failed to deduct amount from wallet');
        return false;
      }
      
      // For demo purposes, immediately mark as successful
      // In production, this would involve calling recharge API
      await rechargeRef.update({
        'status': AppConstants.statusSuccess,
        'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload recharge history
      await loadRechargeHistory(currentUser.uid);
      
      // Log analytics event
      FirebaseConfig.logEvent('recharge_completed', {
        'user_id': currentUser.uid,
        'operator': operator,
        'amount': amount,
        'category': _selectedCategory,
      });
      
      _logger.i('Recharge completed successfully');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Recharge processing failed: $e');
      _setError('Recharge failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Repeat previous recharge
  Future<bool> repeatRecharge(BuildContext context, dynamic previousRecharge) async {
    return await processRecharge(
      context: context,
      mobileNumber: previousRecharge.mobileNumber,
      amount: previousRecharge.amount,
      operator: previousRecharge.operator,
      planId: previousRecharge.planId,
    );
  }
  
  /// Get filtered plans by type
  List<MobilePlan> getFilteredPlans(String type) {
    return _availablePlans.where((plan) => plan.type == type).toList();
  }
  
  /// Get recharge statistics
  Map<String, dynamic> getRechargeStats() {
    final successful = successfulRecharges;
           final totalAmount = successful.fold(0.0, (sum, r) => sum + (r?.amount ?? 0.0));
    final totalCount = successful.length;
    
    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'averageAmount': totalCount > 0 ? totalAmount / totalCount : 0.0,
      'lastRechargeDate': _rechargeHistory.isNotEmpty ? _rechargeHistory.first.createdAt : null,
    };
  }
  
  /// Get frequently recharged numbers
  List<String> getFrequentNumbers({int limit = 5}) {
    final numberCount = <String, int>{};
    
    for (final recharge in successfulRecharges) {
      numberCount[recharge.mobileNumber] = (numberCount[recharge.mobileNumber] ?? 0) + 1;
    }
    
    final sortedNumbers = numberCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedNumbers.take(limit).map((e) => e.key).toList();
  }
  
  /// Mask mobile number for logging
  String _maskMobileNumber(String number) {
    if (number.length >= 4) {
      return '${number.substring(0, 2)}****${number.substring(number.length - 2)}';
    }
    return number;
  }
  
  /// Refresh data
  Future<void> refresh() async {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      await loadRechargeHistory(currentUser.uid);
    }
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

/// Mobile Plan model
class MobilePlan {
  final String id;
  final String operator;
  final double amount;
  final String validity;
  final String data;
  final String calls;
  final String sms;
  final String type;
  final String description;
  
  const MobilePlan({
    required this.id,
    required this.operator,
    required this.amount,
    required this.validity,
    required this.data,
    required this.calls,
    required this.sms,
    required this.type,
    required this.description,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operator': operator,
      'amount': amount,
      'validity': validity,
      'data': data,
      'calls': calls,
      'sms': sms,
      'type': type,
      'description': description,
    };
  }
  
  factory MobilePlan.fromMap(Map<String, dynamic> map) {
    return MobilePlan(
      id: map['id'] ?? '',
      operator: map['operator'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      validity: map['validity'] ?? '',
      data: map['data'] ?? '',
      calls: map['calls'] ?? '',
      sms: map['sms'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
    );
  }
} 