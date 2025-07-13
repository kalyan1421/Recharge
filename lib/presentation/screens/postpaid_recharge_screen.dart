import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recharger/data/services/postpaid_service.dart';
import 'package:recharger/data/services/operator_detection_service.dart';

import 'package:recharger/data/models/operator_info.dart';
import 'package:recharger/presentation/providers/wallet_provider.dart';
import 'package:recharger/presentation/screens/postpaid_plan_selection_screen.dart';
import 'package:recharger/presentation/widgets/samypay_logo.dart';
import 'package:recharger/presentation/widgets/mobile_input_widget.dart';
import 'package:recharger/presentation/widgets/operator_display_card.dart';
import 'package:recharger/core/theme/app_theme.dart';

class PostpaidRechargeScreen extends StatefulWidget {
  const PostpaidRechargeScreen({Key? key}) : super(key: key);

  @override
  State<PostpaidRechargeScreen> createState() => _PostpaidRechargeScreenState();
}

class _PostpaidRechargeScreenState extends State<PostpaidRechargeScreen> {
  final _mobileNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _postpaidService = PostpaidService();
  final _operatorDetectionService = OperatorDetectionService();

  OperatorInfo? _detectedOperator;
  Map<String, dynamic>? _billDetails;
  bool _isLoading = false;
  bool _autoDetectEnabled = true;
  bool _isPostpaidNumber = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _postpaidService.dispose();
    _operatorDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postpaid Recharge'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SamyPay Logo
              const Center(
                child: SamyPayLogo(size: 80),
              ),
              const SizedBox(height: 24),

              // Wallet Balance
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${walletProvider.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Mobile Number Input
              MobileInputWidget(
                controller: _mobileNumberController,
                onChanged: (value) {
                  if (_autoDetectEnabled && value.length == 10) {
                    _detectOperator();
                  }
                },
                isLoading: _isLoading,
                errorText: _errorMessage?.isNotEmpty == true ? _errorMessage : null,
              ),
              const SizedBox(height: 16),

              // Auto-detect toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto-detect operator',
                    style: TextStyle(fontSize: 14),
                  ),
                  Switch(
                    value: _autoDetectEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoDetectEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Manual detect button
              if (!_autoDetectEnabled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _detectOperator,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Detect Operator'),
                  ),
                ),
              const SizedBox(height: 16),

              // Postpaid status indicator
              if (_isPostpaidNumber)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Postpaid number detected',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Detected operator display
              if (_detectedOperator != null)
                OperatorDisplayCard(
                  operatorInfo: _detectedOperator!,
                ),
              const SizedBox(height: 16),

              // Bill Details display
              if (_billDetails != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBillInfoRow('Customer Name', _billDetails!['customer_name']),
                      _buildBillInfoRow('Plan', _billDetails!['plan_name']),
                      _buildBillInfoRow('Bill Amount', '₹${_billDetails!['bill_amount']}'),
                      _buildBillInfoRow('Due Date', _billDetails!['due_date']),
                      _buildBillInfoRow('Status', _billDetails!['due_status']),
                      if (_billDetails!['usage_details'] != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Usage Details:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildBillInfoRow('Data Used', _billDetails!['usage_details']['data_used']),
                        _buildBillInfoRow('SMS Used', _billDetails!['usage_details']['sms_used']),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Continue to plans button
              if (_detectedOperator != null && _isPostpaidNumber)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigateToPlans,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Postpaid Plans',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillInfoRow(String label, String value) {
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

  Future<void> _detectOperator() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _detectedOperator = null;
      _billDetails = null;
      _isPostpaidNumber = false;
    });

    try {
      final mobileNumber = _mobileNumberController.text.trim();
      
      // Check if number is postpaid
      final isPostpaid = await _postpaidService.isPostpaidNumber(mobileNumber);
      
      if (!isPostpaid) {
        setState(() {
          _errorMessage = 'This appears to be a prepaid number. Please use Mobile Prepaid for prepaid recharges.';
        });
        return;
      }

      // Detect operator
      final operatorInfo = await _operatorDetectionService.detectOperator(mobileNumber);
      
      if (operatorInfo != null) {
        // Check if operator supports postpaid
        if (!_postpaidService.supportsPostpaid(operatorInfo.operator)) {
          setState(() {
            _errorMessage = 'Postpaid is not supported for ${operatorInfo.operator}';
          });
          return;
        }

        setState(() {
          _detectedOperator = operatorInfo;
          _isPostpaidNumber = true;
        });

        // Get bill details
        final billDetails = await _postpaidService.getPostpaidBillDetails(mobileNumber);
        
        if (billDetails != null) {
          setState(() {
            _billDetails = billDetails;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to detect operator. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error detecting operator: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPlans() {
    if (_detectedOperator == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostpaidPlanSelectionScreen(
          mobileNumber: _mobileNumberController.text.trim(),
          operatorInfo: _detectedOperator!,
          billDetails: _billDetails,
        ),
      ),
    );
  }
} 