import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../config/firebase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

enum WalletState { loading, loaded, error }

class WalletProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  
  // State variables
  WalletState _state = WalletState.loading;
  double _balance = 0.0;
  double _outstandingBalance = 0.0;
  List<WalletTransaction> _transactions = [];
  String _errorMessage = '';
  bool _isLoading = false;
  
  // Getters
  WalletState get state => _state;
  double get balance => _balance;
  double get outstandingBalance => _outstandingBalance;
  List<WalletTransaction> get transactions => _transactions;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  // Filtered transactions
  List<WalletTransaction> get recentTransactions => 
      _transactions.take(10).toList();
  
  List<WalletTransaction> get successfulTransactions => 
      _transactions.where((t) => t.status == AppConstants.statusSuccess).toList();
  
  List<WalletTransaction> get pendingTransactions => 
      _transactions.where((t) => t.status == AppConstants.statusPending).toList();
  
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
  
  /// Load wallet data for user
  Future<void> loadWalletData(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _logger.i('Loading wallet data for user: $userId');
      
      // Load wallet balance
      await _loadWalletBalance(userId);
      
      // Load transaction history
      await _loadTransactionHistory(userId);
      
      _state = WalletState.loaded;
      _logger.i('Wallet data loaded successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to load wallet data: $e');
      _setError('Failed to load wallet data');
      _state = WalletState.error;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load wallet balance from Firestore
  Future<void> _loadWalletBalance(String userId) async {
    try {
      final walletDoc = await FirebaseConfig.firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId)
          .get();
      
      if (walletDoc.exists) {
        final data = walletDoc.data()!;
        _balance = (data['balance'] ?? 0.0).toDouble();
        _outstandingBalance = (data['outstandingBalance'] ?? 0.0).toDouble();
      } else {
        // Create wallet document if it doesn't exist
        await _createWalletDocument(userId);
      }
      
      _logger.i('Wallet balance loaded: ₹$_balance');
      
    } catch (e) {
      _logger.e('Failed to load wallet balance: $e');
      throw Exception('Failed to load wallet balance');
    }
  }
  
  /// Create wallet document for new user
  Future<void> _createWalletDocument(String userId) async {
    try {
      final walletData = {
        'userId': userId,
        'balance': 0.0,
        'outstandingBalance': 0.0,
        'totalAddedMoney': 0.0,
        'totalSpentMoney': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseConfig.firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId)
          .set(walletData);
      
      _balance = 0.0;
      _outstandingBalance = 0.0;
      
      _logger.i('Wallet document created for user: $userId');
      
    } catch (e) {
      _logger.e('Failed to create wallet document: $e');
      throw Exception('Failed to create wallet');
    }
  }
  
  /// Load transaction history
  Future<void> _loadTransactionHistory(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await FirebaseConfig.firestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      _transactions = querySnapshot.docs.map((doc) {
        return WalletTransaction.fromFirestore(doc);
      }).toList();
      
      _logger.i('Loaded ${_transactions.length} transactions');
      
    } catch (e) {
      _logger.e('Failed to load transaction history: $e');
      // Don't throw here, wallet balance is more important
    }
  }
  
  /// Add money to wallet
  Future<bool> addMoney({
    required double amount,
    required String paymentMethod,
    String? paymentId,
    String? orderId,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Validate amount
      if (amount < AppConstants.minWalletAmount) {
        _setError('Minimum amount is ₹${AppConstants.minWalletAmount}');
        return false;
      }
      
      if (amount > AppConstants.maxWalletAmount) {
        _setError('Maximum amount is ₹${AppConstants.maxWalletAmount}');
        return false;
      }
      
      _logger.i('Adding ₹$amount to wallet');
      
      // Create transaction record
      final transactionData = {
        'userId': currentUser.uid,
        'type': AppConstants.transactionTypeAddMoney,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
        'orderId': orderId,
        'status': AppConstants.statusPending,
        'description': 'Money added to wallet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final transactionRef = await FirebaseConfig.firestore
          .collection(AppConstants.transactionsCollection)
          .add(transactionData);
      
      // For demo purposes, immediately update balance
      // In production, this would be done after payment verification
      await _updateWalletBalance(currentUser.uid, amount, isCredit: true);
      
      // Update transaction status
      await transactionRef.update({
        'status': AppConstants.statusSuccess,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload wallet data
      await loadWalletData(currentUser.uid);
      
      // Log analytics event
      FirebaseConfig.logEvent('add_money', {
        'amount': amount,
        'payment_method': paymentMethod,
        'user_id': currentUser.uid,
      });
      
      _logger.i('Money added successfully: ₹$amount');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to add money: $e');
      _setError('Failed to add money. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Deduct money from wallet
  Future<bool> deductMoney({
    required double amount,
    required String purpose,
    String? referenceId,
  }) async {
    try {
      final currentUser = FirebaseConfig.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Check sufficient balance
      if (_balance < amount) {
        _setError(AppConstants.errorInsufficientBalance);
        return false;
      }
      
      _logger.i('Deducting ₹$amount from wallet for: $purpose');
      
      // Create transaction record
      final transactionData = {
        'userId': currentUser.uid,
        'type': AppConstants.transactionTypeWithdraw,
        'amount': -amount,
        'purpose': purpose,
        'referenceId': referenceId,
        'status': AppConstants.statusSuccess,
        'description': purpose,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseConfig.firestore
          .collection(AppConstants.transactionsCollection)
          .add(transactionData);
      
      // Update wallet balance
      await _updateWalletBalance(currentUser.uid, amount, isCredit: false);
      
      // Reload wallet data
      await loadWalletData(currentUser.uid);
      
      _logger.i('Money deducted successfully: ₹$amount');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to deduct money: $e');
      _setError('Failed to deduct money');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update wallet balance in Firestore
  Future<void> _updateWalletBalance(String userId, double amount, {required bool isCredit}) async {
    try {
      final walletRef = FirebaseConfig.firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId);
      
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          throw Exception('Wallet document not found');
        }
        
        final currentBalance = (walletDoc.data()!['balance'] ?? 0.0).toDouble();
        final newBalance = isCredit ? currentBalance + amount : currentBalance - amount;
        
        if (!isCredit && newBalance < 0) {
          throw Exception('Insufficient balance');
        }
        
        transaction.update(walletRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Update local balance
      if (isCredit) {
        _balance += amount;
      } else {
        _balance -= amount;
      }
      
    } catch (e) {
      _logger.e('Failed to update wallet balance: $e');
      throw Exception('Failed to update wallet balance');
    }
  }
  
  /// Refresh wallet data
  Future<void> refresh() async {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      await loadWalletData(currentUser.uid);
    }
  }
  
  /// Get transactions by type
  List<WalletTransaction> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }
  
  /// Get transactions by date range
  List<WalletTransaction> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((t) {
      return t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate);
    }).toList();
  }
  
  /// Calculate total spent amount
  double get totalSpentAmount {
    return _transactions
        .where((t) => t.amount < 0 && t.status == AppConstants.statusSuccess)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }
  
  /// Calculate total added amount
  double get totalAddedAmount {
    return _transactions
        .where((t) => t.amount > 0 && t.status == AppConstants.statusSuccess)
        .fold(0.0, (sum, t) => sum + t.amount);
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