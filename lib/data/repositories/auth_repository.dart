import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user.dart' show UserType, UserStatus, UserTier;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Send OTP for login/registration
  Future<void> sendOTP(String mobile, {
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$mobile',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
          onCompleted();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP and sign in
  Future<domain.User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return await _createOrUpdateUser(userCredential.user!);
      }
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
    return null;
  }

  // Create or update user in Firestore
  Future<domain.User> _createOrUpdateUser(User firebaseUser) async {
    final mobile = firebaseUser.phoneNumber?.substring(3) ?? '';
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      // Create new user
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

      await userDoc.set(_userToMap(newUser));
      await _createWallet(newUser.walletId, newUser.userId);
      
      return newUser;
    } else {
      // Update existing user
      final userData = docSnapshot.data()!;
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      return _userFromMap(userData);
    }
  }

  // Create wallet for new user
  Future<void> _createWallet(String walletId, String userId) async {
    await _firestore.collection('wallets').doc(userId).set({
      'walletId': walletId,
      'userId': userId,
      'balance': 0.0,
      'blockedAmount': 0.0,
      'minBalance': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
      'status': 'active',
      'dailyLimit': 25000.0,
      'monthlyLimit': 200000.0,
      'dailyUsed': 0.0,
      'monthlyUsed': 0.0,
      'isAutoRechargeEnabled': false,
      'autoRechargeThreshold': 50.0,
    });
  }

  // Sign in with credential
  Future<UserCredential> _signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data
  Future<domain.User?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return _userFromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Update user profile (works for both creating and updating)
  Future<void> updateUserProfile(domain.User user) async {
    await _firestore.collection('users').doc(user.userId).set(
      _userToMap(user), 
      SetOptions(merge: true) // This will merge with existing data or create new document
    );
  }

  // KYC verification
  Future<void> submitKYC({
    required String userId,
    required String aadharNumber,
    required String panNumber,
    required String fullName,
    required String address,
  }) async {
    await _firestore.collection('kyc_requests').add({
      'userId': userId,
      'aadharNumber': _hashSensitiveData(aadharNumber),
      'panNumber': _hashSensitiveData(panNumber),
      'fullName': fullName,
      'address': address,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Update user status
    await _firestore.collection('users').doc(userId).update({
      'status': 'pending_verification',
    });
  }

  // Helper methods
  String _generateWalletId() {
    return 'WLT${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateReferralCode(String mobile) {
    return 'SP${mobile.substring(mobile.length - 4)}${DateTime.now().year}';
  }

  String _hashSensitiveData(String data) {
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  domain.User _userFromMap(Map<String, dynamic> map) {
    // Create a mock document snapshot to use the fromFirestore factory
    final doc = _MockDocumentSnapshot(map['userId'] ?? '', map);
    return domain.User.fromFirestore(doc);
  }

  Map<String, dynamic> _userToMap(domain.User user) {
    return user.toFirestore();
  }
}

class _MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  get(Object field) => throw UnimplementedError();

  @override
  operator [](Object field) => throw UnimplementedError();
} 