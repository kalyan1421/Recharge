import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/operator_info.dart';
import '../../data/services/operator_detection_service.dart';
import '../../data/services/plan_api_service.dart';
import '../widgets/operator_display_card.dart';
import 'plan_selection_screen.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final OperatorDetectionService _operatorService = OperatorDetectionService();
  
  OperatorInfo? _detectedOperator;
  bool _isDetecting = false;
  String? _errorMessage;
  String? _selectedCircle;
  String? _selectedOperatorCode;
  bool _showManualSelection = false;
  bool _isApiBlocked = false;
  List<Map<String, String>> _availableOperators = [];
  List<String> _availableCircles = [];
  bool _isLoadingOperators = true;

  @override
  void initState() {
    super.initState();
    _loadOperatorsAndCircles();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadOperatorsAndCircles() async {
    try {
      final operators = await _operatorService.getAvailableOperators();
      final circles = await _operatorService.getAvailableCircles();
      
      setState(() {
        _availableOperators = operators.map((op) => {
          'code': _getOperatorCode(op),
          'name': op
        }).toList();
        _availableCircles = circles;
        _isLoadingOperators = false;
      });
    } catch (e) {
      setState(() {
        _availableOperators = [
          {'code': '2', 'name': 'Airtel'},
          {'code': '11', 'name': 'Jio'},
          {'code': '23', 'name': 'Vi'},
          {'code': '5', 'name': 'BSNL'},
        ];
        _availableCircles = ['Andhra Pradesh', 'Delhi', 'Mumbai', 'Karnataka'];
        _isLoadingOperators = false;
      });
    }
  }

  String _getOperatorCode(String operatorName) {
    switch (operatorName.toLowerCase()) {
      case 'airtel':
        return '2';
      case 'jio':
        return '11';
      case 'vi':
      case 'vodafone':
      case 'idea':
        return '23';
      case 'bsnl':
        return '5';
      case 'mtnl':
        return '6';
      default:
        return '11';
    }
  }

  void _onMobileNumberChanged(String value) {
    setState(() {
      _detectedOperator = null;
      _errorMessage = null;
      _showManualSelection = false;
    });

    if (value.length == 10) {
      _detectOperator(value);
    }
  }

  Future<void> _detectOperator(String mobileNumber) async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
      _showManualSelection = false;
      _isApiBlocked = false;
    });
    try {
      final operatorInfo = await _operatorService.detectOperator(mobileNumber);
      if (mounted) {
        if (operatorInfo != null) {
        setState(() {
          _detectedOperator = operatorInfo;
            _selectedCircle = operatorInfo.circleCode;
          _isDetecting = false;
            _showManualSelection = false;
        });
        } else {
          _handleAutoDetectionFailure('Auto-detection failed');
        }
      }
    } on IPBlockedException catch (e) {
      if (mounted) {
        _handleIPBlockedException(e);
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _handleNetworkException(e);
      }
    } on AuthenticationException catch (e) {
      if (mounted) {
        _handleAuthenticationException(e);
      }
    } on InvalidMobileNumberException catch (e) {
      if (mounted) {
        _handleGenericException(e);
      }
    } catch (e) {
      if (mounted) {
        _handleGenericException(e);
      }
    }
  }

  void _handleIPBlockedException(IPBlockedException e) {
        setState(() {
      _isDetecting = false;
      _isApiBlocked = true;
      _showManualSelection = true;
      _errorMessage = 'Auto-detection temporarily unavailable. Please select your operator manually.';
    });
  }
  void _handleNetworkException(NetworkException e) {
    setState(() {
      _isDetecting = false;
      _showManualSelection = true;
      _errorMessage = 'Network issue detected. Please check your connection or select manually.';
    });
  }
  void _handleAuthenticationException(AuthenticationException e) {
    setState(() {
      _isDetecting = false;
      _showManualSelection = true;
      _errorMessage = 'Service authentication issue. Please select your operator manually.';
    });
  }
  void _handleGenericException(Object e) {
    setState(() {
      _isDetecting = false;
      _showManualSelection = true;
      _errorMessage = 'Auto-detection failed. Please select your operator manually.';
    });
  }
  void _handleAutoDetectionFailure(String reason) {
    setState(() {
      _isDetecting = false;
      _showManualSelection = true;
      _errorMessage = reason;
        });
      }

  void _onOperatorSelected(String operatorCode, String operatorName) {
    setState(() {
      _selectedOperatorCode = operatorCode;
      _detectedOperator = _operatorService.createManualOperatorInfo(
        _mobileController.text,
        operatorName,
        _availableCircles.isNotEmpty ? _availableCircles[0] : 'Andhra Pradesh',
      );
      _selectedCircle = _availableCircles.isNotEmpty ? _availableCircles[0] : 'Andhra Pradesh';
      _showManualSelection = false;
    });
  }

  void _onCircleChanged(String? circleCode) {
    setState(() {
      _selectedCircle = circleCode;
    });
  }

  void _proceedToPlans() {
    if (_detectedOperator != null && _selectedCircle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanSelectionScreen(
            mobileNumber: _mobileController.text,
            operatorInfo: _detectedOperator!,
            circleCode: _selectedCircle!,
          ),
        ),
      );
    }
  }

  Widget? _buildSuffixIcon() {
    if (_isDetecting) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
      );
    } else if (_mobileController.text.length == 10 && _detectedOperator != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 24,
        ),
      );
    } else if (_mobileController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          color: Colors.grey,
          size: 20,
        ),
        onPressed: () {
          _mobileController.clear();
          setState(() {
            _detectedOperator = null;
            _errorMessage = null;
            _showManualSelection = false;
          });
        },
      );
    }
    return null;
  }

  Widget _buildStatusIndicator() {
    final length = _mobileController.text.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(length).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(length).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(length),
            size: 16,
            color: _getStatusColor(length),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(length),
            style: TextStyle(
              color: _getStatusColor(length),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(length).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$length/10',
              style: TextStyle(
                color: _getStatusColor(length),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int length) {
    if (length == 10 && _detectedOperator != null) {
      return Colors.green;
    } else if (length == 10 && _showManualSelection) {
      return Colors.orange;
    } else if (length == 10) {
      return Colors.blue;
    } else if (length > 0) {
      return const Color(0xFF6C63FF);
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(int length) {
    if (length == 10 && _detectedOperator != null) {
      return Icons.check_circle;
    } else if (length == 10 && _showManualSelection) {
      return Icons.touch_app;
    } else if (length == 10) {
      return Icons.search;
    } else if (length > 0) {
      return Icons.edit;
    }
    return Icons.phone_android;
  }

  String _getStatusText(int length) {
    if (length == 10 && _detectedOperator != null) {
      return 'Operator detected';
    } else if (length == 10 && _showManualSelection) {
      return 'Select operator manually';
    } else if (length == 10 && _isDetecting) {
      return 'Detecting operator...';
    } else if (length == 10) {
      return 'Ready to detect';
    } else if (length > 0) {
      return 'Enter ${10 - length} more digits';
    }
    return 'Start typing';
  }

  Widget _buildManualOperatorSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Your Operator',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Operator selection grid
          if (_isLoadingOperators)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _availableOperators.length,
              itemBuilder: (context, index) {
                final operator = _availableOperators[index];
                final isSelected = _selectedOperatorCode == operator['code'];
                
                return GestureDetector(
                  onTap: () => _onOperatorSelected(operator['code']!, operator['name']!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6C63FF),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            operator['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_mobileController.text.length < 10) {
      return 'Enter Mobile Number';
    } else if (_isDetecting) {
      return 'Detecting Operator...';
    } else if (_detectedOperator == null && _showManualSelection) {
      return 'Select Operator';
    } else if (_detectedOperator == null) {
      return 'Operator Not Found';
    } else if (_selectedCircle == null) {
      return 'Select Circle';
    }
    return 'View Plans';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mobile Recharge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icon with background
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.smartphone,
                      color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mobile Recharge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                    const Text(
                            'Smart Detection + Manual Backup',
                      style: TextStyle(
                              color: Colors.white,
                        fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Mobile Number Input Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_android,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Phone number input with modern styling
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF).withOpacity(0.05),
                            const Color(0xFF9C88FF).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: _onMobileNumberChanged,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit number',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                        ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: Color(0xFF6C63FF),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                              width: 2,
                            ),
                        ),
                        filled: true,
                          fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                        ),
                          suffixIcon: _buildSuffixIcon(),
                        ),
                      ),
                    ),
                    
                    // Status indicator
                    if (_mobileController.text.length > 0) ...[
                      const SizedBox(height: 16),
                      _buildStatusIndicator(),
                    ],
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Manual Operator Selection (when auto-detection fails)
              if (_showManualSelection && _mobileController.text.length == 10)
                _buildManualOperatorSelection(),
              
              // Operator Display Card (when operator is detected/selected)
              if (_detectedOperator != null && !_showManualSelection)
                OperatorDisplayCard(
                  operatorInfo: _detectedOperator!,
                  selectedCircle: _selectedCircle,
                  availableCircles: _availableCircles,
                  onCircleChanged: _onCircleChanged,
                ),
              
              const SizedBox(height: 30),
              
              // Continue Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _mobileController.text.length == 10 && 
                            _detectedOperator != null && 
                            _selectedCircle != null && 
                            !_isDetecting
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _mobileController.text.length == 10 && 
                         _detectedOperator != null && 
                         _selectedCircle != null && 
                         !_isDetecting
                      ? null
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _mobileController.text.length == 10 && 
                             _detectedOperator != null && 
                             _selectedCircle != null && 
                             !_isDetecting
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _mobileController.text.length == 10 && 
                          _detectedOperator != null && 
                          _selectedCircle != null && 
                          !_isDetecting
                    ? _proceedToPlans
                    : null,
                    child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: _mobileController.text.length == 10 && 
                                   _detectedOperator != null && 
                                   _selectedCircle != null && 
                                   !_isDetecting
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 20,
                ),
                          const SizedBox(width: 12),
                          Text(
                            _mobileController.text.length == 10 && 
                            _detectedOperator != null && 
                            _selectedCircle != null && 
                            !_isDetecting
                                ? 'View Recharge Plans'
                                : _getButtonText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                              color: _mobileController.text.length == 10 && 
                                     _detectedOperator != null && 
                                     _selectedCircle != null && 
                                     !_isDetecting
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Recent Recharges Section
              if (_detectedOperator != null && !_showManualSelection) _buildRecentRecharges(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecharges() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Recharges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sample recent recharge items
          _buildRecentRechargeItem('₹199', '28 days', 'Unlimited + 2GB/day', '2 days ago'),
          const Divider(height: 20),
          _buildRecentRechargeItem('₹49', '3 days', '3GB Data', '1 week ago'),
          const Divider(height: 20),
          _buildRecentRechargeItem('₹299', '28 days', 'Unlimited + OTT', '2 weeks ago'),
        ],
      ),
    );
  }

  Widget _buildRecentRechargeItem(String amount, String validity, String description, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt,
            color: Color(0xFF6C63FF),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$description • $validity',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    IconData iconData;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    if (_isApiBlocked) {
      iconData = Icons.info_outline;
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      textColor = Colors.blue.shade600;
    } else if (_errorMessage!.contains('Network')) {
      iconData = Icons.wifi_off;
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      textColor = Colors.orange.shade600;
    } else {
      iconData = Icons.error_outline;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade600;
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isApiBlocked)
            TextButton(
              onPressed: () => _showIPBlockedInfo(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
              ),
              child: Text(
                'Why?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showIPBlockedInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
            const SizedBox(width: 8),
            const Text('Service Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-detection is temporarily unavailable due to service restrictions.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Manual selection works perfectly',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'All recharge features available',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Same reliable service',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Simply select your operator from the list below and proceed with your recharge.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 