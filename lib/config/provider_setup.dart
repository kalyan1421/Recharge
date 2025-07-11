import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/user_provider.dart';
import '../presentation/providers/wallet_provider.dart';
import '../presentation/providers/recharge_provider.dart';
import '../presentation/providers/transaction_provider.dart';
import '../presentation/viewmodels/wallet_viewmodel.dart';

class ProviderSetup {
  static List<ChangeNotifierProvider> getProviders() {
    return [
      // Authentication Provider
      ChangeNotifierProvider<AuthProvider>(
        create: (context) => AuthProvider(),
      ),
      
      // User Provider
      ChangeNotifierProvider<UserProvider>(
        create: (context) => UserProvider(),
      ),
      
      // Wallet Provider
      ChangeNotifierProvider<WalletProvider>(
        create: (context) => WalletProvider(),
      ),
      
      // Wallet ViewModel
      ChangeNotifierProvider<WalletViewModel>(
        create: (context) => WalletViewModel(),
      ),
      
      // Recharge Provider
      ChangeNotifierProvider<RechargeProvider>(
        create: (context) => RechargeProvider(),
      ),
      
      // Transaction Provider - TODO: Implement TransactionProvider
      // ChangeNotifierProvider<TransactionProvider>(
      //   create: (context) => TransactionProvider(),
      // ),
    ];
  }
  
  static MultiProvider createApp({required Widget child}) {
    return MultiProvider(
      providers: getProviders(),
      child: child,
    );
  }
} 