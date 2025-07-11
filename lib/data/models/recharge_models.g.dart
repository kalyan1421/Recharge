// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recharge_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RechargeRequest _$RechargeRequestFromJson(Map<String, dynamic> json) =>
    RechargeRequest(
      mobileNumber: json['mobileNumber'] as String,
      operatorCode: json['operatorCode'] as String,
      circleCode: json['circleCode'] as String,
      amount: (json['amount'] as num).toInt(),
      planDescription: json['planDescription'] as String,
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
      transactionId: json['transactionId'] as String?,
      requestTime: DateTime.parse(json['requestTime'] as String),
    );

Map<String, dynamic> _$RechargeRequestToJson(RechargeRequest instance) =>
    <String, dynamic>{
      'mobileNumber': instance.mobileNumber,
      'operatorCode': instance.operatorCode,
      'circleCode': instance.circleCode,
      'amount': instance.amount,
      'planDescription': instance.planDescription,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'transactionId': instance.transactionId,
      'requestTime': instance.requestTime.toIso8601String(),
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.razorpay: 'razorpay',
  PaymentMethod.phonepe: 'phonepe',
  PaymentMethod.paytm: 'paytm',
  PaymentMethod.upi: 'upi',
  PaymentMethod.netbanking: 'netbanking',
  PaymentMethod.card: 'card',
};

RechargeResult _$RechargeResultFromJson(Map<String, dynamic> json) =>
    RechargeResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      transactionId: json['transactionId'] as String?,
      operatorTransactionId: json['operatorTransactionId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: $enumDecode(_$RechargeStatusEnumMap, json['status']),
      request: json['request'] == null
          ? null
          : RechargeRequest.fromJson(json['request'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RechargeResultToJson(RechargeResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'transactionId': instance.transactionId,
      'operatorTransactionId': instance.operatorTransactionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': _$RechargeStatusEnumMap[instance.status]!,
      'request': instance.request,
    };

const _$RechargeStatusEnumMap = {
  RechargeStatus.pending: 'pending',
  RechargeStatus.success: 'success',
  RechargeStatus.failed: 'failed',
  RechargeStatus.cancelled: 'cancelled',
};

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      mobileNumber: json['mobileNumber'] as String,
      operator: json['operator'] as String,
      circle: json['circle'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      status: $enumDecode(_$TransactionStatusEnumMap, json['status']),
      operatorTransactionId: json['operatorTransactionId'] as String?,
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mobileNumber': instance.mobileNumber,
      'operator': instance.operator,
      'circle': instance.circle,
      'amount': instance.amount,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'operatorTransactionId': instance.operatorTransactionId,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.recharge: 'recharge',
  TransactionType.walletTopup: 'walletTopup',
  TransactionType.refund: 'refund',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.success: 'success',
  TransactionStatus.failed: 'failed',
  TransactionStatus.cancelled: 'cancelled',
  TransactionStatus.refunded: 'refunded',
};

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    PaymentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      paymentId: json['paymentId'] as String?,
      orderId: json['orderId'] as String?,
      amount: (json['amount'] as num).toInt(),
      method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'paymentId': instance.paymentId,
      'orderId': instance.orderId,
      'amount': instance.amount,
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'additionalData': instance.additionalData,
    };
