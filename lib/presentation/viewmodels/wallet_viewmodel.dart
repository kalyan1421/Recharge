import 'package:flutter/material.dart';
import '../../data/repositories/wallet_repository_mock.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

enum WalletState { initial, loading, loaded, error }

class WalletViewModel extends ChangeNotifier {
  final WalletRepositoryMock _walletRepository = WalletRepositoryMock();
  
  WalletState _state = WalletState.initial;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  String? _errorMessage;
  
  // Getters
  WalletState get state => _state;
  Wallet? get wallet => _wallet;
  List<WalletTransaction> get transactions => _transactions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == WalletState.loading;

  // Load wallet data
  Future<void> loadWallet(String walletId) async {
    _setState(WalletState.loading);
    
    try {
      _wallet = await _walletRepository.getWallet(walletId);
      if (_wallet != null) {
        await _loadTransactions(walletId);
        _setState(WalletState.loaded);
      } else {
        _setError('Wallet not found');
      }
    } catch (e) {
      _setError('Failed to load wallet: $e');
    }
  }

  // Stream wallet changes
  void subscribeToWallet(String walletId) {
    _walletRepository.walletStream(walletId).listen(
      (wallet) {
        _wallet = wallet;
        notifyListeners();
      },
      onError: (error) {
        _setError('Wallet stream error: $error');
      },
    );
  }

  // Add money to wallet
  Future<void> addMoney({
    required String walletId,
    required double amount,
    required PaymentMethod method,
    required String userId,
  }) async {
    _setState(WalletState.loading);

    final success = await _walletRepository.addMoney(
      walletId,
      amount,
      'Money added via ${method.toString().split('.').last}',
    );
    
    if (success) {
      await loadWallet(walletId);
      _showSuccess('Money added successfully');
    } else {
      _setError('Failed to add money');
    }
  }

  // Check if sufficient balance for transaction
  bool hasSufficientBalance(double amount) {
    if (_wallet == null) return false;
    return (_wallet!.balance - _wallet!.blockedAmount) >= amount;
  }

  // Get available balance
  double get availableBalance {
    if (_wallet == null) return 0.0;
    return _wallet!.balance - _wallet!.blockedAmount;
  }

  // Check daily limit
  bool canTransact(double amount) {
    if (_wallet == null) return false;
    return (_wallet!.dailyUsed + amount) <= _wallet!.dailyLimit;
  }

  // Check monthly limit
  bool withinMonthlyLimit(double amount) {
    if (_wallet == null) return false;
    return (_wallet!.monthlyUsed + amount) <= _wallet!.monthlyLimit;
  }

  // Get remaining daily limit
  double get remainingDailyLimit {
    if (_wallet == null) return 0.0;
    return _wallet!.dailyLimit - _wallet!.dailyUsed;
  }

  // Get remaining monthly limit
  double get remainingMonthlyLimit {
    if (_wallet == null) return 0.0;
    return _wallet!.monthlyLimit - _wallet!.monthlyUsed;
  }

  // Load transaction history
  Future<void> _loadTransactions(String walletId) async {
    try {
      _transactions = await _walletRepository.getTransactionHistory(walletId);
    } catch (e) {
      print('Failed to load transactions: $e');
    }
  }

  // Refresh transactions
  Future<void> refreshTransactions(String walletId) async {
    await _loadTransactions(walletId);
    notifyListeners();
  }

  // Get transaction by ID
  WalletTransaction? getTransaction(String transactionId) {
    try {
      return _transactions.firstWhere((t) => t.transactionId == transactionId);
    } catch (e) {
      return null;
    }
  }

  // Filter transactions by type
  List<WalletTransaction> getTransactionsByType(WalletTransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Get transactions for date range
  List<WalletTransaction> getTransactionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions.where((t) {
      return t.timestamp.isAfter(startDate) && t.timestamp.isBefore(endDate);
    }).toList();
  }

  // Calculate total amount for transaction type
  double getTotalAmount(WalletTransactionType type) {
    return _transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get wallet health score (0-100)
  int getWalletHealthScore() {
    if (_wallet == null) return 0;
    
    int score = 100;
    
    // Deduct points for low balance
    if (_wallet!.balance < _wallet!.minBalance + 100) {
      score -= 20;
    }
    
    // Deduct points for high utilization
    double dailyUtilization = _wallet!.dailyUsed / _wallet!.dailyLimit;
    if (dailyUtilization > 0.8) {
      score -= 15;
    }
    
    double monthlyUtilization = _wallet!.monthlyUsed / _wallet!.monthlyLimit;
    if (monthlyUtilization > 0.8) {
      score -= 15;
    }
    
    // Add points for regular usage
    if (_transactions.length > 10) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }

  // Get spending insights
  Map<String, dynamic> getSpendingInsights() {
    if (_transactions.isEmpty) {
      return {
        'totalSpent': 0.0,
        'averageTransaction': 0.0,
        'topCategory': 'No transactions',
        'monthlyTrend': 'No data',
      };
    }

    final debitTransactions = getTransactionsByType(WalletTransactionType.debit);
    final totalSpent = debitTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final averageTransaction = totalSpent / debitTransactions.length;

    return {
      'totalSpent': totalSpent,
      'averageTransaction': averageTransaction,
      'topCategory': 'Recharge',
      'monthlyTrend': 'Stable',
      'transactionCount': debitTransactions.length,
    };
  }

  // Predict next recharge
  Map<String, dynamic> getPredictiveInsights() {
    if (_transactions.length < 3) {
      return {
        'nextRechargeDate': 'Not enough data',
        'recommendedAmount': 0.0,
        'confidence': 'Low',
      };
    }

    // Simple prediction based on recent transactions
    final recentTransactions = _transactions
        .where((t) => t.type == WalletTransactionType.debit)
        .take(7)
        .toList();

    final averageDailySpend = recentTransactions.fold(0.0, (sum, t) => sum + t.amount) / 7;

    return {
      'nextRechargeDate': DateTime.now().add(const Duration(days: 3)).toString().split(' ')[0],
      'recommendedAmount': (averageDailySpend * 10).roundToDouble(),
      'confidence': 'Medium',
    };
  }

  // Helper methods
  void _setState(WalletState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = WalletState.error;
    _errorMessage = error;
    notifyListeners();
  }

  void _showSuccess(String message) {
    // Handle success message
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == WalletState.error) {
      _state = WalletState.initial;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 