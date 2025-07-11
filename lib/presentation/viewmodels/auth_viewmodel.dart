import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Temporarily disabled
// import '../../data/repositories/auth_repository.dart'; // Temporarily disabled
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user.dart' show UserType, UserStatus, UserTier;

enum AuthState { initial, loading, otpSent, authenticated, error }

class AuthViewModel extends ChangeNotifier {
  // final AuthRepository _authRepository = AuthRepository(); // Temporarily disabled
  
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String? _verificationId;
  domain.User? _user;
  
  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  domain.User? get user => _user;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // Initialize auth listener
  void initialize() {
    // Temporarily disabled Firebase auth
    // _authRepository.authStateChanges.listen((User? firebaseUser) async {
    //   if (firebaseUser != null) {
    //     _user = await _authRepository.getUserData(firebaseUser.uid);
    //     _state = AuthState.authenticated;
    //   } else {
    //     _user = null;
    //     _state = AuthState.initial;
    //   }
    //   notifyListeners();
    // });
  }

  // Send OTP for login/registration
  Future<void> sendOTP(String mobile) async {
    _setState(AuthState.loading);
    
    // Simulate OTP sending for demo
    await Future.delayed(Duration(seconds: 2));
    _verificationId = 'demo_verification_id';
    _setState(AuthState.otpSent);
    
    // await _authRepository.sendOTP(
    //   mobile,
    //   onCodeSent: (verificationId) {
    //     _verificationId = verificationId;
    //     _setState(AuthState.otpSent);
    //   },
    //   onError: (error) {
    //     _setError(error);
    //   },
    //   onCompleted: () {
    //     _setState(AuthState.authenticated);
    //   },
    // );
  }

  // Verify OTP
  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _setError('Verification ID not found');
      return;
    }

    _setState(AuthState.loading);

    // Simulate OTP verification for demo
    await Future.delayed(Duration(seconds: 2));
    
    if (otp == '123456') {
      // Create demo user
      _user = domain.User(
        userId: 'demo_user_123',
        mobile: '9999999999',
        name: 'Demo User',
        email: 'demo@samypay.com',
        type: UserType.b2c,
        walletId: 'wallet_123',
        createdAt: DateTime.now(),
        isKYCVerified: true,
        status: UserStatus.active,
        tier: UserTier.silver,
        lastLoginAt: DateTime.now(),
        isBiometricEnabled: false,
        referralCode: 'DEMO123',
      );
      _setState(AuthState.authenticated);
    } else {
      _setError('Invalid OTP. Use 123456 for demo');
    }

    // try {
    //   _user = await _authRepository.verifyOTP(_verificationId!, otp);
    //   if (_user != null) {
    //     _setState(AuthState.authenticated);
    //   } else {
    //     _setError('OTP verification failed');
    //   }
    // } catch (e) {
    //   _setError(e.toString());
    // }
  }

  // Update user profile
  Future<void> updateProfile({
    required String name,
    required String email,
    String? profileImage,
  }) async {
    if (_user == null) return;

    try {
      final updatedUser = domain.User(
        userId: _user!.userId,
        mobile: _user!.mobile,
        name: name,
        email: email,
        type: _user!.type,
        walletId: _user!.walletId,
        createdAt: _user!.createdAt,
        isKYCVerified: _user!.isKYCVerified,
        status: _user!.status,
        tier: _user!.tier,
        profileImage: profileImage ?? _user!.profileImage,
        lastLoginAt: _user!.lastLoginAt,
        isBiometricEnabled: _user!.isBiometricEnabled,
        referralCode: _user!.referralCode,
        referredBy: _user!.referredBy,
      );

      // await _authRepository.updateUserProfile(updatedUser); // Temporarily disabled
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    }
  }

  // Submit KYC
  Future<void> submitKYC({
    required String aadharNumber,
    required String panNumber,
    required String fullName,
    required String address,
  }) async {
    if (_user == null) return;

    try {
      // await _authRepository.submitKYC( // Temporarily disabled
      /*
        userId: _user!.userId,
        aadharNumber: aadharNumber,
        panNumber: panNumber,
        fullName: fullName,
        address: address,
      );
      */
      
      // Update local user status
      final updatedUser = domain.User(
        userId: _user!.userId,
        mobile: _user!.mobile,
        name: _user!.name,
        email: _user!.email,
        type: _user!.type,
        walletId: _user!.walletId,
        createdAt: _user!.createdAt,
        isKYCVerified: false, // Will be verified by admin
        status: UserStatus.pending_verification,
        tier: _user!.tier,
        profileImage: _user!.profileImage,
        lastLoginAt: _user!.lastLoginAt,
        isBiometricEnabled: _user!.isBiometricEnabled,
        referralCode: _user!.referralCode,
        referredBy: _user!.referredBy,
      );

      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('KYC submission failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // await _authRepository.signOut(); // Temporarily disabled
      _user = null;
      _state = AuthState.initial;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    }
  }

  // Helper methods
  void _setState(AuthState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.initial;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 