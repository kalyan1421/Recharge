import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/wallet_models.dart';
import '../models/recharge_models.dart' as recharge_models;

class WalletService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();
  
  WalletService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user wallet balance from Firestore
  Future<double> getUserWalletBalance(String userId) async {
    try {
      _logger.i('Getting user wallet balance for userId: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final balance = (data?['walletBalance'] ?? 0.0).toDouble();
        
        _logger.i('User wallet balance retrieved: ₹$balance');
        return balance;
      } else {
        _logger.w('User document not found for userId: $userId, initializing wallet');
        
        // Initialize user wallet with 0.0 balance
        await initializeUserWallet(userId, initialBalance: 0.0);
        
        _logger.i('User wallet initialized with balance: ₹0.0');
        return 0.0;
      }
    } catch (e) {
      _logger.e('Error getting user wallet balance: $e');
      throw WalletServiceException('Failed to get wallet balance', operation: 'getUserWalletBalance');
    }
  }

  /// Check if user can process recharge (only user wallet balance)
  Future<bool> canProcessRecharge(String userId, double amount) async {
    try {
      _logger.i('Checking if user can process recharge: userId=$userId, amount=₹$amount');
      
      // Check user wallet balance
      final userBalance = await getUserWalletBalance(userId);
      if (userBalance < amount) {
        _logger.w('User wallet insufficient: available=₹$userBalance, required=₹$amount');
        return false;
      }
      
      _logger.i('Recharge can be processed: user=₹$userBalance, required=₹$amount');
      return true;
    } catch (e) {
      _logger.e('Error checking recharge capability: $e');
      return false;
    }
  }

  /// Complete wallet deduction flow for recharge
  Future<WalletDeductionResult> processWalletDeduction({
    required String userId,
    required double amount,
    required String purpose,
    required String transactionId,
  }) async {
    _logger.i('Processing wallet deduction: userId=$userId, amount=₹$amount, purpose=$purpose');
    
    try {
      // Start Firestore transaction for atomic operations
      return await _firestore.runTransaction((transaction) async {
        // Step 1: Get user document
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);
        
        if (!userDoc.exists) {
          throw WalletServiceException('User not found', operation: 'processWalletDeduction');
        }
        
        final userData = userDoc.data()!;
        final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
        
        _logger.i('Current user balance: ₹$currentBalance');
        
        // Step 2: Check user wallet balance
        if (currentBalance < amount) {
          throw InsufficientBalanceException(
            message: 'Insufficient balance. Available: ₹$currentBalance, Required: ₹$amount',
            availableBalance: currentBalance,
            requiredAmount: amount,
          );
        }
        
        // Step 3: Create transaction record
        final transactionDocRef = _firestore.collection('transactions').doc(transactionId);
        final now = DateTime.now();
        final transactionData = {
          'transactionId': transactionId,
          'userId': userId,
          'amount': amount,
          'type': 'debit',
          'purpose': purpose,
          'status': 'pending',
          'balanceBefore': currentBalance,
          'balanceAfter': currentBalance - amount,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };
        
        // Step 4: Update user balance (deduct amount)
        transaction.update(userDocRef, {
          'walletBalance': currentBalance - amount,
          'updatedAt': Timestamp.fromDate(now),
        });
        
        // Step 5: Create transaction record
        transaction.set(transactionDocRef, transactionData);
        
        _logger.i('Wallet deduction successful: deducted=₹$amount, newBalance=₹${currentBalance - amount}');
        
        return WalletDeductionResult(
          success: true,
          transactionId: transactionId,
          previousBalance: currentBalance,
          newBalance: currentBalance - amount,
          deductedAmount: amount,
          timestamp: now,
        );
      });
    } catch (e) {
      _logger.e('Error in wallet deduction: $e');
      
      if (e is InsufficientBalanceException) {
        rethrow; // Re-throw specific wallet exceptions
      }
      
      throw WalletServiceException('Failed to process wallet deduction: ${e.toString()}', operation: 'processWalletDeduction');
    }
  }

  /// Refund amount back to user wallet (in case of failed recharge)
  Future<void> refundToUserWallet({
    required String userId,
    required String originalTransactionId,
    required double amount,
    required String reason,
  }) async {
    _logger.i('Processing refund: userId=$userId, amount=₹$amount, reason=$reason');
    
    try {
      await _firestore.runTransaction((transaction) async {
        // Get user document
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);
        
        if (!userDoc.exists) {
          throw WalletServiceException('User not found for refund', operation: 'refundToUserWallet');
        }
        
        final currentBalance = (userDoc.data()!['walletBalance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;
        
        _logger.i('Processing refund: currentBalance=₹$currentBalance, refundAmount=₹$amount, newBalance=₹$newBalance');
        
        // Update user balance (add refund amount)
        transaction.update(userDocRef, {
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Create refund transaction record
        final refundTransactionId = 'REFUND_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        final refundDocRef = _firestore.collection('transactions').doc(refundTransactionId);
        
        transaction.set(refundDocRef, {
          'transactionId': refundTransactionId,
          'originalTransactionId': originalTransactionId,
          'userId': userId,
          'amount': amount,
          'type': 'credit',
          'purpose': 'Refund: $reason',
          'status': 'completed',
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update original transaction status to failed
        final originalTransactionRef = _firestore.collection('transactions').doc(originalTransactionId);
        transaction.update(originalTransactionRef, {
          'status': 'failed',
          'refundTransactionId': refundTransactionId,
          'refundReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      _logger.i('Refund processed successfully: amount=₹$amount, refundId=REFUND_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      _logger.e('Error processing refund: $e');
      throw WalletServiceException('Failed to process refund: ${e.toString()}', operation: 'refundToUserWallet');
    }
  }

  /// Update transaction status (called after recharge attempt)
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    Map<String, dynamic>? rechargeResponse,
    String? operatorTransactionId,
  }) async {
    try {
      _logger.i('Updating transaction status: transactionId=$transactionId, status=$status');
      
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (rechargeResponse != null) {
        updateData['rechargeResponse'] = rechargeResponse;
      }
      
      if (operatorTransactionId != null) {
        updateData['operatorTransactionId'] = operatorTransactionId;
      }
      
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);
      
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
      
      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final transactions = query.docs.map((doc) {
        final data = doc.data();
        return WalletTransaction(
          transactionId: data['transactionId'] ?? '',
          userId: data['userId'] ?? '',
          amount: (data['amount'] ?? 0.0).toDouble(),
          type: data['type'] ?? '',
          purpose: data['purpose'] ?? '',
          status: data['status'] ?? '',
          balanceBefore: (data['balanceBefore'] ?? 0.0).toDouble(),
          balanceAfter: (data['balanceAfter'] ?? 0.0).toDouble(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          originalTransactionId: data['originalTransactionId'],
          rechargeResponse: data['rechargeResponse'],
        );
      }).toList();
      
      _logger.i('Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      throw WalletServiceException('Failed to get transaction history', operation: 'getTransactionHistory');
    }
  }

  /// Add money to user wallet (for testing or admin purposes)
  Future<void> addMoneyToWallet({
    required String userId,
    required double amount,
    required String purpose,
    String? adminId,
  }) async {
    try {
      _logger.i('Adding money to wallet: userId=$userId, amount=₹$amount, purpose=$purpose');
      
      await _firestore.runTransaction((transaction) async {
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);
        
        if (!userDoc.exists) {
          throw WalletServiceException('User not found', operation: 'addMoneyToWallet');
        }
        
        final currentBalance = (userDoc.data()!['walletBalance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;
        
        // Update user balance
        transaction.update(userDocRef, {
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Create credit transaction record
        final transactionId = 'ADD_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        final transactionDocRef = _firestore.collection('transactions').doc(transactionId);
        
        transaction.set(transactionDocRef, {
          'transactionId': transactionId,
          'userId': userId,
          'amount': amount,
          'type': 'credit',
          'purpose': purpose,
          'status': 'completed',
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'adminId': adminId,
        });
      });
      
      _logger.i('Money added to wallet successfully: amount=₹$amount');
    } catch (e) {
      _logger.e('Error adding money to wallet: $e');
      throw WalletServiceException('Failed to add money to wallet', operation: 'addMoneyToWallet');
    }
  }

  /// Initialize user wallet (create wallet balance field if not exists)
  Future<void> initializeUserWallet(String userId, {double initialBalance = 0.0}) async {
    try {
      _logger.i('Initializing wallet for userId: $userId');
      
      final userDocRef = _firestore.collection('users').doc(userId);
      
      await userDocRef.set({
        'walletBalance': initialBalance,
        'walletCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _logger.i('Wallet initialized successfully with balance: ₹$initialBalance');
    } catch (e) {
      _logger.e('Error initializing wallet: $e');
      throw WalletServiceException('Failed to initialize wallet', operation: 'initializeUserWallet');
    }
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose as RoboticsExchangeService is removed
  }
} 