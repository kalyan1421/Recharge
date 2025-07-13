import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recharger/data/services/dth_service.dart';
import 'package:recharger/data/models/dth_models.dart';
import 'package:recharger/presentation/providers/wallet_provider.dart';
import 'package:recharger/presentation/screens/dth_plan_selection_screen.dart';
import 'package:recharger/presentation/widgets/samypay_logo.dart';
import 'package:recharger/core/theme/app_theme.dart';

class DthRechargeScreen extends StatefulWidget {
  const DthRechargeScreen({Key? key}) : super(key: key);

  @override
  State<DthRechargeScreen> createState() => _DthRechargeScreenState();
}

class _DthRechargeScreenState extends State<DthRechargeScreen> {
  final _dthNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _dthService = DthService();

  DthOperatorResponse? _detectedOperator;
  DthInfoResponse? _dthInfo;
  bool _isLoading = false;
  bool _autoDetectEnabled = true;
  String? _errorMessage;

  @override
  void dispose() {
    _dthNumberController.dispose();
    _dthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DTH Recharge'),
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

              // DTH Number Input
              const Text(
                'DTH Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dthNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter DTH number',
                  prefixIcon: const Icon(Icons.tv),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !_isLoading,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter DTH number';
                  }
                  if (!_dthService.validateDthNumber(value)) {
                    return 'Please enter a valid DTH number';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_autoDetectEnabled && value.length >= 11) {
                    _detectOperator();
                  }
                },
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Operator Detected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Operator: ${_detectedOperator!.dthName}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'DTH Number: ${_detectedOperator!.dthNumber}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // DTH Info display
              if (_dthInfo != null && _dthInfo!.isSuccess)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_dthInfo!.data != null) ...[
                        _buildInfoRow('Name', _dthInfo!.data!.name),
                        _buildInfoRow('VC Number', _dthInfo!.data!.vc),
                        _buildInfoRow('Balance', '₹${_dthInfo!.data!.balance}'),
                        _buildInfoRow('Mobile', _dthInfo!.data!.rmn),
                        if (_dthInfo!.data!.nextRechargeDate.isNotEmpty)
                          _buildInfoRow('Next Recharge', _dthInfo!.data!.nextRechargeDate),
                        if (_dthInfo!.data!.plan.isNotEmpty)
                          _buildInfoRow('Current Plan', _dthInfo!.data!.plan),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Continue to plans button
              if (_detectedOperator != null)
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
                      'View DTH Plans',
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

  Widget _buildInfoRow(String label, String value) {
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
      _dthInfo = null;
    });

    try {
      final dthNumber = _dthNumberController.text.trim();
      
      // Detect operator
      final operatorResponse = await _dthService.detectDthOperator(dthNumber);
      
      if (operatorResponse != null && operatorResponse.isSuccess) {
        setState(() {
          _detectedOperator = operatorResponse;
        });

        // Get DTH info
        final infoResponse = await _dthService.checkDthInfoWithLastRecharge(
          dthNumber,
          operatorResponse.dthOpCode,
        );

        if (infoResponse != null && infoResponse.isSuccess) {
          setState(() {
            _dthInfo = infoResponse;
          });
        }
      } else {
        setState(() {
          _errorMessage = operatorResponse?.message ?? 'Failed to detect operator';
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
        builder: (context) => DthPlanSelectionScreen(
          dthNumber: _dthNumberController.text.trim(),
          operatorResponse: _detectedOperator!,
          dthInfo: _dthInfo,
        ),
      ),
    );
  }
} 