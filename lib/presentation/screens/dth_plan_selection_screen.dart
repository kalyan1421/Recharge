import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recharger/data/services/dth_service.dart';
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/presentation/providers/wallet_provider.dart';
import 'package:recharger/presentation/widgets/samypay_logo.dart';
import 'package:recharger/core/theme/app_theme.dart';

class DthPlanSelectionScreen extends StatefulWidget {
  final String dthNumber;
  final DthOperatorResponse operatorResponse;
  final DthInfoResponse? dthInfo;

  const DthPlanSelectionScreen({
    Key? key,
    required this.dthNumber,
    required this.operatorResponse,
    this.dthInfo,
  }) : super(key: key);

  @override
  State<DthPlanSelectionScreen> createState() => _DthPlanSelectionScreenState();
}

class _DthPlanSelectionScreenState extends State<DthPlanSelectionScreen> {
  final _dthService = DthService();
  
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLanguage = 'All';
  List<String> _availableLanguages = ['All'];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _dthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.operatorResponse.dthName} Plans'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header with DTH info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Column(
              children: [
                // SamyPay Logo
                const SamyPayLogo(size: 60),
                const SizedBox(height: 16),
                
                // DTH Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DTH Number: ${widget.dthNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Operator: ${widget.operatorResponse.dthName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (widget.dthInfo?.data?.name != null)
                            Text(
                              'Customer: ${widget.dthInfo!.data!.name}',
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
              ],
            ),
          ),
          
          // Language filter
          if (_availableLanguages.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Language: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableLanguages.map((language) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(language),
                              selected: _selectedLanguage == language,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedLanguage = language;
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
          'No plans available for this operator',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final filteredPlans = _selectedLanguage == 'All'
        ? _plans
        : _plans.where((plan) => plan['language'] == _selectedLanguage).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPlans.length,
      itemBuilder: (context, index) {
        final plan = filteredPlans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
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
                        plan['plan_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Language: ${plan['language']}',
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
                      plan['amount'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      plan['duration'],
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
            
            // Plan details
            if (plan['channels'] != null)
              _buildDetailRow('Channels', plan['channels']),
            if (plan['paid_channels'] != null)
              _buildDetailRow('Paid Channels', plan['paid_channels']),
            if (plan['hd_channels'] != null)
              _buildDetailRow('HD Channels', plan['hd_channels']),
            
            const SizedBox(height: 12),
            
            // Recharge button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _processDthRecharge(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Recharge ${plan['amount']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plansResponse = await _dthService.fetchDthPlans(
        widget.operatorResponse.dthOpCode,
      );

      if (plansResponse != null && plansResponse.isSuccess) {
        final parsedPlans = _dthService.parseDthPlans(plansResponse);
        
        // Extract unique languages
        final languages = parsedPlans
            .map((plan) => plan['language'] as String)
            .toSet()
            .toList();
        languages.sort();
        
        setState(() {
          _plans = parsedPlans;
          _availableLanguages = ['All', ...languages];
        });
      } else {
        setState(() {
          _errorMessage = plansResponse?.message ?? 'Failed to load plans';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading plans: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processDthRecharge(Map<String, dynamic> plan) async {
    // Check wallet balance
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final planAmount = plan['numeric_amount'] as double;
    
    if (walletProvider.balance < planAmount) {
      _showErrorDialog('Insufficient Balance', 
          'Your wallet balance is insufficient for this recharge. Please add money to your wallet.');
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
            Text('Processing DTH recharge...'),
          ],
        ),
      ),
    );

    try {
      // Deduct from wallet first
      await walletProvider.debitMoney(
        amount: planAmount,
        purpose: 'DTH Recharge',
        transactionId: 'DTH_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'dth_number': widget.dthNumber,
          'operator': widget.operatorResponse.dthName,
          'plan_name': plan['plan_name'],
          'amount': plan['amount'],
          'duration': plan['duration'],
          'channels': plan['channels'],
          'type': 'DTH_RECHARGE',
        },
      );

      // Process DTH recharge
      final rechargeResult = await _dthService.performDthRecharge(
        dthNumber: widget.dthNumber,
        operatorName: widget.operatorResponse.dthName,
        amount: planAmount.toStringAsFixed(2),
        planName: plan['plan_name'],
        duration: plan['duration'],
        channels: plan['channels'] ?? '',
      );

      // Close processing dialog
      Navigator.pop(context);

      if (rechargeResult != null && rechargeResult['success'] == true) {
        _showSuccessDialog(rechargeResult);
      } else {
        // Refund the wallet on failure
        await walletProvider.addMoney(
          amount: planAmount,
          purpose: 'DTH Recharge Refund',
          metadata: {
            'original_transaction': 'DTH_RECHARGE',
            'dth_number': widget.dthNumber,
            'operator': widget.operatorResponse.dthName,
            'reason': 'recharge_failed',
            'transaction_id': 'DTH_REFUND_${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        
        _showErrorDialog('Recharge Failed', 
            rechargeResult?['message'] ?? 'DTH recharge failed. Amount has been refunded.');
      }
    } catch (e) {
      // Close processing dialog
      Navigator.pop(context);
      
      // Refund the wallet on error
      await walletProvider.addMoney(
        amount: planAmount,
        purpose: 'DTH Recharge Refund',
        metadata: {
          'original_transaction': 'DTH_RECHARGE',
          'transaction_id': 'DTH_ERROR_REFUND_${DateTime.now().millisecondsSinceEpoch}',
          'dth_number': widget.dthNumber,
          'operator': widget.operatorResponse.dthName,
          'reason': 'recharge_error',
          'error': e.toString(),
        },
      );
      
      _showErrorDialog('Recharge Error', 
          'An error occurred during recharge: $e\n\nAmount has been refunded.');
    }
  }

  Future<bool> _showConfirmationDialog(Map<String, dynamic> plan) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm DTH Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DTH Number: ${widget.dthNumber}'),
            Text('Operator: ${widget.operatorResponse.dthName}'),
            Text('Plan: ${plan['plan_name']}'),
            Text('Amount: ${plan['amount']}'),
            Text('Duration: ${plan['duration']}'),
            if (plan['channels'] != null)
              Text('Channels: ${plan['channels']}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to proceed with this recharge?',
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
            Text('Recharge Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DTH Number: ${result['dth_number']}'),
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