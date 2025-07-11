import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../data/models/operator_info.dart';
import '../../data/models/mobile_plans.dart';
import '../../data/services/plan_service.dart';
import '../../data/services/recharge_service.dart';
import '../../data/services/live_recharge_service.dart';
import '../widgets/plan_card.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import 'add_money_screen.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String mobileNumber;
  final OperatorInfo operatorInfo;
  final String circleCode;

  const PlanSelectionScreen({
    super.key,
    required this.mobileNumber,
    required this.operatorInfo,
    required this.circleCode,
  });

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlanService _planService = PlanService();
  
  MobilePlans? _mobilePlans;
  bool _isLoading = true;
  String? _errorMessage;
  List<SpecialOffer> _specialOffers = [];

  final List<PlanCategory> _categories = [
    PlanCategory.trulyUnlimited,
    PlanCategory.data,
    PlanCategory.talktime,
    PlanCategory.cricketPacks,
    PlanCategory.planVouchers,
    PlanCategory.roamingPacks,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we have a valid operator code
      final opCode = widget.operatorInfo.opCode;
      if (opCode == null || opCode.isEmpty) {
        throw Exception('Invalid operator code');
      }

      // Load mobile plans
      final plans = await _planService.fetchMobilePlans(
        opCode,
        widget.circleCode,
      );

      // Load special offers
      final offers = await _planService.fetchROffers(
        opCode,
        widget.mobileNumber,
      );

      if (mounted) {
        setState(() {
          _mobilePlans = plans;
          _specialOffers = offers.map((offer) => SpecialOffer.fromJson(offer)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.operatorInfo.operator ?? "Mobile"} Plans',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '+91 ${widget.mobileNumber}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildPlanTabs(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTabs() {
    if (_mobilePlans == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Special Offers Section
        if (_specialOffers.isNotEmpty) _buildSpecialOffers(),
        
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            tabs: _categories.map((category) {
              final plans = _mobilePlans!.getPlansByCategory(category);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.icon),
                    const SizedBox(width: 4),
                    Text(category.displayName),
                    if (plans.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          plans.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final plans = _mobilePlans!.getPlansByCategory(category);
              return _buildPlanList(plans, category);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialOffers() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Special Offers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _specialOffers.length,
              itemBuilder: (context, index) {
                final offer = _specialOffers[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.formattedAmount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(List<PlanItem> plans, PlanCategory category) {
    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${category.displayName.toLowerCase()} plans available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlanCard(
            plan: plan,
            onTap: () => _selectPlan(plan),
          ),
        );
      },
    );
  }

  void _selectPlan(PlanItem plan) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // Check wallet balance
    final validationResult = await _planService.validateRechargePrerequisites(
      mobileNumber: widget.mobileNumber,
      operatorCode: widget.operatorInfo.opCode ?? '',
      circleCode: widget.circleCode,
      planAmount: plan.rs,
      walletBalance: walletProvider.balance,
    );

    if (!validationResult.isValid) {
      _showInsufficientBalanceDialog(plan, validationResult);
      return;
    }

    // Show confirmation dialog if wallet balance is sufficient
    _showConfirmationDialog(plan, walletProvider.balance);
  }

  void _showInsufficientBalanceDialog(PlanItem plan, RechargeValidationResult validationResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('Insufficient Balance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${plan.formattedPrice}'),
            Text('Current Balance: ₹${Provider.of<WalletProvider>(context, listen: false).balance.toStringAsFixed(2)}'),
            Text('Required: ₹${validationResult.shortfallAmount.toStringAsFixed(2)} more'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationResult.errorMessage ?? 'Please add money to your wallet',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add money screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMoneyScreen(
                    suggestedAmount: validationResult.shortfallAmount,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(PlanItem plan, double walletBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: +91 ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Amount: ${plan.formattedPrice}'),
            Text('Validity: ${plan.validityDisplay}'),
            const SizedBox(height: 8),
            Text(
              plan.cleanDescription,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wallet Balance: ₹${walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance after recharge: ₹${(walletBalance - plan.rs).toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRecharge(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _processRecharge(PlanItem plan) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final liveRechargeService = LiveRechargeService();

    // Show enhanced loading dialog with progress tracking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing recharge...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${plan.rs} for ${widget.mobileNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we process your request securely...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Pre-flight validations
      if (authProvider.currentUser?.uid == null) {
        Navigator.pop(context);
        _showErrorDialog('Authentication required. Please log in again.');
        return;
      }

      // Enhanced wallet balance validation
      final currentBalance = walletProvider.balance;
      if (currentBalance < plan.rs) {
        Navigator.pop(context);
        final shortfall = plan.rs - currentBalance;
        _showInsufficientBalanceDialog(plan, RechargeValidationResult(
          isValid: false,
          errorMessage: 'Insufficient balance. Add ₹${shortfall.toStringAsFixed(2)} to proceed.',
          shortfallAmount: shortfall,
        ));
        return;
      }

      // Deduct amount from wallet first (with rollback capability)
      final walletSuccess = await walletProvider.deductMoney(
        amount: plan.rs.toDouble(),
        purpose: 'Mobile Recharge for ${widget.mobileNumber}',
        referenceId: 'PENDING_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!walletSuccess) {
        Navigator.pop(context);
        _showErrorDialog('Failed to deduct amount from wallet. Please try again.');
        return;
      }

      // Update loading dialog to show recharge processing
      Navigator.pop(context);
      _showEnhancedLoadingDialog('Processing recharge with operator...');

      // Process the enhanced live recharge
      final result = await liveRechargeService.processLiveRecharge(
        userId: authProvider.currentUser!.uid,
        mobileNumber: widget.mobileNumber,
        operatorCode: widget.operatorInfo.opCode ?? '',
        operatorName: widget.operatorInfo.operator ?? 'Unknown',
        circleCode: widget.operatorInfo.circleCode ?? widget.circleCode,
        planAmount: plan.rs,
        planDescription: plan.cleanDescription,
        validity: plan.validityDisplay,
        walletBalance: walletProvider.balance,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Handle result based on status
      if (result.success && result.status == 'SUCCESS') {
        // Immediate success
        _showEnhancedRechargeResultDialog(result, true);
      } else if (result.status == 'PENDING') {
        // Pending - start monitoring
        _showPendingRechargeDialog(result);
        _startStatusMonitoring(result.transactionId);
      } else {
        // Failed - refund wallet
        await _handleRechargeFailure(result, plan, walletProvider);
      }

    } catch (e) {
      // Close any open dialogs
      Navigator.pop(context);
      
      // Refund wallet on critical error
      await walletProvider.addMoney(
        amount: plan.rs.toDouble(),
        paymentMethod: 'refund',
        orderId: 'ERROR_REFUND_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      _showErrorDialog(
        'A system error occurred. Your money has been refunded to your wallet. Please try again.'
      );
    }
  }

  /// Show enhanced loading dialog with progress information
  void _showEnhancedLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  ),
                ),
                Icon(
                  Icons.phone_android,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security,
                    size: 14,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Secure Transaction',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show pending recharge dialog with monitoring capability
  void _showPendingRechargeDialog(RechargeResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color: Colors.orange.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Recharge Processing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${result.transactionId}'),
            Text('Mobile: +91 ${result.mobileNumber}'),
            Text('Operator: ${result.operatorName}'),
            Text('Amount: ${result.formattedAmount}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your recharge is being processed by the operator. We\'ll update you when it\'s complete.',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Monitoring status...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkTransactionStatus(result.transactionId);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  /// Enhanced recharge result dialog with better visual feedback
  void _showEnhancedRechargeResultDialog(RechargeResult result, bool isSuccess) {
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    final title = isSuccess ? 'Recharge Successful!' : 'Recharge Failed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultDetailRow('Transaction ID', result.transactionId),
            _buildResultDetailRow('Mobile Number', '+91 ${result.mobileNumber}'),
            _buildResultDetailRow('Operator', result.operatorName),
            _buildResultDetailRow('Amount', result.formattedAmount),
            _buildResultDetailRow('Status', result.status),
            if (result.operatorTransactionId != null)
              _buildResultDetailRow('Operator TXN ID', result.operatorTransactionId!),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    result.message,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isSuccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Allow user to retry or contact support
                _showRetryOptions(result);
              },
              child: const Text('Retry Options'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                // Navigate to transaction history or home
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(isSuccess ? 'Done' : 'Close'),
          ),
        ],
      ),
    );
  }

  /// Build result detail row
  Widget _buildResultDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle recharge failure with wallet refund
  Future<void> _handleRechargeFailure(
    RechargeResult result,
    PlanItem plan,
    WalletProvider walletProvider,
  ) async {
    // Refund wallet
    await walletProvider.addMoney(
      amount: plan.rs.toDouble(),
      paymentMethod: 'refund',
      orderId: result.transactionId,
    );
    
    // Show failure dialog
    _showEnhancedRechargeResultDialog(result, false);
  }

  /// Start automatic status monitoring for pending transactions
  void _startStatusMonitoring(String transactionId) {
    // Monitor status every 30 seconds for up to 10 minutes
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (timer.tick > 20) {  // Stop after 10 minutes (20 * 30s)
        timer.cancel();
        return;
      }

      try {
        final liveRechargeService = LiveRechargeService();
        final updatedResult = await liveRechargeService.checkRechargeStatusEnhanced(
          transactionId,
          forceRemoteCheck: true,
        );

        if (updatedResult != null && updatedResult.status != 'PENDING') {
          timer.cancel();
          
          // Show notification or update UI
          if (mounted) {
            _showStatusUpdateNotification(updatedResult);
          }
        }
      } catch (e) {
        // Continue monitoring despite errors
        print('Status monitoring error: $e');
      }
    });
  }

  /// Show status update notification
  void _showStatusUpdateNotification(RechargeResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recharge ${result.status.toLowerCase()}: ${result.message}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () => _showEnhancedRechargeResultDialog(result, result.success),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Check transaction status manually
  void _checkTransactionStatus(String transactionId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking status...'),
          ],
        ),
      ),
    );

    try {
      final liveRechargeService = LiveRechargeService();
      final result = await liveRechargeService.checkRechargeStatusEnhanced(
        transactionId,
        forceRemoteCheck: true,
      );

      Navigator.pop(context); // Close loading dialog

      if (result != null) {
        _showEnhancedRechargeResultDialog(result, result.success);
      } else {
        _showErrorDialog('Unable to check transaction status. Please try again later.');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Error checking status: ${e.toString()}');
    }
  }

  /// Show retry options for failed transactions
  void _showRetryOptions(RechargeResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry Recharge'),
              subtitle: const Text('Try the same recharge again'),
              onTap: () {
                Navigator.pop(context);
                // Retry the same plan
                _processRecharge(_getSelectedPlan());
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help with this transaction'),
              onTap: () {
                Navigator.pop(context);
                _contactSupport(result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Return to Home'),
              subtitle: const Text('Go back to main screen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Contact support for transaction issues
  void _contactSupport(RechargeResult result) {
    // In production, this would open support chat or email
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Details:'),
            const SizedBox(height: 8),
            Text('ID: ${result.transactionId}'),
            Text('Amount: ${result.formattedAmount}'),
            Text('Status: ${result.status}'),
            const SizedBox(height: 16),
            const Text(
              'Our support team will help you resolve this issue. Please save this transaction ID for reference.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production, open support channel
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support contact feature will be available soon'),
                ),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  /// Get currently selected plan (helper method)
  PlanItem _getSelectedPlan() {
    // This would return the currently selected plan
    // For now, return a default plan
    return const PlanItem(
      rs: 199,
      validity: '28 days',
      desc: 'Default plan',
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Recharge Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('An error occurred while processing your recharge.'),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 