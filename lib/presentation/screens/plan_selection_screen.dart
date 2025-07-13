import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/mobile_plans.dart';
import '../../data/models/operator_info.dart';
import '../../data/services/plan_api_service.dart';
import '../../data/services/wallet_service.dart';
import '../../data/services/robotics_exchange_service.dart';
import '../../data/models/recharge_models.dart';
import '../../data/models/wallet_models.dart' as wallet_models;
import '../providers/wallet_provider.dart';
import '../widgets/recharge_status_card.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String mobileNumber;
  final OperatorInfo operatorInfo;

  const PlanSelectionScreen({
    Key? key,
    required this.mobileNumber,
    required this.operatorInfo,
  }) : super(key: key);

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final PlanApiService _planApiService = PlanApiService();
  final WalletService _walletService = WalletService();
  final RoboticsExchangeService _roboticsService = RoboticsExchangeService();

  MobilePlansResponse? _plansResponse;
  ROfferResponse? _rOfferResponse;
  bool _isLoadingPlans = false;
  bool _isLoadingROffers = false;
  bool _isProcessingRecharge = false;
  String? _plansError;
  String? _rOffersError;
  String _selectedCategory = 'Unlimited';
  
  // Recharge status and expiry state
  RechargeStatusResponse? _rechargeStatusResponse;
  RechargeExpiryResponse? _rechargeExpiryResponse;
  bool _isLoadingStatus = false;
  bool _isLoadingExpiry = false;
  String? _statusError;
  String? _expiryError;

  @override
  void initState() {
    super.initState();
    _fetchMobilePlans();
    _fetchROffers();
    _fetchRechargeStatusForSupportedOperators();
  }

  @override
  void dispose() {
    _planApiService.dispose();
    _walletService.dispose();
    _roboticsService.dispose();
    super.dispose();
  }

  Future<void> _fetchMobilePlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final response = await _planApiService.getMobilePlans(
        operatorCode: widget.operatorInfo.opCode,
        circleCode: widget.operatorInfo.circleCode,
      );

      if (mounted) {
        setState(() {
          _plansResponse = response;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plansError = e.toString();
          _isLoadingPlans = false;
        });
      }
    }
  }

  Future<void> _fetchROffers() async {
    setState(() {
      _isLoadingROffers = true;
      _rOffersError = null;
    });

    try {
      final response = await _planApiService.getROffers(
        operatorInfo: widget.operatorInfo,
        mobileNumber: widget.mobileNumber,
      );

      if (mounted) {
        setState(() {
          _rOfferResponse = response;
          _isLoadingROffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rOffersError = e.toString();
          _isLoadingROffers = false;
        });
      }
    }
  }

  bool _shouldShowRechargeStatus() {
    // Only show for Airtel and VI operators
    final operatorName = widget.operatorInfo.operator.toLowerCase();
    return operatorName.contains('airtel') || 
           operatorName.contains('vodafone') || 
           operatorName.contains('idea') || 
           operatorName.contains('vi');
  }

  void _fetchRechargeStatusForSupportedOperators() {
    // Only fetch for Airtel and VI operators
    if (_shouldShowRechargeStatus()) {
      _fetchRechargeStatus();
      _fetchRechargeExpiry();
    }
  }

  Future<void> _fetchRechargeStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _statusError = null;
    });

    try {
      final response = await _planApiService.checkLastRecharge(
        operatorCode: widget.operatorInfo.opCode,
        mobileNumber: widget.mobileNumber,
      );

      if (mounted) {
        setState(() {
          _rechargeStatusResponse = response;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = e.toString();
          _isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _fetchRechargeExpiry() async {
    setState(() {
      _isLoadingExpiry = true;
      _expiryError = null;
    });

    try {
      final response = await _planApiService.checkRechargeExpiry(
        operatorCode: widget.operatorInfo.opCode,
        mobileNumber: widget.mobileNumber,
      );

      if (mounted) {
        setState(() {
          _rechargeExpiryResponse = response;
          _isLoadingExpiry = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expiryError = e.toString();
          _isLoadingExpiry = false;
        });
      }
    }
  }

  Future<void> _processRecharge(PlanDetails plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Login Required', 'Please login to continue');
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final walletBalance = walletProvider.getBalance();
    
    // Check if user has sufficient balance
    if (walletBalance < plan.priceValue.toDouble()) {
      _showInsufficientBalanceDialog(walletBalance, plan.priceValue.toDouble());
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showRechargeConfirmationDialog(plan, walletBalance);
    if (!confirmed) return;

    setState(() => _isProcessingRecharge = true);

    try {
      // Show processing dialog
      _showProcessingDialog();

      // Step 1: Process wallet deduction first
      final transactionId = 'RCH_${DateTime.now().millisecondsSinceEpoch}';
      
      final walletSuccess = await walletProvider.processTransaction(
        amount: plan.priceValue.toDouble(),
        purpose: 'Mobile Recharge - ${widget.mobileNumber}',
        transactionId: transactionId,
        metadata: {
          'mobile_number': widget.mobileNumber,
          'operator': widget.operatorInfo.operator,
          'circle': widget.operatorInfo.circle,
          'plan_details': {
            'price': plan.price,
            'validity': plan.validity,
            'desc': plan.desc,
            'type': plan.type,
          },
          'recharge_type': 'mobile',
        },
      );

      if (!walletSuccess) {
        Navigator.of(context).pop();
        _showErrorDialog('Wallet Error', 'Failed to deduct amount from wallet');
        return;
      }

      // Step 2: Process real-time recharge using RoboticsExchangeService
      final rechargeResponse = await _roboticsService.performRechargeWithLapuCheck(
        mobileNumber: widget.mobileNumber,
        operatorName: widget.operatorInfo.operator,
        circleName: widget.operatorInfo.circle,
        amount: plan.priceValue.toString(),
      );

      // Close processing dialog
      Navigator.of(context).pop();

      // Step 3: Create result and handle response
      final rechargeResult = wallet_models.RechargeResult(
        success: rechargeResponse.isSuccess,
        transactionId: rechargeResponse.orderId ?? transactionId,
        message: rechargeResponse.message,
        operatorTransactionId: rechargeResponse.opTransId,
        status: rechargeResponse.isSuccess ? 'SUCCESS' : 
                rechargeResponse.isProcessing ? 'PROCESSING' : 'FAILED',
        amount: plan.priceValue.toDouble(),
        mobileNumber: widget.mobileNumber,
        timestamp: DateTime.now(),
      );

      if (rechargeResult.success) {
        // Refresh wallet balance
        await walletProvider.refresh();
        
        // Show success dialog with real transaction details
        _showSuccessDialog(rechargeResult.transactionId, plan, rechargeResult);
      } else {
        // For failed recharge, refund the amount
        await walletProvider.addMoney(
          amount: plan.priceValue.toDouble(),
          purpose: 'Refund for failed recharge - ${widget.mobileNumber}',
          metadata: {
            'refund_reason': 'Recharge failed: ${rechargeResult.message}',
            'original_transaction_id': transactionId,
          },
        );
        
        // Refresh wallet balance
        await walletProvider.refresh();
        
        // Show error dialog with specific error message
        _showErrorDialog('Recharge Failed', rechargeResult.message);
      }
    } catch (e) {
      // Close processing dialog
      Navigator.of(context).pop();
      
      if (e is wallet_models.InsufficientBalanceException) {
        _showInsufficientBalanceDialog(e.availableBalance, e.requiredAmount);
      } else {
        _showErrorDialog('Recharge Failed', 'Recharge failed: ${e.toString()}');
      }
    } finally {
      setState(() => _isProcessingRecharge = false);
    }
  }

  Future<bool> _showRechargeConfirmationDialog(PlanDetails plan, double walletBalance) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Circle: ${widget.operatorInfo.circle}'),
            const SizedBox(height: 10),
            Text('Plan: ₹${plan.price}'),
            Text('Validity: ${plan.validity}'),
            Text('Description: ${plan.desc}'),
            const SizedBox(height: 10),
            Text('Wallet Balance: ₹${walletBalance.toStringAsFixed(2)}'),
            Text('After Recharge: ₹${(walletBalance - plan.priceValue).toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Processing Real-Time Recharge...'),
            const SizedBox(height: 8),
            Text(
              'Step 1: Validating recharge details',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Step 2: Deducting from wallet',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Step 3: Processing via Robotics Exchange',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take 10-30 seconds...',
              style: TextStyle(fontSize: 11, color: Colors.orange[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String transactionId, PlanDetails plan, wallet_models.RechargeResult rechargeResult) {
    final isProcessing = rechargeResult.status == 'PROCESSING';
    final title = isProcessing ? 'Recharge Processing' : 'Recharge Successful';
    final icon = isProcessing ? Icons.hourglass_empty : Icons.check_circle;
    final iconColor = isProcessing ? Colors.orange : Colors.green;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Circle: ${widget.operatorInfo.circle}'),
            Text('Amount: ₹${plan.price}'),
            Text('Plan: ${plan.desc}'),
            Text('Validity: ${plan.validity}'),
            const SizedBox(height: 10),
            Text('Transaction ID: $transactionId'),
            if (rechargeResult.operatorTransactionId != null) ...[
              Text('Operator TXN ID: ${rechargeResult.operatorTransactionId}'),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isProcessing ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isProcessing ? Colors.orange.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${rechargeResult.status}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isProcessing ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rechargeResult.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isProcessing ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isProcessing) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkRechargeStatus(transactionId);
              },
              child: const Text('Check Status'),
            ),
          ],
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog(double availableBalance, double requiredAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Insufficient Balance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You don\'t have enough balance to complete this recharge.'),
            const SizedBox(height: 10),
            Text('Available Balance: ₹${availableBalance.toStringAsFixed(2)}'),
            Text('Required Amount: ₹${requiredAmount.toStringAsFixed(2)}'),
            Text('Shortfall: ₹${(requiredAmount - availableBalance).toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            const Text('Please add money to your wallet to continue.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to add money screen with suggested amount
              context.pushNamed('add-money', extra: requiredAmount - availableBalance);
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRechargeStatus(String transactionId) async {
    try {
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
              Text('Checking recharge status...'),
            ],
          ),
        ),
      );

      // Check recharge status using the robotics exchange service
      final statusResponse = await _roboticsService.checkRechargeStatus(memberRequestTxnId: transactionId);
      
      // Create result from response
      final statusResult = wallet_models.RechargeResult(
        success: statusResponse.isSuccess,
        transactionId: statusResponse.orderId ?? transactionId,
        message: statusResponse.message,
        operatorTransactionId: statusResponse.opTransId,
        status: statusResponse.isSuccess ? 'SUCCESS' : 
                statusResponse.isProcessing ? 'PROCESSING' : 'FAILED',
        amount: double.tryParse(statusResponse.amount ?? '0'),
        mobileNumber: statusResponse.mobileNo,
        timestamp: DateTime.now(),
      );
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Update wallet balance
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.refresh();

      // Show status result
      _showStatusDialog(statusResult);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      _showErrorDialog('Status Check Failed', 'Failed to check recharge status: ${e.toString()}');
    }
  }

  void _showStatusDialog(wallet_models.RechargeResult statusResult) {
    final isSuccess = statusResult.status == 'SUCCESS';
    final isProcessing = statusResult.status == 'PROCESSING';
    final isFailed = statusResult.status == 'FAILED';
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    
    if (isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isProcessing) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (isFailed) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 30),
            const SizedBox(width: 10),
            Text('Recharge Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${statusResult.transactionId}'),
            if (statusResult.operatorTransactionId != null) ...[
              Text('Operator TXN ID: ${statusResult.operatorTransactionId}'),
            ],
            if (statusResult.mobileNumber != null) ...[
              Text('Mobile: ${statusResult.mobileNumber}'),
            ],
            if (statusResult.amount != null) ...[
              Text('Amount: ₹${statusResult.amount!.toStringAsFixed(2)}'),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                               color: statusColor.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${statusResult.status}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusResult.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isProcessing) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkRechargeStatus(statusResult.transactionId);
              },
              child: const Text('Check Again'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Plan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return Column(
            children: [
              // Wallet Balance Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${walletProvider.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.pushNamed('add-money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Money'),
                    ),
                  ],
                ),
              ),
              
              // Mobile Number Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Number: ${widget.mobileNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Operator: ${widget.operatorInfo.operator}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Circle: ${widget.operatorInfo.circle}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              // Recharge Status Cards (for Airtel and VI only)
              if (_shouldShowRechargeStatus())
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _fetchRechargeStatus,
                        child: RechargeStatusCard(
                          statusResponse: _rechargeStatusResponse,
                          isLoading: _isLoadingStatus,
                          error: _statusError,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _fetchRechargeExpiry,
                        child: RechargeExpiryCard(
                          expiryResponse: _rechargeExpiryResponse,
                          isLoading: _isLoadingExpiry,
                          error: _expiryError,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Plans Content
              Expanded(
                child: _buildPlansContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlansContent() {
    if (_isLoadingPlans) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_plansError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _plansError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMobilePlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_plansResponse == null || _plansResponse!.rdata == null || _plansResponse!.rdata!.getAllCategories().isEmpty) {
      return const Center(
        child: Text(
          'No plans available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildPlansList();
  }

  Widget _buildPlansList() {
    final plansByCategory = <String, List<PlanDetails>>{};
    
    // Get all categories from the response
    final categories = _plansResponse!.rdata!.getAllCategories();
    
    for (final category in categories) {
      final plans = <PlanDetails>[];
      for (final planItem in category.plans) {
        plans.add(PlanDetails.fromPlanItem(planItem, category.name));
      }
      plansByCategory[category.name] = plans;
    }

    return Column(
      children: [
        // Category Tabs
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: plansByCategory.keys.length,
            itemBuilder: (context, index) {
              final category = plansByCategory.keys.elementAt(index);
              final isSelected = category == _selectedCategory;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Plans List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plansByCategory[_selectedCategory]?.length ?? 0,
            itemBuilder: (context, index) {
              final plan = plansByCategory[_selectedCategory]![index];
              return _buildPlanCard(plan);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(PlanDetails plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${plan.price}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Validity: ${plan.validity}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.desc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingRecharge ? null : () => _processRecharge(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isProcessingRecharge ? 'Processing...' : 'Recharge Now',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 