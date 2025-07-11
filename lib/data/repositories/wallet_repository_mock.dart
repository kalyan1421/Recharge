import 'dart:async';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet.dart';

class WalletRepositoryMock {
  static const String demoWalletId = 'demo_wallet_001';
  static const String demoUserId = 'demo_user_001';
  
  final Map<String, Wallet> _wallets = {};
  final Map<String, List<WalletTransaction>> _transactions = {};
  
  WalletRepositoryMock() {
    _initializeDemoData();
  }
  
  void _initializeDemoData() {
    // Initialize demo wallet
    _wallets[demoWalletId] = Wallet(
      id: demoWalletId,
      walletId: demoWalletId,
      userId: demoUserId,
      balance: 1500.0,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
    
    // Initialize demo transactions
    _transactions[demoWalletId] = [
      WalletTransaction(
        id: 'txn_001',
        transactionId: 'txn_001',
        userId: demoUserId,
        amount: 1000.0,
        type: WalletTransactionType.credit,
        status: WalletTransactionStatus.success,
        description: 'Added money to wallet',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        balanceAfter: 1000.0,
        balanceBefore: 0.0,
      ),
      WalletTransaction(
        id: 'txn_002',
        transactionId: 'txn_002',
        userId: demoUserId,
        amount: 50.0,
        type: WalletTransactionType.debit,
        status: WalletTransactionStatus.success,
        description: 'Mobile recharge for 9876543210',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        balanceAfter: 950.0,
        balanceBefore: 1000.0,
      ),
      WalletTransaction(
        id: 'txn_003',
        transactionId: 'txn_003',
        userId: demoUserId,
        amount: 500.0,
        type: WalletTransactionType.credit,
        status: WalletTransactionStatus.pending,
        description: 'Adding money to wallet',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        balanceAfter: 1450.0,
        balanceBefore: 950.0,
      ),
    ];
  }
  
  Future<Wallet?> getWallet(String walletId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _wallets[walletId];
  }
  
  Future<double> getBalance(String walletId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _wallets[walletId]?.balance ?? 0.0;
  }
  
  Future<List<WalletTransaction>> getTransactions(String walletId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions[walletId] ?? [];
  }
  
  Future<List<WalletTransaction>> getTransactionHistory(String walletId) async {
    return getTransactions(walletId);
  }
  
  Future<bool> addMoney(String walletId, double amount, String description) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final wallet = _wallets[walletId];
    if (wallet == null) return false;
    
    final newBalance = wallet.balance + amount;
    _wallets[walletId] = wallet.copyWith(
      balance: newBalance,
      updatedAt: DateTime.now(),
    );
    
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = WalletTransaction(
      id: transactionId,
      transactionId: transactionId,
      userId: wallet.userId,
      amount: amount,
      type: WalletTransactionType.credit,
      status: WalletTransactionStatus.success,
      description: description,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      balanceAfter: newBalance,
      balanceBefore: wallet.balance,
    );
    
    _transactions.putIfAbsent(walletId, () => []).insert(0, transaction);
    return true;
  }
  
  Future<bool> deductMoney(String walletId, double amount, String description) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final wallet = _wallets[walletId];
    if (wallet == null || wallet.balance < amount) return false;
    
    final newBalance = wallet.balance - amount;
    _wallets[walletId] = wallet.copyWith(
      balance: newBalance,
      updatedAt: DateTime.now(),
    );
    
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = WalletTransaction(
      id: transactionId,
      transactionId: transactionId,
      userId: wallet.userId,
      amount: amount,
      type: WalletTransactionType.debit,
      status: WalletTransactionStatus.success,
      description: description,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      balanceAfter: newBalance,
      balanceBefore: wallet.balance,
    );
    
    _transactions.putIfAbsent(walletId, () => []).insert(0, transaction);
    return true;
  }
  
  Stream<Wallet?> walletStream(String walletId) {
    return Stream.periodic(const Duration(seconds: 5), (count) {
      return _wallets[walletId];
    });
  }
  
  Stream<List<WalletTransaction>> transactionsStream(String walletId) {
    return Stream.periodic(const Duration(seconds: 10), (count) {
      return _transactions[walletId] ?? [];
    });
  }
  
  Future<bool> debitWallet({
    required String walletId,
    required double amount,
    required String purpose,
    required String transactionId,
  }) async {
    return await deductMoney(walletId, amount, purpose);
  }
  
  Future<void> creditWallet({
    required String walletId,
    required double amount,
    required WalletTransactionType type,
    required String description,
    required String transactionId,
  }) async {
    await addMoney(walletId, amount, description);
  }
} 