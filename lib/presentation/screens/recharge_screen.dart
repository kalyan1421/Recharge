import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/operator_info.dart';
import '../../data/services/operator_detection_service.dart';
import '../widgets/mobile_input_widget.dart';
import '../widgets/operator_display_card.dart';
import 'plan_selection_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({Key? key}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _mobileController = TextEditingController();
  final _operatorService = OperatorDetectionService();
  
  String? _errorText;
  bool _isLoading = false;
  OperatorInfo? _operatorInfo;

  @override
  void dispose() {
    _mobileController.dispose();
    _operatorService.dispose();
    super.dispose();
  }

  Future<void> _detectOperator(String mobileNumber) async {
    if (mobileNumber.length != 10) {
      setState(() {
        _errorText = 'Please enter a valid 10-digit mobile number';
        _operatorInfo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final operatorInfo = await _operatorService.detectOperator(mobileNumber);
      setState(() {
        _operatorInfo = operatorInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Failed to detect operator. Please try again.';
        _operatorInfo = null;
        _isLoading = false;
      });
    }
  }

  void _navigateToPlans() {
    if (_operatorInfo != null && _mobileController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanSelectionScreen(
            mobileNumber: _mobileController.text,
            operatorInfo: _operatorInfo!,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MobileInputWidget(
              controller: _mobileController,
              errorText: _errorText,
              isLoading: _isLoading,
              onChanged: (value) {
                if (value.length == 10) {
                  _detectOperator(value);
                } else {
                  setState(() {
                    _operatorInfo = null;
                    _errorText = null;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            if (_operatorInfo != null) ...[
              OperatorDisplayCard(
                operatorInfo: _operatorInfo!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _navigateToPlans,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Available Plans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 