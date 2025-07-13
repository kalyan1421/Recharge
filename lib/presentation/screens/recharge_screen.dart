import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/services/operator_detection_service.dart';
import '../../data/models/operator_info.dart';
import '../widgets/mobile_input_widget.dart';
import '../widgets/operator_display_card.dart';
import '../providers/wallet_provider.dart';
import 'plan_selection_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final OperatorDetectionService _operatorService = OperatorDetectionService();
  OperatorInfo? _detectedOperator;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _detectOperator(String mobileNumber) async {
    if (mobileNumber.length != 10) {
      setState(() {
        _detectedOperator = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final operator = await _operatorService.detectOperator(mobileNumber);
      setState(() {
        _detectedOperator = operator;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to detect operator. Please select manually.';
        _isLoading = false;
      });
    }
  }

  void _onMobileNumberChanged(String value) {
    // Remove any non-digit characters
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length <= 10) {
      _mobileController.value = _mobileController.value.copyWith(
        text: cleanNumber,
        selection: TextSelection.collapsed(offset: cleanNumber.length),
      );
      
      if (cleanNumber.length == 10) {
        _detectOperator(cleanNumber);
      } else {
        setState(() {
          _detectedOperator = null;
          _error = null;
        });
      }
    }
  }

  void _proceedToPlans() {
    if (_mobileController.text.length == 10 && _detectedOperator != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanSelectionScreen(
            mobileNumber: _mobileController.text,
            operatorInfo: _detectedOperator!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Recharge'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                          '₹${walletProvider.wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.push('/add-money');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Add Money'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Mobile Number Input Section
            const Text(
              'Enter Mobile Number',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            MobileInputWidget(
              controller: _mobileController,
              onChanged: _onMobileNumberChanged,
              errorText: _error,
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 24),
            
            // Operator Detection Section
            if (_isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Detecting operator...'),
              ),
            ] else if (_error != null) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_detectedOperator != null) ...[
              const Text(
                'Detected Operator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: _proceedToPlans,
                child: OperatorDisplayCard(
                  operatorInfo: _detectedOperator!,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Continue Button
            if (_mobileController.text.length == 10 && _detectedOperator != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToPlans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue to Plans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 