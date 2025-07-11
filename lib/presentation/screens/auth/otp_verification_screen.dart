import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/samypay_logo.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _showKeyboard = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showErrorSnackBar('Please enter complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(_otpCode);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        // Check auth state to determine next step
        if (authProvider.authState == AuthState.otpVerified) {
          // New user or incomplete profile - navigate to registration
          GoRouter.of(context).pushNamed('registration', extra: widget.phoneNumber);
        } else if (authProvider.authState == AuthState.authenticated) {
          // Existing user with complete profile - navigate to home
          GoRouter.of(context).go('/home');
        }
      } else {
        _showErrorSnackBar(authProvider.errorMessage);
      }
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendOtp(widget.phoneNumber);
    
    if (mounted) {
      if (success) {
        _showSuccessSnackBar('OTP sent successfully');
      } else {
        _showErrorSnackBar(authProvider.errorMessage);
      }
    }
  }

  void _handlePaste(String value) {
    if (value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = value[i];
      }
      setState(() {});
      _verifyOtp();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onKeypadTap(String value) {
    if (value == '⌫') {
      // Backspace
      for (int i = 5; i >= 0; i--) {
        if (_otpControllers[i].text.isNotEmpty) {
          _otpControllers[i].clear();
          if (i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
          break;
        }
      }
    } else if (value == '→') {
      // Submit
      _verifyOtp();
    } else {
      // Number input
      for (int i = 0; i < 6; i++) {
        if (_otpControllers[i].text.isEmpty) {
          _otpControllers[i].text = value;
          if (i < 5) {
            _focusNodes[i + 1].requestFocus();
          }
          break;
        }
      }
      
      // Auto-submit when all 6 digits are entered
      if (_otpCode.length == 6) {
        _verifyOtp();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
                             // Logo
               const SamyPayLogo(size: 100),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Verification Code',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Please enter code sent to Mobile Number',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _otpControllers[index].text.isNotEmpty 
                            ? AppTheme.primaryColor 
                            : AppTheme.dividerColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: (value) {
                        // Handle paste operation
                        if (value.length > 1) {
                          _handlePaste(value);
                          return;
                        }
                        
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        if (_otpCode.length == 6) {
                          _verifyOtp();
                        }
                        setState(() {});
                      },
                      onTap: () {
                        setState(() {
                          _showKeyboard = true;
                        });
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Timer and Resend OTP
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (authProvider.otpTimeoutSeconds > 0) ...[
                        const Icon(
                          Icons.timer,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '00:${authProvider.otpTimeoutSeconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: _resendOtp,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Custom Numeric Keypad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // First row: 1, 2, 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['1', '2', '3'].map((key) => _buildKeypadButton(key)).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Second row: 4, 5, 6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['4', '5', '6'].map((key) => _buildKeypadButton(key)).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Third row: 7, 8, 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['7', '8', '9'].map((key) => _buildKeypadButton(key)).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Fourth row: *, 0, #
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildKeypadButton('*'),
                        _buildKeypadButton('0'),
                        _buildKeypadButton('#'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Fifth row: backspace, +, .
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildKeypadButton('⌫', isSpecial: true),
                        _buildKeypadButton('+'),
                        _buildKeypadButton('.'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Submit button (arrow)
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _onKeypadTap('→'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isSpecial = false}) {
    return GestureDetector(
      onTap: () => _onKeypadTap(value),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: isSpecial ? AppTheme.backgroundColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isSpecial ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
} 