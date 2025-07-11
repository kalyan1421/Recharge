import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class RegistrationScreen extends StatefulWidget {
  final String? phoneNumber;
  
  const RegistrationScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  
  // Form keys
  final _personalFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _kycFormKey = GlobalKey<FormState>();
  
  // Personal Details Controllers
  final _accountTypeController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  // Address Controllers
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _villageController = TextEditingController();
  final _talukController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  
  // KYC Controllers
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  
  // State variables
  String _selectedAccountType = 'Individual';
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.phoneNumber != null) {
      _mobileController.text = widget.phoneNumber!;
    }
    
    // Set default account type
    _accountTypeController.text = _selectedAccountType;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    
    // Dispose personal controllers
    _accountTypeController.dispose();
    _businessNameController.dispose();
    _gstController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    
    // Dispose address controllers
    _addressController.dispose();
    _pincodeController.dispose();
    _villageController.dispose();
    _talukController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    
    // Dispose KYC controllers
    _aadhaarController.dispose();
    _panController.dispose();
    
    super.dispose();
  }
  
  void _nextStep() {
    if (_tabController.index < 2) {
      _tabController.animateTo(_tabController.index + 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _submitRegistration();
    }
  }
  
  void _previousStep() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }
  
  bool _validateCurrentStep() {
    switch (_tabController.index) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _addressFormKey.currentState?.validate() ?? false;
      case 2:
        return _kycFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }
  
  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      // Update user profile with registration data
      final success = await authProvider.updateUserProfile(
        name: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text,
        accountType: _selectedAccountType,
        businessName: _businessNameController.text.isNotEmpty ? _businessNameController.text : null,
        gstNumber: _gstController.text.isNotEmpty ? _gstController.text : null,
        address: _addressController.text,
        pincode: _pincodeController.text,
        village: _villageController.text,
        taluk: _talukController.text,
        district: _districtController.text,
        state: _stateController.text,
        aadharNumber: _aadhaarController.text.isNotEmpty ? _aadhaarController.text : null,
        panNumber: _panController.text.isNotEmpty ? _panController.text : null,
      );
      
      if (success && mounted) {
        _showSuccessSnackBar('Registration completed successfully!');
        GoRouter.of(context).go('/home');
      } else {
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: const Text(
          'Complete Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'PERSONAL'),
                Tab(text: 'ADDRESS'),
                Tab(text: 'KYC'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              children: [
                _buildPersonalStep(),
                _buildAddressStep(),
                _buildKYCStep(),
              ],
            ),
          ),
          
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_validateCurrentStep()) {
                        _nextStep();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text(
                            _tabController.index == 2 ? 'Register' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _personalFormKey,
        child: Column(
          children: [
            // Account Type
            _buildInputField(
              controller: _accountTypeController,
              label: 'Account Type',
              isDropdown: true,
              dropdownItems: ['Individual', 'Business'],
              onChanged: (value) {
                setState(() {
                  _selectedAccountType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Business Name (conditional)
            if (_selectedAccountType == 'Business')
              _buildInputField(
                controller: _businessNameController,
                label: 'Business Name',
                validator: (value) {
                  if (_selectedAccountType == 'Business' && (value == null || value.isEmpty)) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
            
            if (_selectedAccountType == 'Business') const SizedBox(height: 16),
            
            // GST Number (conditional)
            if (_selectedAccountType == 'Business')
              _buildInputField(
                controller: _gstController,
                label: 'GST Number',
                validator: (value) {
                  if (_selectedAccountType == 'Business' && (value == null || value.isEmpty)) {
                    return 'Please enter GST number';
                  }
                  return null;
                },
              ),
            
            if (_selectedAccountType == 'Business') const SizedBox(height: 16),
            
            // First Name
            _buildInputField(
              controller: _firstNameController,
              label: 'First Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Last Name
            _buildInputField(
              controller: _lastNameController,
              label: 'Last Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date of Birth
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _dobController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'DOB',
                    hintText: 'Select date of birth',
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select date of birth';
                    }
                    return null;
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Email ID
            _buildInputField(
              controller: _emailController,
              label: 'Email ID',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            
            const SizedBox(height: 16),
            
            // Mobile Number (Display only - already verified)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _mobileController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Verified mobile number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  suffixIcon: const Icon(Icons.verified, color: Colors.green),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _addressFormKey,
        child: Column(
          children: [
            // Address
            _buildInputField(
              controller: _addressController,
              label: 'Address',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Pincode
            _buildInputField(
              controller: _pincodeController,
              label: 'Pincode',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pincode';
                }
                if (value.length != 6) {
                  return 'Please enter valid pincode';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Village
            _buildInputField(
              controller: _villageController,
              label: 'Village',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter village';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Taluk
            _buildInputField(
              controller: _talukController,
              label: 'Taluk',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter taluk';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // District
            _buildInputField(
              controller: _districtController,
              label: 'District',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter district';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // State
            _buildInputField(
              controller: _stateController,
              label: 'State',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter state';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKYCStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _kycFormKey,
        child: Column(
          children: [
            // Aadhaar Number
            _buildInputField(
              controller: _aadhaarController,
              label: 'Enter Aadhaar Number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Aadhaar number';
                }
                if (value.length != 12) {
                  return 'Please enter valid Aadhaar number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // PAN Number
            _buildInputField(
              controller: _panController,
              label: 'Enter PAN Number',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter PAN number';
                }
                if (value.length != 10) {
                  return 'Please enter valid PAN number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Upload Aadhaar Card
            _buildUploadButton(
              title: 'Upload Aadhaar Card',
              onTap: () {
                // Handle Aadhaar card upload
                _showUploadDialog('Aadhaar Card');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Upload PAN Card
            _buildUploadButton(
              title: 'Upload PAN Card',
              onTap: () {
                // Handle PAN card upload
                _showUploadDialog('PAN Card');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Upload Photo
            _buildUploadButton(
              title: 'Upload Your Photo',
              onTap: () {
                // Handle photo upload
                _showUploadDialog('Photo');
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isDropdown = false,
    List<String>? dropdownItems,
    Function(String?)? onChanged,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDropdown
          ? DropdownButtonFormField<String>(
              value: dropdownItems?.first,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: dropdownItems?.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
            )
          : TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              decoration: InputDecoration(
                labelText: label,
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
    );
  }
  
  Widget _buildUploadButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUploadDialog(String documentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $documentType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle camera capture
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Handle gallery selection
              },
            ),
          ],
        ),
      ),
    );
  }
} 