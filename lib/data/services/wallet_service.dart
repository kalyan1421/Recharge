import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../repositories/wallet_repository.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Firebase-only wallet service
class WalletService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final WalletRepository _walletRepository;
  final Logger _logger = Logger();
  
  WalletService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    WalletRepository? walletRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _walletRepository = walletRepository ?? WalletRepository();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get user wallet balance from Firebase
  Future<double> getUserWalletBalance(String userId) async {
    try {
      _logger.i('Getting user wallet balance for userId: $userId');
      
      final wallet = await _walletRepository.getWallet(userId);
      if (wallet != null) {
        _logger.i('User wallet balance retrieved: ₹${wallet.balance}');
        return wallet.balance;
      } else {
        _logger.w('Wallet not found for userId: $userId, creating new wallet');
        await _walletRepository.createWallet(userId);
        return 0.0;
      }
    } catch (e) {
      _logger.e('Error getting user wallet balance: $e');
      throw WalletServiceException('Failed to get wallet balance', operation: 'getUserWalletBalance');
    }
  }

  /// Check if user can process transaction
  Future<bool> canProcessTransaction(String userId, double amount) async {
    try {
      _logger.i('Checking if user can process transaction: userId=$userId, amount=₹$amount');
      
      final balance = await getUserWalletBalance(userId);
      final canProcess = balance >= amount;
      
      _logger.i('Transaction check result: canProcess=$canProcess, balance=₹$balance');
      return canProcess;
    } catch (e) {
      _logger.e('Error checking transaction capability: $e');
      return false;
    }
  }

  /// Process wallet deduction for recharge/payment
  Future<WalletDeductionResult> processWalletDeduction({
    required String userId,
    required double amount,
    required String purpose,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    _logger.i('Processing wallet deduction: userId=$userId, amount=₹$amount, purpose=$purpose');
    
    try {
      final success = await _walletRepository.debitWallet(
        userId: userId,
        amount: amount,
        purpose: purpose,
        transactionId: transactionId,
        metadata: metadata,
      );

      if (success) {
        // Get updated wallet balance
        final newBalance = await getUserWalletBalance(userId);
        
        return WalletDeductionResult(
          success: true,
          transactionId: transactionId,
          previousBalance: newBalance + amount,
          newBalance: newBalance,
          deductedAmount: amount,
          timestamp: DateTime.now(),
        );
      } else {
        throw InsufficientBalanceException(
          message: 'Insufficient balance for transaction',
          availableBalance: await getUserWalletBalance(userId),
          requiredAmount: amount,
        );
      }
    } catch (e) {
      _logger.e('Error processing wallet deduction: $e');
      if (e is InsufficientBalanceException) {
        rethrow;
      }
      throw WalletServiceException('Failed to process wallet deduction: ${e.toString()}', operation: 'processWalletDeduction');
    }
  }

  /// Refund money to user wallet
  Future<void> refundToUserWallet({
    required String userId,
    required String originalTransactionId,
    required double amount,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    _logger.i('Processing refund: userId=$userId, amount=₹$amount, reason=$reason');
    
    try {
      final success = await _walletRepository.refundWallet(
        userId: userId,
        amount: amount,
        reason: reason,
        originalTransactionId: originalTransactionId,
        metadata: metadata,
      );

      if (success) {
        _logger.i('Refund processed successfully: amount=₹$amount');
      } else {
        throw WalletServiceException('Failed to process refund', operation: 'refundToUserWallet');
      }
    } catch (e) {
      _logger.e('Error processing refund: $e');
      throw WalletServiceException('Failed to process refund: ${e.toString()}', operation: 'refundToUserWallet');
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required WalletTransactionStatus status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.i('Updating transaction status: transactionId=$transactionId, status=$status');
      
      await _firestore
          .collection('wallet_transactions')
          .doc(transactionId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': FieldValue.arrayUnion([metadata]),
      });
      
      _logger.i('Transaction status updated successfully');
    } catch (e) {
      _logger.e('Error updating transaction status: $e');
      throw WalletServiceException('Failed to update transaction status', operation: 'updateTransactionStatus');
    }
  }

  /// Get transaction history for user
  Future<List<WalletTransaction>> getTransactionHistory(String userId, {int limit = 50}) async {
    try {
      _logger.i('Getting transaction history for userId: $userId');
      
      final transactions = await _walletRepository.getTransactions(userId, limit: limit);
      
      _logger.i('Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      throw WalletServiceException('Failed to get transaction history', operation: 'getTransactionHistory');
    }
  }

  /// Add money to user wallet (admin/manual operation)
  Future<void> addMoneyToWallet({
    required String userId,
    required double amount,
    required String purpose,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.i('Adding money to wallet: userId=$userId, amount=₹$amount, purpose=$purpose');
      
      final success = await _walletRepository.addMoney(
        userId: userId,
        amount: amount,
        description: purpose,
        adminId: adminId,
        metadata: metadata,
      );

      if (success) {
        _logger.i('Money added to wallet successfully: amount=₹$amount');
      } else {
        throw WalletServiceException('Failed to add money to wallet', operation: 'addMoneyToWallet');
      }
    } catch (e) {
      _logger.e('Error adding money to wallet: $e');
      throw WalletServiceException('Failed to add money to wallet: ${e.toString()}', operation: 'addMoneyToWallet');
    }
  }

  /// Initialize user wallet
  Future<void> initializeUserWallet(String userId, {double initialBalance = 0.0}) async {
    try {
      _logger.i('Initializing wallet for userId: $userId');
      
      final wallet = await _walletRepository.initializeWallet(userId);
      
      if (wallet != null && initialBalance > 0) {
        await addMoneyToWallet(
          userId: userId,
          amount: initialBalance,
          purpose: 'Initial wallet setup',
          adminId: 'system',
        );
      }
      
      _logger.i('Wallet initialized successfully with balance: ₹$initialBalance');
    } catch (e) {
      _logger.e('Error initializing wallet: $e');
      throw WalletServiceException('Failed to initialize wallet', operation: 'initializeUserWallet');
    }
  }

  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      return await _walletRepository.getWalletStats(userId);
    } catch (e) {
      _logger.e('Error getting wallet stats: $e');
      return {};
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(String userId, double amount) async {
    try {
      return await _walletRepository.hasSufficientBalance(userId, amount);
    } catch (e) {
      _logger.e('Error checking balance: $e');
      return false;
    }
  }

  /// Get wallet stream
  Stream<Wallet?> getWalletStream(String userId) {
    return _walletRepository.walletStream(userId);
  }

  /// Get transactions stream
  Stream<List<WalletTransaction>> getTransactionsStream(String userId, {int limit = 50}) {
    return _walletRepository.transactionsStream(userId, limit: limit);
  }

  /// Dispose resources
  void dispose() {
    _walletRepository.dispose();
  }
}

/// Wallet deduction result
class WalletDeductionResult {
  final bool success;
  final String transactionId;
  final double previousBalance;
  final double newBalance;
  final double deductedAmount;
  final DateTime timestamp;
  
  WalletDeductionResult({
    required this.success,
    required this.transactionId,
    required this.previousBalance,
    required this.newBalance,
    required this.deductedAmount,
    required this.timestamp,
  });
}

/// Custom exceptions for wallet operations
class WalletServiceException implements Exception {
  final String message;
  final String operation;
  
  WalletServiceException(this.message, {required this.operation});
  
  @override
  String toString() => 'WalletServiceException($operation): $message';
}

class InsufficientBalanceException implements Exception {
  final String message;
  final double availableBalance;
  final double requiredAmount;
  
  InsufficientBalanceException({
    required this.message,
    required this.availableBalance,
    required this.requiredAmount,
  });
  
  @override
  String toString() => 'InsufficientBalanceException: $message (Available: ₹$availableBalance, Required: ₹$requiredAmount)';
} 