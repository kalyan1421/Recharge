import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/user_provider.dart';
import '../presentation/providers/wallet_provider.dart';

class ProviderSetup {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
        ChangeNotifierProvider<WalletProvider>(
          create: (context) => WalletProvider(),
        ),
      ];
} 