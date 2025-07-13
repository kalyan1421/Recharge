import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../dth_recharge_screen.dart';
import '../postpaid_recharge_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('SamyPay'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Balance Card
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${walletProvider.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.pushNamed('add-money');
                          },
                          icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                          label: const Text(
                            'Add Money',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Services Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildServiceCard(
                  context,
                  icon: Icons.phone_android,
                  title: 'Mobile Prepaid',
                  subtitle: 'Recharge prepaid mobile',
                  color: Colors.blue,
                  onTap: () => context.push('/recharge'),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.phone_in_talk,
                  title: 'Mobile Postpaid',
                  subtitle: 'Pay postpaid bills',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostpaidRechargeScreen(),
                    ),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.tv,
                  title: 'DTH Recharge',
                  subtitle: 'Recharge DTH connection',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DthRechargeScreen(),
                    ),
                  ),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Add Money',
                  subtitle: 'Add money to wallet',
                  color: Colors.green,
                  onTap: () => context.pushNamed('add-money'),
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Transaction History',
                  subtitle: 'View all transactions',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Navigate to transaction history
                  },
                ),
                _buildServiceCard(
                  context,
                  icon: Icons.support_agent,
                  title: 'Support',
                  subtitle: 'Get help & support',
                  color: Colors.teal,
                  onTap: () {
                    // TODO: Navigate to support
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Development Test Button (can be removed in production)
            if (kDebugMode)
              ElevatedButton.icon(
                onPressed: () {
                  context.pushNamed('recharge-test');
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Live Recharge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 