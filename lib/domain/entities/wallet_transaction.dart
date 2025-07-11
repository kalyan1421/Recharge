import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTransactionType {
  credit,
  debit,
  refund,
  bonus,
  cashback,
  transfer,
  recharge,
  payment,
  withdrawal,
  commission,
}

enum WalletTransactionStatus {
  pending,
  success,
  failed,
  cancelled,
  refunded,
}

class WalletTransaction {
  final String id;
  final String transactionId;
  final String userId;
  final double amount;
  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final String description;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double balanceAfter;
  final double balanceBefore;
  final String? reference;
  final String? gateway;
  final String? gatewayTransactionId;
  final Map<String, dynamic>? metadata;

  const WalletTransaction({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.balanceAfter,
    required this.balanceBefore,
    this.reference,
    this.gateway,
    this.gatewayTransactionId,
    this.metadata,
  });

  /// Create WalletTransaction from Firestore document
  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return WalletTransaction(
      id: doc.id,
      transactionId: data['transactionId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: WalletTransactionType.values.firstWhere(
        (e) => e.toString() == 'WalletTransactionType.${data['type']}',
        orElse: () => WalletTransactionType.debit,
      ),
      status: WalletTransactionStatus.values.firstWhere(
        (e) => e.toString() == 'WalletTransactionStatus.${data['status']}',
        orElse: () => WalletTransactionStatus.pending,
      ),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      balanceAfter: (data['balanceAfter'] ?? 0).toDouble(),
      balanceBefore: (data['balanceBefore'] ?? 0).toDouble(),
      reference: data['reference'],
      gateway: data['gateway'],
      gatewayTransactionId: data['gatewayTransactionId'],
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'balanceAfter': balanceAfter,
      'balanceBefore': balanceBefore,
      'reference': reference,
      'gateway': gateway,
      'gatewayTransactionId': gatewayTransactionId,
      'metadata': metadata,
    };
  }

  /// Copy with new values
  WalletTransaction copyWith({
    String? id,
    String? transactionId,
    String? userId,
    double? amount,
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    String? description,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? balanceAfter,
    double? balanceBefore,
    String? reference,
    String? gateway,
    String? gatewayTransactionId,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      reference: reference ?? this.reference,
      gateway: gateway ?? this.gateway,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted amount string
  String get formattedAmount {
    final prefix = type == WalletTransactionType.credit ? '+' : '-';
    return '$prefix₹${amount.toStringAsFixed(2)}';
  }

  /// Get transaction type display name
  String get typeDisplayName {
    switch (type) {
      case WalletTransactionType.credit:
        return 'Credit';
      case WalletTransactionType.debit:
        return 'Debit';
      case WalletTransactionType.refund:
        return 'Refund';
      case WalletTransactionType.bonus:
        return 'Bonus';
      case WalletTransactionType.cashback:
        return 'Cashback';
      case WalletTransactionType.transfer:
        return 'Transfer';
      case WalletTransactionType.recharge:
        return 'Recharge';
      case WalletTransactionType.payment:
        return 'Payment';
      case WalletTransactionType.withdrawal:
        return 'Withdrawal';
      case WalletTransactionType.commission:
        return 'Commission';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case WalletTransactionStatus.pending:
        return 'Pending';
      case WalletTransactionStatus.success:
        return 'Success';
      case WalletTransactionStatus.failed:
        return 'Failed';
      case WalletTransactionStatus.cancelled:
        return 'Cancelled';
      case WalletTransactionStatus.refunded:
        return 'Refunded';
    }
  }

  /// Check if transaction is successful
  bool get isSuccess => status == WalletTransactionStatus.success;

  /// Check if transaction is pending
  bool get isPending => status == WalletTransactionStatus.pending;

  /// Check if transaction is failed
  bool get isFailed => status == WalletTransactionStatus.failed;

  @override
  String toString() {
    return 'WalletTransaction(id: $id, transactionId: $transactionId, amount: $amount, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction &&
        other.id == id &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode => id.hashCode ^ transactionId.hashCode;
} 