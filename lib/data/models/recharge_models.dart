import 'package:json_annotation/json_annotation.dart';

part 'recharge_models.g.dart';

@JsonSerializable()
class RechargeRequest {
  final String mobileNumber;
  final String operatorCode;
  final String circleCode;
  final int amount;
  final String planDescription;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final DateTime requestTime;

  const RechargeRequest({
    required this.mobileNumber,
    required this.operatorCode,
    required this.circleCode,
    required this.amount,
    required this.planDescription,
    required this.paymentMethod,
    this.transactionId,
    required this.requestTime,
  });

  factory RechargeRequest.fromJson(Map<String, dynamic> json) => _$RechargeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RechargeRequestToJson(this);

  String get formattedAmount => '₹$amount';
  String get maskedMobileNumber => '${mobileNumber.substring(0, 2)}****${mobileNumber.substring(6)}';
}

@JsonSerializable()
class RechargeResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? operatorTransactionId;
  final DateTime timestamp;
  final RechargeStatus status;
  final RechargeRequest? request;

  const RechargeResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.operatorTransactionId,
    required this.timestamp,
    required this.status,
    this.request,
  });

  factory RechargeResult.fromJson(Map<String, dynamic> json) => _$RechargeResultFromJson(json);
  Map<String, dynamic> toJson() => _$RechargeResultToJson(this);

  factory RechargeResult.success({
    String? transactionId,
    String? operatorTransactionId,
    RechargeRequest? request,
  }) {
    return RechargeResult(
      success: true,
      message: 'Recharge completed successfully',
      transactionId: transactionId,
      operatorTransactionId: operatorTransactionId,
      timestamp: DateTime.now(),
      status: RechargeStatus.success,
      request: request,
    );
  }

  factory RechargeResult.failed({
    String? message,
    String? transactionId,
    RechargeRequest? request,
  }) {
    return RechargeResult(
      success: false,
      message: message ?? 'Recharge failed',
      transactionId: transactionId,
      timestamp: DateTime.now(),
      status: RechargeStatus.failed,
      request: request,
    );
  }

  factory RechargeResult.pending({
    String? transactionId,
    RechargeRequest? request,
  }) {
    return RechargeResult(
      success: false,
      message: 'Recharge is pending',
      transactionId: transactionId,
      timestamp: DateTime.now(),
      status: RechargeStatus.pending,
      request: request,
    );
  }
}

@JsonSerializable()
class Transaction {
  final String id;
  final String mobileNumber;
  final String operator;
  final String circle;
  final int amount;
  final String description;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final String? operatorTransactionId;
  final PaymentMethod paymentMethod;

  const Transaction({
    required this.id,
    required this.mobileNumber,
    required this.operator,
    required this.circle,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.status,
    this.operatorTransactionId,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  String get formattedAmount => '₹$amount';
  String get maskedMobileNumber => '${mobileNumber.substring(0, 2)}****${mobileNumber.substring(6)}';
  String get formattedDate => '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}

@JsonSerializable()
class PaymentResponse {
  final bool success;
  final String message;
  final String? paymentId;
  final String? orderId;
  final int amount;
  final PaymentMethod method;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  const PaymentResponse({
    required this.success,
    required this.message,
    this.paymentId,
    this.orderId,
    required this.amount,
    required this.method,
    required this.timestamp,
    this.additionalData,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) => _$PaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);

  String get formattedAmount => '₹$amount';
}

enum PaymentMethod {
  wallet,
  razorpay,
  phonepe,
  paytm,
  upi,
  netbanking,
  card,
}

enum RechargeStatus {
  pending,
  success,
  failed,
  cancelled,
}

enum TransactionType {
  recharge,
  walletTopup,
  refund,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
  refunded,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.razorpay:
        return 'Razorpay';
      case PaymentMethod.phonepe:
        return 'PhonePe';
      case PaymentMethod.paytm:
        return 'Paytm';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.netbanking:
        return 'Net Banking';
      case PaymentMethod.card:
        return 'Debit/Credit Card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.wallet:
        return '💰';
      case PaymentMethod.razorpay:
        return '💳';
      case PaymentMethod.phonepe:
        return '📱';
      case PaymentMethod.paytm:
        return '💙';
      case PaymentMethod.upi:
        return '🔄';
      case PaymentMethod.netbanking:
        return '🏦';
      case PaymentMethod.card:
        return '💳';
    }
  }

  bool get requiresExternalApp {
    return this == PaymentMethod.phonepe || 
           this == PaymentMethod.paytm || 
           this == PaymentMethod.upi;
  }
}

extension RechargeStatusExtension on RechargeStatus {
  String get displayName {
    switch (this) {
      case RechargeStatus.pending:
        return 'Pending';
      case RechargeStatus.success:
        return 'Success';
      case RechargeStatus.failed:
        return 'Failed';
      case RechargeStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case RechargeStatus.pending:
        return '⏳';
      case RechargeStatus.success:
        return '✅';
      case RechargeStatus.failed:
        return '❌';
      case RechargeStatus.cancelled:
        return '🚫';
    }
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  String get color {
    switch (this) {
      case TransactionStatus.pending:
        return '#FF9800'; // Orange
      case TransactionStatus.success:
        return '#4CAF50'; // Green
      case TransactionStatus.failed:
        return '#F44336'; // Red
      case TransactionStatus.cancelled:
        return '#9E9E9E'; // Grey
      case TransactionStatus.refunded:
        return '#2196F3'; // Blue
    }
  }
} 