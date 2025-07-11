import '../constants/app_constants.dart';

class Validators {
  // Phone Number Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any spaces or special characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length != AppConstants.phoneNumberLength) {
      return 'Phone number must be 10 digits';
    }
    
    if (!RegExp(AppConstants.phoneRegex).hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!RegExp(AppConstants.emailRegex).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    
    return null;
  }
  
  // OTP Validation
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }
  
  // Amount Validation
  static String? validateAmount(String? value, {double? minAmount, double? maxAmount}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (minAmount != null && amount < minAmount) {
      return 'Minimum amount is ₹${minAmount.toStringAsFixed(0)}';
    }
    
    if (maxAmount != null && amount > maxAmount) {
      return 'Maximum amount is ₹${maxAmount.toStringAsFixed(0)}';
    }
    
    return null;
  }
  
  // PAN Card Validation
  static String? validatePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }
    
    final panUpper = value.toUpperCase();
    if (!RegExp(AppConstants.panRegex).hasMatch(panUpper)) {
      return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
    }
    
    return null;
  }
  
  // Aadhar Card Validation
  static String? validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    
    final cleanAadhar = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!RegExp(AppConstants.aadharRegex).hasMatch(cleanAadhar)) {
      return 'Please enter a valid Aadhar number';
    }
    
    return null;
  }
  
  // IFSC Code Validation
  static String? validateIfsc(String? value) {
    if (value == null || value.isEmpty) {
      return 'IFSC code is required';
    }
    
    final ifscUpper = value.toUpperCase();
    if (!RegExp(AppConstants.ifscRegex).hasMatch(ifscUpper)) {
      return 'Please enter a valid IFSC code';
    }
    
    return null;
  }
  
  // Account Number Validation
  static String? validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account number is required';
    }
    
    final cleanAccount = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanAccount.length < 9 || cleanAccount.length > 18) {
      return 'Account number must be between 9-18 digits';
    }
    
    return null;
  }
  
  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 20) {
      return 'Password cannot exceed 20 characters';
    }
    
    return null;
  }
  
  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Required Field Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Date Validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      
      if (date.isAfter(now)) {
        return 'Date cannot be in the future';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }
  
  // Age Validation (for Date of Birth)
  static String? validateAge(String? value, {int minAge = 18, int maxAge = 100}) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    
    try {
      final birthDate = DateTime.parse(value);
      final now = DateTime.now();
      final age = now.year - birthDate.year;
      
      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }
      
      if (age > maxAge) {
        return 'Please enter a valid date of birth';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid date of birth';
    }
  }
  
  // GST Number Validation
  static String? validateGst(String? value) {
    if (value == null || value.isEmpty) {
      return null; // GST is optional
    }
    
    final gstUpper = value.toUpperCase();
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(gstUpper)) {
      return 'Please enter a valid GST number';
    }
    
    return null;
  }
  
  // Pincode Validation
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    
    return null;
  }
} 