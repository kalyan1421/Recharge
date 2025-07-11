import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;

  // Mock implementation for demo
  static final Map<String, double> _walletBalances = {};
  static final Map<String, List<WalletTransaction>> _transactions = {};

  WalletRepository() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Get wallet details
  Future<Wallet?> getWallet(String walletId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(walletId).get();
      if (doc.exists) {
        return _walletFromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting wallet: $e');
    }
    return null;
  }

  // Stream wallet changes
  Stream<Wallet?> walletStream(String walletId) {
    return _firestore
        .collection('wallets')
        .doc(walletId)
        .snapshots()
        .map((doc) => doc.exists ? _walletFromMap(doc.data()!) : null);
  }

  // Add money to wallet
  Future<void> addMoney({
    required String walletId,
    required double amount,
    required PaymentMethod method,
    required String userId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Validate amount
      if (amount < 10 || amount > 50000) {
        onError('Amount should be between ₹10 and ₹50,000');
        return;
      }

      final transactionId = _generateTransactionId();

      switch (method) {
        case PaymentMethod.upi:
        case PaymentMethod.debit_card:
        case PaymentMethod.credit_card:
        case PaymentMethod.net_banking:
          await _processRazorpayPayment(
            amount: amount,
            userId: userId,
            walletId: walletId,
            transactionId: transactionId,
            onSuccess: onSuccess,
            onError: onError,
          );
          break;
        case PaymentMethod.wallet:
          onError('Cannot add money using wallet');
          break;
      }
    } catch (e) {
      onError('Failed to add money: $e');
    }
  }

  // Process Razorpay payment
  Future<void> _processRazorpayPayment({
    required double amount,
    required String userId,
    required String walletId,
    required String transactionId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    var options = {
      'key': 'rzp_test_your_key_here', // Replace with actual key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'SamyPay',
      'description': 'Add Money to Wallet',
      'order_id': transactionId,
      'prefill': {
        'contact': '', // User's mobile
        'email': '', // User's email
      },
      'theme': {
        'color': '#6A1B9A'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError('Payment failed: $e');
    }
  }

  // Debit from wallet
  Future<bool> debitWallet({
    required String walletId,
    required double amount,
    required String purpose,
    required String transactionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentBalance = _walletBalances[walletId] ?? 1000.0;
    if (currentBalance >= amount) {
      _walletBalances[walletId] = currentBalance - amount;
      
      // Add transaction record
      final transaction = WalletTransaction(
        transactionId: transactionId,
        walletId: walletId,
        amount: amount,
        type: WalletTransactionType.debit,
        description: purpose,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
      );
      
      _transactions.putIfAbsent(walletId, () => []).add(transaction);
      return true;
    }
    return false;
  }

  // Credit to wallet
  Future<void> creditWallet({
    required String walletId,
    required double amount,
    required WalletTransactionType type,
    required String description,
    required String transactionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentBalance = _walletBalances[walletId] ?? 1000.0;
    _walletBalances[walletId] = currentBalance + amount;
    
    // Add transaction record
    final transaction = WalletTransaction(
      transactionId: transactionId,
      walletId: walletId,
      amount: amount,
      type: type,
      description: description,
      timestamp: DateTime.now(),
      status: TransactionStatus.completed,
    );
    
    _transactions.putIfAbsent(walletId, () => []).add(transaction);
  }

  // Get wallet transactions
  Future<List<WalletTransaction>> getTransactionHistory(String walletId, {int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final history = _transactions[walletId] ?? [];
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history.take(limit).toList();
  }

  // Payment event handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment Success: ${response.paymentId}');
    // Handle successful payment
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    // Handle payment error
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    // Handle external wallet
  }

  // Helper methods
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}';
  }

  Wallet _walletFromMap(Map<String, dynamic> map) {
    return Wallet(
      walletId: map['walletId'] ?? '',
      userId: map['userId'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      blockedAmount: (map['blockedAmount'] ?? 0.0).toDouble(),
      minBalance: (map['minBalance'] ?? 0.0).toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: WalletStatus.values.firstWhere(
        (e) => e.toString() == 'WalletStatus.${map['status']}',
        orElse: () => WalletStatus.active,
      ),
      dailyLimit: (map['dailyLimit'] ?? 25000.0).toDouble(),
      monthlyLimit: (map['monthlyLimit'] ?? 200000.0).toDouble(),
      dailyUsed: (map['dailyUsed'] ?? 0.0).toDouble(),
      monthlyUsed: (map['monthlyUsed'] ?? 0.0).toDouble(),
      isAutoRechargeEnabled: map['isAutoRechargeEnabled'] ?? false,
      autoRechargeThreshold: (map['autoRechargeThreshold'] ?? 50.0).toDouble(),
    );
  }

  WalletTransaction _transactionFromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      walletTransactionId: map['walletTransactionId'] ?? map['transactionId'] ?? '',
      walletId: map['walletId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: WalletTransactionType.values.firstWhere(
        (e) => e.toString() == 'WalletTransactionType.${map['type']}',
        orElse: () => WalletTransactionType.debit,
      ),
      balanceBefore: (map['balanceBefore'] ?? 0.0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      remarks: map['description'] ?? map['remarks'],
    );
  }

  void dispose() {
    _razorpay.clear();
  }
} 