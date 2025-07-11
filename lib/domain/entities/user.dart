import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserType { b2c, b2b }
enum UserStatus { active, inactive, pending_verification, suspended }
enum UserTier { bronze, silver, gold, platinum }

class User extends Equatable {
  final String userId;
  final String mobile;
  final String name;
  final String email;
  final UserType type;
  final String walletId;
  final DateTime createdAt;
  final bool isKYCVerified;
  final UserStatus status;
  final UserTier tier;
  final String? profileImage;
  final DateTime? lastLoginAt;
  final bool isBiometricEnabled;
  final String? referralCode;
  final String? referredBy;
  
  // Additional registration fields
  final String? businessName;
  final String? gstNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final String? pincode;
  final String? village;
  final String? taluk;
  final String? district;
  final String? state;
  final String? aadharNumber;
  final String? panNumber;
  final String? firstName;
  final String? lastName;

  const User({
    required this.userId,
    required this.mobile,
    required this.name,
    required this.email,
    required this.type,
    required this.walletId,
    required this.createdAt,
    required this.isKYCVerified,
    required this.status,
    required this.tier,
    this.profileImage,
    this.lastLoginAt,
    this.isBiometricEnabled = false,
    this.referralCode,
    this.referredBy,
    // Additional registration fields
    this.businessName,
    this.gstNumber,
    this.dateOfBirth,
    this.address,
    this.pincode,
    this.village,
    this.taluk,
    this.district,
    this.state,
    this.aadharNumber,
    this.panNumber,
    this.firstName,
    this.lastName,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return User(
      userId: doc.id,
      mobile: data['mobile'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      type: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${data['type']}',
        orElse: () => UserType.b2c,
      ),
      walletId: data['walletId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isKYCVerified: data['isKYCVerified'] ?? false,
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == 'UserStatus.${data['status']}',
        orElse: () => UserStatus.active,
      ),
      tier: UserTier.values.firstWhere(
        (e) => e.toString() == 'UserTier.${data['tier']}',
        orElse: () => UserTier.bronze,
      ),
      profileImage: data['profileImage'],
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isBiometricEnabled: data['isBiometricEnabled'] ?? false,
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
      // Additional registration fields
      businessName: data['businessName'],
      gstNumber: data['gstNumber'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      address: data['address'],
      pincode: data['pincode'],
      village: data['village'],
      taluk: data['taluk'],
      district: data['district'],
      state: data['state'],
      aadharNumber: data['aadharNumber'],
      panNumber: data['panNumber'],
      firstName: data['firstName'],
      lastName: data['lastName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mobile': mobile,
      'name': name,
      'email': email,
      'type': type.toString().split('.').last,
      'walletId': walletId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isKYCVerified': isKYCVerified,
      'status': status.toString().split('.').last,
      'tier': tier.toString().split('.').last,
      'profileImage': profileImage,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isBiometricEnabled': isBiometricEnabled,
      'referralCode': referralCode,
      'referredBy': referredBy,
      // Additional registration fields
      'businessName': businessName,
      'gstNumber': gstNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'address': address,
      'pincode': pincode,
      'village': village,
      'taluk': taluk,
      'district': district,
      'state': state,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  User copyWith({
    String? userId,
    String? mobile,
    String? name,
    String? email,
    UserType? type,
    String? walletId,
    DateTime? createdAt,
    bool? isKYCVerified,
    UserStatus? status,
    UserTier? tier,
    String? profileImage,
    DateTime? lastLoginAt,
    bool? isBiometricEnabled,
    String? referralCode,
    String? referredBy,
    String? businessName,
    String? gstNumber,
    DateTime? dateOfBirth,
    String? address,
    String? pincode,
    String? village,
    String? taluk,
    String? district,
    String? state,
    String? aadharNumber,
    String? panNumber,
    String? firstName,
    String? lastName,
  }) {
    return User(
      userId: userId ?? this.userId,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      createdAt: createdAt ?? this.createdAt,
      isKYCVerified: isKYCVerified ?? this.isKYCVerified,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      profileImage: profileImage ?? this.profileImage,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      businessName: businessName ?? this.businessName,
      gstNumber: gstNumber ?? this.gstNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      village: village ?? this.village,
      taluk: taluk ?? this.taluk,
      district: district ?? this.district,
      state: state ?? this.state,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      panNumber: panNumber ?? this.panNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        mobile,
        name,
        email,
        type,
        walletId,
        createdAt,
        isKYCVerified,
        status,
        tier,
        profileImage,
        lastLoginAt,
        isBiometricEnabled,
        referralCode,
        referredBy,
        businessName,
        gstNumber,
        dateOfBirth,
        address,
        pincode,
        village,
        taluk,
        district,
        state,
        aadharNumber,
        panNumber,
        firstName,
        lastName,
      ];

  @override
  String toString() {
    return 'User(userId: $userId, mobile: $mobile, name: $name, email: $email, type: $type, tier: $tier, status: $status)';
  }
} 