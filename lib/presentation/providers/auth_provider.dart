import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../config/firebase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user.dart' show UserType, UserStatus, UserTier;

enum AuthState { initial, loading, authenticated, unauthenticated, otpVerified, error }

class AuthProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AuthRepository _authRepository = AuthRepository();
  
  // State variables
  AuthState _authState = AuthState.initial;
  User? _currentUser; 
  domain.User? _userData;
  String _errorMessage = '';
  String _verificationId = '';
  int? _resendToken;
  String? _currentPhoneNumber;
  bool _isLoading = false;
  bool _isCodeSent = false;
  
  // Timer for OTP
  Timer? _otpTimer;
  int _otpTimeoutSeconds = 0;
  
  // Getters
  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  domain.User? get userData => _userData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isCodeSent => _isCodeSent;
  int get otpTimeoutSeconds => _otpTimeoutSeconds;
  String get userId => _currentUser?.uid ?? '';
  String get phoneNumber => _currentUser?.phoneNumber ?? '';
  String get userName => _userData?.name ?? '';
  String get userEmail => _userData?.email ?? '';
  
  // Phone number validation
  bool isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
  }
  
  // Format phone number with country code
  String formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '+91$cleanPhone';
    }
    return cleanPhone;
  }
  
  AuthProvider() {
    _initializeAuth();
  }
  
  /// Initialize authentication state
  void _initializeAuth() {
    _currentUser = FirebaseConfig.currentUser;
    _authState = _currentUser != null ? AuthState.authenticated : AuthState.unauthenticated;
    
    // Listen to auth state changes
    FirebaseConfig.auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  /// Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    _currentUser = user;
    
    if (user != null) {
      try {
        // Load user data from Firestore
        _userData = await _authRepository.getUserData(user.uid);
        _authState = AuthState.authenticated;
        await _saveUserSession(user);
        _logger.i('User authenticated: ${user.uid}');
      } catch (e) {
        _logger.e('Failed to load user data: $e');
        _authState = AuthState.error;
        _setError('Failed to load user data');
      }
    } else {
      _userData = null;
      _authState = AuthState.unauthenticated;
      await _clearUserSession();
      _logger.i('User signed out');
    }
    
    notifyListeners();
  }
  
  /// Send OTP to phone number
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Validate phone number
      if (!isValidPhoneNumber(phoneNumber)) {
        _setError('Please enter a valid 10 digit mobile number');
        return false;
      }
      
      // Format phone number with country code
      final formattedPhone = formatPhoneNumber(phoneNumber);
      _currentPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      _logger.i('Sending OTP to: $formattedPhone');
      
      if (kIsWeb) {
        // Web implementation
        return await _sendOTPWeb(formattedPhone);
      } else {
        // Mobile implementation
        return await _sendOTPMobile(formattedPhone);
      }
      
    } catch (e, stackTrace) {
      _logger.e('Send OTP failed: $e');
      _setError('Failed to send OTP. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Send OTP for mobile platforms
  Future<bool> _sendOTPMobile(String phoneNumber) async {
    final completer = Completer<bool>();
    
    // Set a longer timeout for production
    Timer(const Duration(seconds: 120), () {
      if (!completer.isCompleted) {
        _logger.e('Firebase OTP request timeout after 2 minutes');
        _setError('Request timeout. Please check your internet connection and try again.');
        completer.complete(false);
      }
    });
    
    await FirebaseConfig.auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in for Android
        try {
          await _signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete(true);
        } catch (e) {
          if (!completer.isCompleted) completer.complete(false);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _logger.e('Phone verification failed: ${e.message}');
        _setError(_getErrorMessage(e));
        if (!completer.isCompleted) completer.complete(false);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _isCodeSent = true;
        _startOTPTimer();
        _logger.i('OTP sent successfully');
        if (!completer.isCompleted) completer.complete(true);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        _logger.i('Auto retrieval timeout');
      },
      timeout: const Duration(seconds: 120),
      forceResendingToken: _resendToken,
    );
    
    return await completer.future;
  }
  
  /// Send OTP for web platform
  Future<bool> _sendOTPWeb(String phoneNumber) async {
    try {
      // For web, we'll use the mobile implementation as fallback
      // Web-specific reCAPTCHA implementation can be added later
      _logger.i('Web platform detected, using mobile implementation');
      return await _sendOTPMobile(phoneNumber);
    } catch (e) {
      _logger.e('Web OTP send failed: $e');
      _setError('Failed to send OTP. Please try again.');
      return false;
    }
  }
  
  /// Verify OTP
  Future<bool> verifyOtp(String otp) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Validate OTP
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        _setError('Please enter a valid 6-digit OTP');
        return false;
      }
      
      _logger.i('Using real Firebase OTP verification');
      
      if (_verificationId.isEmpty) {
        _setError('Verification session expired. Please resend OTP.');
        return false;
      }
      
      _logger.i('Verifying OTP: $otp');
      
      // Use mobile OTP verification for all platforms
      return await _verifyOTPMobile(otp);
      
    } catch (e, stackTrace) {
      _logger.e('OTP verification failed: $e');
      _setError('Invalid OTP. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Verify OTP for mobile platforms
  Future<bool> _verifyOTPMobile(String otp) async {
    try {
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      
      // Sign in with credential
      return await _signInWithCredential(credential);
    } catch (e) {
      _logger.e('Mobile OTP verification failed: $e');
      _setError('Invalid OTP. Please try again.');
      return false;
    }
  }
  

  
  /// Sign in with phone auth credential
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseConfig.auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        _currentUser = user;
        
        // Load user data in Firestore using AuthRepository
        _userData = await _authRepository.getUserData(user.uid);
        
        bool isNewUser = false;
        if (_userData == null) {
          // Create new user data for first-time users
          _userData = await _createUserInFirestore(user);
          isNewUser = true;
        }
        
        // Check if user profile is complete (has name and email)
        bool isProfileComplete = _userData!.name.isNotEmpty && _userData!.email.isNotEmpty;
        
        if (isNewUser || !isProfileComplete) {
          // New user or incomplete profile - needs registration
          _authState = AuthState.otpVerified;
          _logger.i('User needs to complete registration: ${user.uid}');
        } else {
          // Existing user with complete profile - direct to home
          _authState = AuthState.authenticated;
          _logger.i('Existing user signed in successfully: ${user.uid}');
        }
        
        await _saveUserSession(user);
        _stopOTPTimer();
        
        // Log analytics event
        FirebaseConfig.logEvent('login', {
          'method': 'phone',
          'user_id': user.uid,
          'is_new_user': isNewUser,
          'profile_complete': isProfileComplete,
        });
        
        return true;
      } else {
        _setError('Authentication failed. Please try again.');
        return false;
      }
      
    } catch (e) {
      if (e is FirebaseAuthException) {
        _setError(_getErrorMessage(e));
      } else {
        _setError('Authentication failed. Please try again.');
      }
      return false;
    }
  }
  
  /// Resend OTP
  Future<bool> resendOtp(String phoneNumber) async {
    if (_otpTimeoutSeconds > 0) {
      _setError('Please wait ${_otpTimeoutSeconds} seconds before resending OTP');
      return false;
    }
    
    _logger.i('Resending OTP...');
    _otpTimeoutSeconds = 60;
    return await sendOtp(phoneNumber);
  }
  
  /// Start OTP timer
  void _startOTPTimer() {
    _otpTimer?.cancel();
    _otpTimeoutSeconds = 60;
    
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimeoutSeconds > 0) {
        _otpTimeoutSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Stop OTP timer
  void _stopOTPTimer() {
    _otpTimer?.cancel();
    _otpTimeoutSeconds = 0;
  }
  
  /// Sign out user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      await FirebaseConfig.signOut();
      await _clearUserSession();
      
      _currentUser = null;
      _userData = null;
      _authState = AuthState.unauthenticated;
      _verificationId = '';
      _resendToken = null;
      _isCodeSent = false;
      _stopOTPTimer();
      _clearError();
      
      // Log analytics event
      FirebaseConfig.logEvent('logout', null);
      
      _logger.i('User signed out successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Sign out failed: $e');
      _setError('Failed to sign out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Save user session
  Future<void> _saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyUserId, user.uid);
      await prefs.setString(AppConstants.keyUserPhone, user.phoneNumber ?? '');
      await prefs.setString(AppConstants.keyUserName, user.displayName ?? '');
    } catch (e) {
      _logger.w('Failed to save user session: $e');
    }
  }
  
  /// Clear user session
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyIsLoggedIn);
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserPhone);
      await prefs.remove(AppConstants.keyUserName);
      await prefs.remove(AppConstants.keyWalletBalance);
      await prefs.remove(AppConstants.keyKycStatus);
    } catch (e) {
      _logger.w('Failed to clear user session: $e');
    }
  }
  
  /// Check if user session exists
  Future<bool> checkUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    } catch (e) {
      _logger.w('Failed to check user session: $e');
      return false;
    }
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _authState = AuthState.error;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = '';
    if (_authState == AuthState.error) {
      _authState = _currentUser != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }
  
  /// Get user-friendly error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please resend OTP.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'session-expired':
        return 'Session expired. Please try again.';
      case 'network-request-failed':
        return AppConstants.errorNetwork;
      default:
        return e.message ?? AppConstants.errorGeneral;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_currentUser == null) return false;
      
      _setLoading(true);
      
      await _currentUser!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _currentUser!.updatePhotoURL(photoURL);
      }
      
      await _currentUser!.reload();
      _currentUser = FirebaseConfig.currentUser;
      notifyListeners();
      
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Profile update failed: $e');
      _setError('Failed to update profile.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) return false;
      
      _setLoading(true);
      
      await _currentUser!.delete();
      await _clearUserSession();
      
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Account deletion failed: $e');
      _setError('Failed to delete account.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Email and Password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      _logger.i('Signing in with email: $email');

      final credential = await FirebaseConfig.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _logger.i('Email sign-in successful');
        _currentUser = credential.user;
        _authState = AuthState.authenticated;
        await _saveUserSession(credential.user!);
        _clearError();
        
        // Log analytics event
        FirebaseConfig.logEvent('email_login', {
          'user_email': credential.user!.email ?? 'unknown',
        });
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      _logger.e('Email sign-in failed: ${e.message}');
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _logger.e('Email sign-in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  /// Create account with Email and Password
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      _logger.i('Creating account with email: $email');

      final credential = await FirebaseConfig.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _logger.i('Email sign-up successful');
        _currentUser = credential.user;
        _authState = AuthState.authenticated;
        await _saveUserSession(credential.user!);
        _clearError();
        
        // Log analytics event
        FirebaseConfig.logEvent('email_register', {
          'user_email': credential.user!.email ?? 'unknown',
        });
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      _logger.e('Email sign-up failed: ${e.message}');
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _logger.e('Email sign-up error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create user data in Firestore
  Future<domain.User> _createUserInFirestore(User firebaseUser) async {
    try {
      _logger.i('Creating user data in Firestore for: ${firebaseUser.uid}');
      
      // Check if user already exists
      final userDoc = FirebaseConfig.firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        _logger.i('User document already exists, returning existing data');
        return domain.User.fromFirestore(docSnapshot);
      }
      
      final mobile = firebaseUser.phoneNumber?.substring(3) ?? '';
      final newUser = domain.User(
        userId: firebaseUser.uid,
        mobile: mobile,
        name: '',
        email: '',
        type: UserType.b2c,
        walletId: _generateWalletId(),
        createdAt: DateTime.now(),
        isKYCVerified: false,
        status: UserStatus.active,
        tier: UserTier.bronze,
        referralCode: _generateReferralCode(mobile),
      );
      
      // Save to Firestore using AuthRepository (now uses set() with merge)
      await _authRepository.updateUserProfile(newUser);
      
      // Create wallet for the user
      await _createWalletForUser(newUser.walletId, newUser.userId);
      
      _logger.i('✅ User data created successfully in Firestore');
      return newUser;
      
    } catch (e) {
      _logger.e('⛔ Failed to create user data in Firestore: $e');
      throw Exception('Failed to create user profile');
    }
  }

  /// Create wallet for new user
  Future<void> _createWalletForUser(String walletId, String userId) async {
    try {
      await FirebaseConfig.firestore.collection('wallets').doc(userId).set({
        'walletId': walletId,
        'userId': userId,
        'balance': 0.0,
        'outstandingBalance': 0.0,
        'totalAddedMoney': 0.0,
        'totalSpentMoney': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.i('Wallet created for user: $userId');
    } catch (e) {
      _logger.e('Failed to create wallet: $e');
      throw Exception('Failed to create wallet');
    }
  }

  /// Generate wallet ID
  String _generateWalletId() {
    return 'WLT${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate referral code
  String _generateReferralCode(String mobile) {
    return 'SP${mobile.substring(mobile.length - 4)}${DateTime.now().year}';
  }

  /// Update user profile with all registration data
  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String accountType,
    String? businessName,
    String? gstNumber,
    String? address,
    String? pincode,
    String? village,
    String? taluk,
    String? district,
    String? state,
    String? aadharNumber,
    String? panNumber,
    DateTime? dateOfBirth,
    String? firstName,
    String? lastName,
  }) async {
    try {
      if (_userData == null) {
        _setError('User data not available');
        return false;
      }
      
      _setLoading(true);
      
      // Update user data with all registration fields
      final updatedUser = domain.User(
        userId: _userData!.userId,
        mobile: _userData!.mobile,
        name: name,
        email: email,
        type: accountType == 'Business' ? UserType.b2b : UserType.b2c,
        walletId: _userData!.walletId,
        createdAt: _userData!.createdAt,
        isKYCVerified: aadharNumber != null && panNumber != null,
        status: _userData!.status,
        tier: _userData!.tier,
        profileImage: _userData!.profileImage,
        lastLoginAt: _userData!.lastLoginAt,
        isBiometricEnabled: _userData!.isBiometricEnabled,
        referralCode: _userData!.referralCode,
        referredBy: _userData!.referredBy,
        // Additional registration fields
        businessName: businessName,
        gstNumber: gstNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        pincode: pincode,
        village: village,
        taluk: taluk,
        district: district,
        state: state,
        aadharNumber: aadharNumber,
        panNumber: panNumber,
        firstName: firstName,
        lastName: lastName,
      );
      
      // Save to Firestore
      await _authRepository.updateUserProfile(updatedUser);
      
      // Update local data
      _userData = updatedUser;
      
      // Set user as fully authenticated after completing profile
      _authState = AuthState.authenticated;
      
      _logger.i('User profile updated successfully with all registration data');
      return true;
      
    } catch (e) {
      _logger.e('Failed to update user profile: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }
} 