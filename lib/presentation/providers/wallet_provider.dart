import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../config/firebase_config.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/services/wallet_service.dart';

enum WalletState { loading, loaded, error }

class WalletProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final WalletRepository _walletRepository = WalletRepository();
  final WalletService _walletService = WalletService();
  
  // State variables
  WalletState _state = WalletState.loading;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  String _errorMessage = '';
  bool _isLoading = false;
  
  // Getters
  WalletState get state => _state;
  Wallet? get wallet => _wallet;
  double get balance => _wallet?.balance ?? 0.0;
  double get totalAdded => _wallet?.totalAdded ?? 0.0;
  double get totalSpent => _wallet?.totalSpent ?? 0.0;
  List<WalletTransaction> get transactions => _transactions;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  // Filtered transactions
  List<WalletTransaction> get recentTransactions => 
      _transactions.take(10).toList();
  
  List<WalletTransaction> get creditTransactions => 
      _transactions.where((t) => t.type == WalletTransactionType.credit).toList();
  
  List<WalletTransaction> get debitTransactions => 
      _transactions.where((t) => t.type == WalletTransactionType.debit).toList();
  
  List<WalletTransaction> get pendingTransactions => 
      _transactions.where((t) => t.status == WalletTransactionStatus.pending).toList();
  
  WalletProvider() {
    _initializeWallet();
  }
  
  /// Initialize wallet data
  void _initializeWallet() {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      loadWalletData(currentUser.uid);
    }
  }

  /// Load wallet data for a specific user
  Future<void> loadWalletData(String userId) async {
    try {
      _setState(WalletState.loading);
      _clearError();
      
      _logger.i('Loading wallet data for user: $userId');
      
      // Load wallet
      _wallet = await _walletRepository.getWallet(userId);
      _logger.i('Wallet loaded: balance=₹${_wallet?.balance ?? 0.0}');
      
      // Load transaction history
      await _loadTransactionHistory(userId);
      
      _setState(WalletState.loaded);
      
    } catch (e) {
      _logger.e('Failed to load wallet data: $e');
      _setError('Failed to load wallet data: $e');
      _setState(WalletState.error);
    }
  }

  /// Refresh wallet data for current user
  Future<void> refresh() async {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      await loadWalletData(currentUser.uid);
    }
  }
  
  /// Load transaction history
  Future<void> _loadTransactionHistory(String userId, {int limit = 50}) async {
    try {
      _transactions = await _walletRepository.getTransactions(userId, limit: limit);
      _logger.i('Loaded ${_transactions.length} transactions');
    } catch (e) {
      _logger.e('Failed to load transaction history: $e');
      // Don't throw here, wallet balance is more important
    }
  }
  
  /// Add money to wallet (admin/manual operation)
  Future<bool> addMoney({
    required double amount,
    required String purpose,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      _logger.i('Adding ₹$amount to wallet: $purpose');
      
      await _walletService.addMoneyToWallet(
        userId: currentUser.uid,
        amount: amount,
        purpose: purpose,
        adminId: adminId,
        metadata: metadata,
      );
      
      // Refresh wallet data after successful addition
      await loadWalletData(currentUser.uid);
      _logger.i('Money added successfully');
      return true;
      
    } catch (e) {
      _logger.e('Error adding money: $e');
      _setError('Failed to add money: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Debit money from wallet
  Future<bool> debitMoney({
    required double amount,
    required String purpose,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      _logger.i('Debiting ₹$amount from wallet for: $purpose');
      
      final success = await _walletRepository.debitWallet(
        userId: currentUser.uid,
        amount: amount,
        purpose: purpose,
        transactionId: transactionId,
        metadata: metadata,
      );
      
      if (success) {
        // Refresh wallet data after successful debit
        await loadWalletData(currentUser.uid);
        _logger.i('Wallet debited successfully');
      } else {
        _setError('Insufficient balance');
      }
      
      return success;
      
    } catch (e) {
      _logger.e('Error debiting wallet: $e');
      _setError('Failed to debit wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Refund money to wallet
  Future<bool> refundMoney({
    required double amount,
    required String reason,
    required String originalTransactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      _logger.i('Refunding ₹$amount to wallet: $reason');
      
      await _walletService.refundToUserWallet(
        userId: currentUser.uid,
        originalTransactionId: originalTransactionId,
        amount: amount,
        reason: reason,
        metadata: metadata,
      );
      
      // Refresh wallet data after successful refund
      await loadWalletData(currentUser.uid);
      _logger.i('Refund processed successfully');
      return true;
      
    } catch (e) {
      _logger.e('Error processing refund: $e');
      _setError('Failed to process refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Check if wallet has sufficient balance
  bool hasSufficientBalance(double amount) {
    return (_wallet?.balance ?? 0.0) >= amount;
  }
  
  /// Get wallet balance
  double getBalance() {
    return _wallet?.balance ?? 0.0;
  }
  
  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats() async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) return {};
      
      return await _walletService.getWalletStats(currentUser.uid);
    } catch (e) {
      _logger.e('Error getting wallet stats: $e');
      return {};
    }
  }
  
  /// Stream wallet changes
  Stream<Wallet?> watchWallet(String userId) {
    return _walletRepository.walletStream(userId);
  }
  
  /// Stream wallet transactions
  Stream<List<WalletTransaction>> watchTransactions(String userId, {int limit = 50}) {
    return _walletRepository.transactionsStream(userId, limit: limit);
  }
  
  /// Get transaction by ID
  WalletTransaction? getTransactionById(String transactionId) {
    try {
      return _transactions.firstWhere(
        (transaction) => transaction.transactionId == transactionId,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get transactions by type
  List<WalletTransaction> getTransactionsByType(WalletTransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }
  
  /// Get transactions by status
  List<WalletTransaction> getTransactionsByStatus(WalletTransactionStatus status) {
    return _transactions.where((t) => t.status == status).toList();
  }
  
  /// Initialize wallet for new user
  Future<void> initializeWallet(String userId, {double initialBalance = 0.0}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _walletService.initializeUserWallet(userId, initialBalance: initialBalance);
      await loadWalletData(userId);
      
    } catch (e) {
      _logger.e('Error initializing wallet: $e');
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Process transaction (debit for recharge/payment)
  Future<bool> processTransaction({
    required double amount,
    required String purpose,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      // Check if transaction can be processed
      final canProcess = await _walletService.canProcessTransaction(currentUser.uid, amount);
      if (!canProcess) {
        _setError('Insufficient balance for transaction');
        return false;
      }
      
      return await debitMoney(
        amount: amount,
        purpose: purpose,
        transactionId: transactionId,
        metadata: metadata,
      );
      
    } catch (e) {
      _logger.e('Error processing transaction: $e');
      _setError('Failed to process transaction: $e');
      return false;
    }
  }
  
  /// Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required WalletTransactionStatus status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _walletService.updateTransactionStatus(
        transactionId: transactionId,
        status: status,
        metadata: metadata,
      );
      
      // Refresh transactions
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser != null) {
        await _loadTransactionHistory(currentUser.uid);
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error updating transaction status: $e');
    }
  }
  
  /// Private helper methods
  void _setState(WalletState state) {
    _state = state;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _walletRepository.dispose();
    _walletService.dispose();
    super.dispose();
  }
} 