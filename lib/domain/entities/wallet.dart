import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase-only wallet entity
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double totalAdded;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.totalAdded = 0.0,
    this.totalSpent = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  /// Create wallet from Firestore document
  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Wallet(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      totalAdded: (data['totalAdded'] ?? 0.0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'totalAdded': totalAdded,
      'totalSpent': totalSpent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Copy with new values
  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    double? totalAdded,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalAdded: totalAdded ?? this.totalAdded,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get available balance
  double get availableBalance => balance;

  /// Check if wallet has sufficient balance
  bool hasSufficientBalance(double amount) => balance >= amount;

  /// Get formatted balance string
  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'totalAdded': totalAdded,
      'totalSpent': totalSpent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      totalAdded: (json['totalAdded'] ?? 0.0).toDouble(),
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'] ?? {},
    );
  }
} 