import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recharger/data/services/postpaid_service.dart';
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/data/models/operator_info.dart';
import 'package:recharger/presentation/providers/wallet_provider.dart';
import 'package:recharger/presentation/widgets/samypay_logo.dart';
import 'package:recharger/core/theme/app_theme.dart';
import 'package:recharger/data/models/recharge_models.dart';

class PostpaidPlanSelectionScreen extends StatefulWidget {
  final String mobileNumber;
  final OperatorInfo operatorInfo;
  final Map<String, dynamic>? billDetails;

  const PostpaidPlanSelectionScreen({
    Key? key,
    required this.mobileNumber,
    required this.operatorInfo,
    this.billDetails,
  }) : super(key: key);

  @override
  State<PostpaidPlanSelectionScreen> createState() => _PostpaidPlanSelectionScreenState();
}

class _PostpaidPlanSelectionScreenState extends State<PostpaidPlanSelectionScreen> {
  final _postpaidService = PostpaidService();
  
  List<PostpaidPlanInfo> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPlanType = 'All';
  List<String> _availablePlanTypes = ['All'];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _postpaidService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.operatorInfo.operator} Postpaid Plans'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header with mobile info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              border: Border(bottom: BorderSide(color: Colors.indigo[200]!)),
            ),
            child: Column(
              children: [
                // SamyPay Logo
                const SamyPayLogo(size: 60),
                const SizedBox(height: 16),
                
                // Mobile Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile: ${widget.mobileNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Operator: ${widget.operatorInfo.operator}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Circle: ${widget.operatorInfo.circle}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (widget.billDetails != null)
                            Text(
                              'Customer: ${widget.billDetails!['customer_name']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Wallet Balance
                    Consumer<WalletProvider>(
                      builder: (context, walletProvider, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${walletProvider.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Outstanding bill display
                if (widget.billDetails != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Outstanding Bill:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${widget.billDetails!['outstanding_amount']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Plan type filter
          if (_availablePlanTypes.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Plan Type: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availablePlanTypes.map((planType) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(planType),
                              selected: _selectedPlanType == planType,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPlanType = planType;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Plans list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _buildPlansList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    if (_plans.isEmpty) {
      return const Center(
        child: Text(
          'No postpaid plans available for this operator',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(PostpaidPlanInfo plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.planName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.amount,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      plan.validity,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Plan benefits
            if (plan.benefits.isNotEmpty) ...[
              const Text(
                'Benefits:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...plan.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: 12),
            
            // Recharge button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _processPostpaidRecharge(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Pay Bill ${plan.amount}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final operatorCode = OperatorMapping.getOperatorCode(widget.operatorInfo.operator);
      final circleCode = OperatorMapping.getCircleCode(widget.operatorInfo.circle);

      final postpaidPlans = await _postpaidService.fetchPostpaidPlans(
        operatorCode: operatorCode,
        circleCode: circleCode,
      );

      // Extract plan types
      final planTypes = _postpaidService.getPostpaidPlanTypes();
      
      setState(() {
        _plans = postpaidPlans;
        _availablePlanTypes = ['All', ...planTypes];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading postpaid plans: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPostpaidRecharge(PostpaidPlanInfo plan) async {
    // Check wallet balance
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final planAmount = plan.numericAmount;
    
    if (walletProvider.balance < planAmount) {
      _showErrorDialog('Insufficient Balance', 
          'Your wallet balance is insufficient for this payment. Please add money to your wallet.');
      return;
    }

    // Show confirmation dialog
    final confirm = await _showConfirmationDialog(plan);
    if (!confirm) return;

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing postpaid payment...'),
          ],
        ),
      ),
    );

    try {
      // Deduct from wallet first
      await walletProvider.debitMoney(
        amount: planAmount,
        purpose: 'Postpaid Bill Payment',
        transactionId: 'POSTPAID_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'mobile_number': widget.mobileNumber,
          'operator': widget.operatorInfo.operator,
          'circle': widget.operatorInfo.circle,
          'plan_name': plan.planName,
          'amount': plan.amount,
          'validity': plan.validity,
          'type': 'POSTPAID_RECHARGE',
        },
      );

      // Process postpaid recharge
      final rechargeResult = await _postpaidService.performPostpaidRecharge(
        mobileNumber: widget.mobileNumber,
        operatorName: widget.operatorInfo.operator,
        circleName: widget.operatorInfo.circle,
        amount: planAmount.toStringAsFixed(2),
        planName: plan.planName,
        validity: plan.validity,
        description: plan.description,
      );

      // Close processing dialog
      Navigator.pop(context);

      if (rechargeResult != null && rechargeResult['success'] == true) {
        _showSuccessDialog(rechargeResult);
      } else {
        // Refund the wallet on failure
        await walletProvider.addMoney(
          amount: planAmount,
          purpose: 'Postpaid Payment Refund',
          metadata: {
            'original_transaction': 'POSTPAID_RECHARGE',
            'mobile_number': widget.mobileNumber,
            'operator': widget.operatorInfo.operator,
            'reason': 'payment_failed',
            'transaction_id': 'POSTPAID_REFUND_${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        
        _showErrorDialog('Payment Failed', 
            rechargeResult?['message'] ?? 'Postpaid payment failed. Amount has been refunded.');
      }
    } catch (e) {
      // Close processing dialog
      Navigator.pop(context);
      
      // Refund the wallet on error
      await walletProvider.addMoney(
        amount: planAmount,
        purpose: 'Postpaid Payment Refund',
        metadata: {
          'original_transaction': 'POSTPAID_RECHARGE',
          'mobile_number': widget.mobileNumber,
          'transaction_id': 'POSTPAID_ERROR_REFUND_${DateTime.now().millisecondsSinceEpoch}',
          'operator': widget.operatorInfo.operator,
          'reason': 'payment_error',
          'error': e.toString(),
        },
      );
      
      _showErrorDialog('Payment Error', 
          'An error occurred during payment: $e\n\nAmount has been refunded.');
    }
  }

  Future<bool> _showConfirmationDialog(PostpaidPlanInfo plan) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Postpaid Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile Number: ${widget.mobileNumber}'),
            Text('Operator: ${widget.operatorInfo.operator}'),
            Text('Plan: ${plan.planName}'),
            Text('Amount: ${plan.amount}'),
            Text('Validity: ${plan.validity}'),
            if (plan.description.isNotEmpty)
              Text('Description: ${plan.description}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to proceed with this payment?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile Number: ${result['mobile_number']}'),
            Text('Operator: ${result['operator']}'),
            Text('Amount: ₹${result['amount']}'),
            Text('Order ID: ${result['order_id']}'),
            if (result['op_trans_id'] != null)
              Text('Transaction ID: ${result['op_trans_id']}'),
            if (result['lapu_no'] != null)
              Text('LAPU Number: ${result['lapu_no']}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 