import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Firebase-only wallet repository
class WalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get wallet for a user
  Future<Wallet?> getWallet(String userId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(userId).get();
      if (doc.exists) {
        return Wallet.fromFirestore(doc);
      } else {
        // Create wallet if it doesn't exist
        return await createWallet(userId);
      }
    } catch (e) {
      _logger.e('Error getting wallet: $e');
      return null;
    }
  }

  /// Create a new wallet for user
  Future<Wallet> createWallet(String userId) async {
    try {
      final now = DateTime.now();
      final wallet = Wallet(
        id: userId,
        userId: userId,
        balance: 0.0,
        totalAdded: 0.0,
        totalSpent: 0.0,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        metadata: {},
      );

      await _firestore.collection('wallets').doc(userId).set(wallet.toFirestore());
      _logger.i('Created new wallet for user: $userId');
      return wallet;
    } catch (e) {
      _logger.e('Error creating wallet: $e');
      throw Exception('Failed to create wallet');
    }
  }

  /// Stream wallet changes
  Stream<Wallet?> walletStream(String userId) {
    return _firestore
        .collection('wallets')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? Wallet.fromFirestore(doc) : null);
  }

  /// Get wallet balance
  Future<double> getBalance(String userId) async {
    try {
      final wallet = await getWallet(userId);
      return wallet?.balance ?? 0.0;
    } catch (e) {
      _logger.e('Error getting balance: $e');
      return 0.0;
    }
  }

  /// Add money to wallet (Firebase-only, for admin/manual operations)
  Future<bool> addMoney({
    required String userId,
    required double amount,
    required String description,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) {
      _logger.w('Invalid amount: $amount');
      return false;
    }

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        // Get current wallet
        final walletDoc = await transaction.get(
          _firestore.collection('wallets').doc(userId),
        );

        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final wallet = Wallet.fromFirestore(walletDoc);
        final newBalance = wallet.balance + amount;
        final newTotalAdded = wallet.totalAdded + amount;

        // Update wallet
        transaction.update(
          _firestore.collection('wallets').doc(userId),
          {
            'balance': newBalance,
            'totalAdded': newTotalAdded,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Create transaction record
        final transactionId = _generateTransactionId();
        final walletTransaction = WalletTransaction(
          id: transactionId,
          transactionId: transactionId,
          userId: userId,
          amount: amount,
          type: WalletTransactionType.credit,
          status: WalletTransactionStatus.success,
          description: description,
          timestamp: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          balanceAfter: newBalance,
          balanceBefore: wallet.balance,
          metadata: {
            'adminId': adminId,
            'operation': 'add_money',
            ...?metadata,
          },
        );

        transaction.set(
          _firestore.collection('wallet_transactions').doc(transactionId),
          walletTransaction.toFirestore(),
        );

        return true;
      });

      _logger.i('Added ₹$amount to wallet for user: $userId');
      return result;
    } catch (e) {
      _logger.e('Error adding money: $e');
      return false;
    }
  }

  /// Debit money from wallet
  Future<bool> debitWallet({
    required String userId,
    required double amount,
    required String purpose,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) {
      _logger.w('Invalid amount: $amount');
      return false;
    }

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        // Get current wallet
        final walletDoc = await transaction.get(
          _firestore.collection('wallets').doc(userId),
        );

        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final wallet = Wallet.fromFirestore(walletDoc);
        
        // Check sufficient balance
        if (wallet.balance < amount) {
          _logger.w('Insufficient balance. Required: ₹$amount, Available: ₹${wallet.balance}');
          return false;
        }

        final newBalance = wallet.balance - amount;
        final newTotalSpent = wallet.totalSpent + amount;

        // Update wallet
        transaction.update(
          _firestore.collection('wallets').doc(userId),
          {
            'balance': newBalance,
            'totalSpent': newTotalSpent,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Create transaction record
        final walletTransaction = WalletTransaction(
          id: transactionId,
          transactionId: transactionId,
          userId: userId,
          amount: amount,
          type: WalletTransactionType.debit,
          status: WalletTransactionStatus.success,
          description: purpose,
          timestamp: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          balanceAfter: newBalance,
          balanceBefore: wallet.balance,
          metadata: {
            'operation': 'debit_wallet',
            ...?metadata,
          },
        );

        transaction.set(
          _firestore.collection('wallet_transactions').doc(transactionId),
          walletTransaction.toFirestore(),
        );

        return true;
      });

      _logger.i('Debited ₹$amount from wallet for user: $userId');
      return result;
    } catch (e) {
      _logger.e('Error debiting wallet: $e');
      return false;
    }
  }

  /// Refund money to wallet
  Future<bool> refundWallet({
    required String userId,
    required double amount,
    required String reason,
    required String originalTransactionId,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) {
      _logger.w('Invalid refund amount: $amount');
      return false;
    }

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        // Get current wallet
        final walletDoc = await transaction.get(
          _firestore.collection('wallets').doc(userId),
        );

        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final wallet = Wallet.fromFirestore(walletDoc);
        final newBalance = wallet.balance + amount;

        // Update wallet
        transaction.update(
          _firestore.collection('wallets').doc(userId),
          {
            'balance': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Create refund transaction record
        final refundTransactionId = _generateTransactionId();
        final walletTransaction = WalletTransaction(
          id: refundTransactionId,
          transactionId: refundTransactionId,
          userId: userId,
          amount: amount,
          type: WalletTransactionType.refund,
          status: WalletTransactionStatus.success,
          description: 'Refund: $reason',
          timestamp: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          balanceAfter: newBalance,
          balanceBefore: wallet.balance,
          reference: originalTransactionId,
          metadata: {
            'operation': 'refund_wallet',
            'original_transaction': originalTransactionId,
            'refund_reason': reason,
            ...?metadata,
          },
        );

        transaction.set(
          _firestore.collection('wallet_transactions').doc(refundTransactionId),
          walletTransaction.toFirestore(),
        );

        return true;
      });

      _logger.i('Refunded ₹$amount to wallet for user: $userId');
      return result;
    } catch (e) {
      _logger.e('Error refunding wallet: $e');
      return false;
    }
  }

  /// Get wallet transactions
  Future<List<WalletTransaction>> getTransactions(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting transactions: $e');
      return [];
    }
  }

  /// Stream wallet transactions
  Stream<List<WalletTransaction>> transactionsStream(String userId, {int limit = 50}) {
    return _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction by ID
  Future<WalletTransaction?> getTransactionById(String transactionId) async {
    try {
      final doc = await _firestore
          .collection('wallet_transactions')
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return WalletTransaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting transaction: $e');
      return null;
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(String userId, double amount) async {
    try {
      final balance = await getBalance(userId);
      return balance >= amount;
    } catch (e) {
      _logger.e('Error checking balance: $e');
      return false;
    }
  }

  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) return {};

      final transactions = await getTransactions(userId);
      final creditTransactions = transactions.where((t) => t.type == WalletTransactionType.credit).length;
      final debitTransactions = transactions.where((t) => t.type == WalletTransactionType.debit).length;

      return {
        'balance': wallet.balance,
        'totalAdded': wallet.totalAdded,
        'totalSpent': wallet.totalSpent,
        'transactionCount': transactions.length,
        'creditTransactions': creditTransactions,
        'debitTransactions': debitTransactions,
        'createdAt': wallet.createdAt.toIso8601String(),
        'updatedAt': wallet.updatedAt.toIso8601String(),
      };
    } catch (e) {
      _logger.e('Error getting wallet stats: $e');
      return {};
    }
  }

  /// Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'TXN_${timestamp}_$random';
  }

  /// Initialize wallet for new user
  Future<Wallet?> initializeWallet(String userId) async {
    try {
      return await createWallet(userId);
    } catch (e) {
      _logger.e('Error initializing wallet: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _logger.i('Disposing WalletRepository');
  }
} 