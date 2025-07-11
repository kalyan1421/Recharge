import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../config/firebase_config.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user.dart' show UserType, UserStatus, UserTier;

enum UserState { loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AuthRepository _authRepository = AuthRepository();
  
  // State variables
  UserState _state = UserState.loading;
  domain.User? _user;
  String _errorMessage = '';
  bool _isLoading = false;
  
  // Getters
  UserState get state => _state;
  domain.User? get user => _user;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String get userId => _user?.userId ?? '';
  String get userName => _user?.name ?? '';
  String get userEmail => _user?.email ?? '';
  String get userMobile => _user?.mobile ?? '';
  String get userWalletId => _user?.walletId ?? '';
  bool get isKYCVerified => _user?.isKYCVerified ?? false;
  String get userTier => _user?.tier.toString().split('.').last ?? 'bronze';
  String get referralCode => _user?.referralCode ?? '';
  
  UserProvider() {
    _initializeUser();
  }
  
  /// Initialize user data
  void _initializeUser() {
    final currentUser = FirebaseConfig.currentUser;
    if (currentUser != null) {
      loadUserData(currentUser.uid);
    }
  }
  
  /// Load user data from Firestore
  Future<void> loadUserData(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _logger.i('Loading user data for: $userId');
      
      _user = await _authRepository.getUserData(userId);
      
      if (_user != null) {
        _state = UserState.loaded;
        _logger.i('User data loaded successfully');
      } else {
        _state = UserState.error;
        _setError('User data not found');
      }
      
    } catch (e, stackTrace) {
      _logger.e('Failed to load user data: $e');
      _setError('Failed to load user data');
      _state = UserState.error;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profileImage,
    UserType? type,
  }) async {
    try {
      if (_user == null) {
        _setError('User data not available');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Create updated user
      final updatedUser = domain.User(
        userId: _user!.userId,
        mobile: _user!.mobile,
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        type: type ?? _user!.type,
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
      
      // Save to Firestore
      await _authRepository.updateUserProfile(updatedUser);
      
      // Update local data
      _user = updatedUser;
      _state = UserState.loaded;
      
      _logger.i('User profile updated successfully');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to update user profile: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Submit KYC documents
  Future<bool> submitKYC({
    required String aadharNumber,
    required String panNumber,
    required String fullName,
    required String address,
  }) async {
    try {
      if (_user == null) {
        _setError('User data not available');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      await _authRepository.submitKYC(
        userId: _user!.userId,
        aadharNumber: aadharNumber,
        panNumber: panNumber,
        fullName: fullName,
        address: address,
      );
      
      // Update local user status to pending verification
      final updatedUser = domain.User(
        userId: _user!.userId,
        mobile: _user!.mobile,
        name: _user!.name,
        email: _user!.email,
        type: _user!.type,
        walletId: _user!.walletId,
        createdAt: _user!.createdAt,
        isKYCVerified: false,
        status: UserStatus.pending_verification,
        tier: _user!.tier,
        profileImage: _user!.profileImage,
        lastLoginAt: _user!.lastLoginAt,
        isBiometricEnabled: _user!.isBiometricEnabled,
        referralCode: _user!.referralCode,
        referredBy: _user!.referredBy,
      );
      
      _user = updatedUser;
      _logger.i('KYC submitted successfully');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to submit KYC: $e');
      _setError('Failed to submit KYC documents');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Refresh user data
  Future<void> refresh() async {
    if (_user != null) {
      await loadUserData(_user!.userId);
    }
  }
  
  /// Stream user data changes
  Stream<domain.User?> get userStream {
    if (_user != null) {
      return FirebaseConfig.firestore
          .collection('users')
          .doc(_user!.userId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          final userData = _userFromMap(doc.data()!);
          _user = userData;
          notifyListeners();
          return userData;
        }
        return null;
      });
    }
    return Stream.value(null);
  }
  
  /// Subscribe to user data changes
  void subscribeToUserChanges() {
    if (_user != null) {
      FirebaseConfig.firestore
          .collection('users')
          .doc(_user!.userId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          _user = _userFromMap(doc.data()!);
          _state = UserState.loaded;
          notifyListeners();
        }
      }, onError: (error) {
        _logger.e('User stream error: $error');
        _setError('Failed to sync user data');
      });
    }
  }
  
  /// Convert Firestore map to User object
  domain.User _userFromMap(Map<String, dynamic> map) {
    return domain.User(
      userId: map['userId'] ?? '',
      mobile: map['mobile'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      type: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['type']}',
        orElse: () => UserType.b2c,
      ),
      walletId: map['walletId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isKYCVerified: map['isKYCVerified'] ?? false,
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == 'UserStatus.${map['status']}',
        orElse: () => UserStatus.active,
      ),
      tier: UserTier.values.firstWhere(
        (e) => e.toString() == 'UserTier.${map['tier']}',
        orElse: () => UserTier.bronze,
      ),
      profileImage: map['profileImage'],
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
      isBiometricEnabled: map['isBiometricEnabled'] ?? false,
      referralCode: map['referralCode'],
      referredBy: map['referredBy'],
    );
  }
  
  /// Clear user data (on logout)
  void clearUserData() {
    _user = null;
    _state = UserState.loading;
    _clearError();
    notifyListeners();
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
} 