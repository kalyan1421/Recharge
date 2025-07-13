import 'package:json_annotation/json_annotation.dart';

part 'wallet_models.g.dart';

@JsonSerializable()
class WalletDeductionResult {
  final bool success;
  final String transactionId;
  final double previousBalance;
  final double newBalance;
  final double deductedAmount;
  final DateTime timestamp;
  
  WalletDeductionResult({
    required this.success,
    required this.transactionId,
    required this.previousBalance,
    required this.newBalance,
    required this.deductedAmount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WalletDeductionResult.fromJson(Map<String, dynamic> json) =>
      _$WalletDeductionResultFromJson(json);

  Map<String, dynamic> toJson() => _$WalletDeductionResultToJson(this);
}

@JsonSerializable()
class WalletTransaction {
  final String transactionId;
  final String userId;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String purpose;
  final String status; // 'pending', 'completed', 'failed'
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? originalTransactionId; // For refunds
  final Map<String, dynamic>? rechargeResponse; // Store recharge API response
  
  WalletTransaction({
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.purpose,
    required this.status,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    required this.updatedAt,
    this.originalTransactionId,
    this.rechargeResponse,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);
}

@JsonSerializable()
class WalletBalanceResponse {
  final String errorcode;
  final int status;
  final String message;
  final String? type;
  final double? buyerWalletBalance;
  final double? sellerWalletBalance;
  
  WalletBalanceResponse({
    required this.errorcode,
    required this.status,
    required this.message,
    this.type,
    this.buyerWalletBalance,
    this.sellerWalletBalance,
  });

  bool get isSuccess => errorcode == '0' && status == 1;
  bool get hasError => errorcode != '0' || status != 1;

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletBalanceResponseToJson(this);
}

@JsonSerializable()
class RechargeResult {
  final bool success;
  final String transactionId;
  final String message;
  final String? operatorTransactionId;
  final String status; // 'SUCCESS', 'PROCESSING', 'FAILED'
  final double? amount;
  final String? mobileNumber;
  final DateTime timestamp;
  
  RechargeResult({
    required this.success,
    required this.transactionId,
    required this.message,
    this.operatorTransactionId,
    required this.status,
    this.amount,
    this.mobileNumber,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RechargeResult.fromJson(Map<String, dynamic> json) =>
      _$RechargeResultFromJson(json);

  Map<String, dynamic> toJson() => _$RechargeResultToJson(this);
}

// Custom Exceptions
class InsufficientBalanceException implements Exception {
  final String message;
  final double availableBalance;
  final double requiredAmount;
  
  InsufficientBalanceException({
    required this.message,
    required this.availableBalance,
    required this.requiredAmount,
  });
  
  @override
  String toString() => 'InsufficientBalanceException: $message';
}

class InsufficientApiBalanceException implements Exception {
  final String message;
  final double? availableBalance;
  final double requiredAmount;
  
  InsufficientApiBalanceException({
    required this.message,
    this.availableBalance,
    required this.requiredAmount,
  });
  
  @override
  String toString() => 'InsufficientApiBalanceException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String? field;
  
  ValidationException(this.message, {this.field});
  
  @override
  String toString() => 'ValidationException: $message';
}

class RechargeException implements Exception {
  final String message;
  final String? errorCode;
  final String? transactionId;
  
  RechargeException(this.message, {this.errorCode, this.transactionId});
  
  @override
  String toString() => 'RechargeException: $message';
}

class WalletServiceException implements Exception {
  final String message;
  final String? operation;
  
  WalletServiceException(this.message, {this.operation});
  
  @override
  String toString() => 'WalletServiceException: $message';
} 