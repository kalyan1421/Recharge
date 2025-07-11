enum UserTier { basic, silver, gold, platinum }
enum KYCStatus { pending, verified, rejected }
enum PaymentMethod { upi, card, netbanking, wallet }

class User {
  final String userId;
  final String phoneNumber;
  final String? email;
  final String? name;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final UserTier tier;
  final KYCStatus kycStatus;
  final String? referralCode;
  final String? referredBy;
  final Map<String, dynamic> metadata;

  const User({
    required this.userId,
    required this.phoneNumber,
    this.email,
    this.name,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.tier = UserTier.basic,
    this.kycStatus = KYCStatus.pending,
    this.referralCode,
    this.referredBy,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'tier': tier.toString().split('.').last,
      'kycStatus': kycStatus.toString().split('.').last,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'metadata': metadata,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      isActive: json['isActive'] ?? true,
      tier: UserTier.values.firstWhere(
        (e) => e.toString() == 'UserTier.${json['tier']}',
        orElse: () => UserTier.basic,
      ),
      kycStatus: KYCStatus.values.firstWhere(
        (e) => e.toString() == 'KYCStatus.${json['kycStatus']}',
        orElse: () => KYCStatus.pending,
      ),
      referralCode: json['referralCode'],
      referredBy: json['referredBy'],
      metadata: json['metadata'] ?? {},
    );
  }
}

class Wallet {
  final String id;
  final String walletId;
  final String userId;
  final double balance;
  final double blockedAmount;
  final double minBalance;
  final double dailyLimit;
  final double monthlyLimit;
  final double dailyUsed;
  final double monthlyUsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Wallet({
    String? id,
    required this.walletId,
    required this.userId,
    required this.balance,
    this.blockedAmount = 0.0,
    this.minBalance = 10.0,
    this.dailyLimit = 5000.0,
    this.monthlyLimit = 50000.0,
    this.dailyUsed = 0.0,
    this.monthlyUsed = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  }) : id = id ?? walletId;

  /// Copy with new values
  Wallet copyWith({
    String? id,
    String? walletId,
    String? userId,
    double? balance,
    double? blockedAmount,
    double? minBalance,
    double? dailyLimit,
    double? monthlyLimit,
    double? dailyUsed,
    double? monthlyUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      blockedAmount: blockedAmount ?? this.blockedAmount,
      minBalance: minBalance ?? this.minBalance,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      dailyUsed: dailyUsed ?? this.dailyUsed,
      monthlyUsed: monthlyUsed ?? this.monthlyUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'balance': balance,
      'blockedAmount': blockedAmount,
      'minBalance': minBalance,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'dailyUsed': dailyUsed,
      'monthlyUsed': monthlyUsed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      walletId: json['walletId'] ?? '',
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      blockedAmount: (json['blockedAmount'] ?? 0.0).toDouble(),
      minBalance: (json['minBalance'] ?? 10.0).toDouble(),
      dailyLimit: (json['dailyLimit'] ?? 5000.0).toDouble(),
      monthlyLimit: (json['monthlyLimit'] ?? 50000.0).toDouble(),
      dailyUsed: (json['dailyUsed'] ?? 0.0).toDouble(),
      monthlyUsed: (json['monthlyUsed'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }
} 