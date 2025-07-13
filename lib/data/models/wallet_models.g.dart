// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletDeductionResult _$WalletDeductionResultFromJson(
        Map<String, dynamic> json) =>
    WalletDeductionResult(
      success: json['success'] as bool,
      transactionId: json['transactionId'] as String,
      previousBalance: (json['previousBalance'] as num).toDouble(),
      newBalance: (json['newBalance'] as num).toDouble(),
      deductedAmount: (json['deductedAmount'] as num).toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$WalletDeductionResultToJson(
        WalletDeductionResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'transactionId': instance.transactionId,
      'previousBalance': instance.previousBalance,
      'newBalance': instance.newBalance,
      'deductedAmount': instance.deductedAmount,
      'timestamp': instance.timestamp.toIso8601String(),
    };

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      transactionId: json['transactionId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      purpose: json['purpose'] as String,
      status: json['status'] as String,
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      originalTransactionId: json['originalTransactionId'] as String?,
      rechargeResponse: json['rechargeResponse'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'userId': instance.userId,
      'amount': instance.amount,
      'type': instance.type,
      'purpose': instance.purpose,
      'status': instance.status,
      'balanceBefore': instance.balanceBefore,
      'balanceAfter': instance.balanceAfter,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'originalTransactionId': instance.originalTransactionId,
      'rechargeResponse': instance.rechargeResponse,
    };

WalletBalanceResponse _$WalletBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    WalletBalanceResponse(
      errorcode: json['errorcode'] as String,
      status: (json['status'] as num).toInt(),
      message: json['message'] as String,
      type: json['type'] as String?,
      buyerWalletBalance: (json['buyerWalletBalance'] as num?)?.toDouble(),
      sellerWalletBalance: (json['sellerWalletBalance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WalletBalanceResponseToJson(
        WalletBalanceResponse instance) =>
    <String, dynamic>{
      'errorcode': instance.errorcode,
      'status': instance.status,
      'message': instance.message,
      'type': instance.type,
      'buyerWalletBalance': instance.buyerWalletBalance,
      'sellerWalletBalance': instance.sellerWalletBalance,
    };

RechargeResult _$RechargeResultFromJson(Map<String, dynamic> json) =>
    RechargeResult(
      success: json['success'] as bool,
      transactionId: json['transactionId'] as String,
      message: json['message'] as String,
      operatorTransactionId: json['operatorTransactionId'] as String?,
      status: json['status'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      mobileNumber: json['mobileNumber'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$RechargeResultToJson(RechargeResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'transactionId': instance.transactionId,
      'message': instance.message,
      'operatorTransactionId': instance.operatorTransactionId,
      'status': instance.status,
      'amount': instance.amount,
      'mobileNumber': instance.mobileNumber,
      'timestamp': instance.timestamp.toIso8601String(),
    };
