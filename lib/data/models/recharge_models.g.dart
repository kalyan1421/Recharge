// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recharge_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RechargeRequest _$RechargeRequestFromJson(Map<String, dynamic> json) =>
    RechargeRequest(
      mobileNumber: json['mobileNumber'] as String,
      operatorCode: json['operatorCode'] as String,
      amount: json['amount'] as String,
      circle: json['circle'] as String,
      memberRequestTxnId: json['memberRequestTxnId'] as String,
      groupId: json['groupId'] as String?,
    );

Map<String, dynamic> _$RechargeRequestToJson(RechargeRequest instance) =>
    <String, dynamic>{
      'mobileNumber': instance.mobileNumber,
      'operatorCode': instance.operatorCode,
      'amount': instance.amount,
      'circle': instance.circle,
      'memberRequestTxnId': instance.memberRequestTxnId,
      'groupId': instance.groupId,
    };

RechargeResponse _$RechargeResponseFromJson(Map<String, dynamic> json) =>
    RechargeResponse(
      error: json['ERROR'] as String,
      status: (json['STATUS'] as num).toInt(),
      orderId: json['ORDERID'] as String,
      opTransId: json['OPTRANSID'] as String?,
      memberReqId: json['MEMBERREQID'] as String,
      message: json['MESSAGE'] as String,
      commission: json['COMMISSION'] as String?,
      mobileNo: json['MOBILENO'] as String?,
      amount: json['AMOUNT'] as String?,
      lapuNo: json['LAPUNO'] as String?,
      openingBal: json['OPNINGBAL'] as String?,
      closingBal: json['CLOSINGBAL'] as String?,
    );

Map<String, dynamic> _$RechargeResponseToJson(RechargeResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'ORDERID': instance.orderId,
      'OPTRANSID': instance.opTransId,
      'MEMBERREQID': instance.memberReqId,
      'MESSAGE': instance.message,
      'COMMISSION': instance.commission,
      'MOBILENO': instance.mobileNo,
      'AMOUNT': instance.amount,
      'LAPUNO': instance.lapuNo,
      'OPNINGBAL': instance.openingBal,
      'CLOSINGBAL': instance.closingBal,
    };

StatusCheckResponse _$StatusCheckResponseFromJson(Map<String, dynamic> json) =>
    StatusCheckResponse(
      error: json['ERROR'] as String,
      status: (json['STATUS'] as num).toInt(),
      orderId: json['ORDERID'] as String,
      opTransId: json['OPTRANSID'] as String,
      memberReqId: json['MEMBERREQID'] as String,
      message: json['MESSAGE'] as String,
      commission: json['COMMISSION'] as String?,
      mobileNo: json['MOBILENO'] as String,
      amount: json['AMOUNT'] as String,
      lapuNo: json['LAPUNO'] as String,
      openingBal: json['OPNINGBAL'] as String,
      closingBal: json['CLOSINGBAL'] as String,
    );

Map<String, dynamic> _$StatusCheckResponseToJson(
        StatusCheckResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'ORDERID': instance.orderId,
      'OPTRANSID': instance.opTransId,
      'MEMBERREQID': instance.memberReqId,
      'MESSAGE': instance.message,
      'COMMISSION': instance.commission,
      'MOBILENO': instance.mobileNo,
      'AMOUNT': instance.amount,
      'LAPUNO': instance.lapuNo,
      'OPNINGBAL': instance.openingBal,
      'CLOSINGBAL': instance.closingBal,
    };

WalletBalanceResponse _$WalletBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    WalletBalanceResponse(
      errorCode: json['Errorcode'] as String,
      status: (json['Status'] as num).toInt(),
      message: json['Message'] as String,
      buyerWalletBalance: (json['BuyerWalletBalance'] as num?)?.toDouble(),
      sellerWalletBalance: (json['SellerWalletBalance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WalletBalanceResponseToJson(
        WalletBalanceResponse instance) =>
    <String, dynamic>{
      'Errorcode': instance.errorCode,
      'Status': instance.status,
      'Message': instance.message,
      'BuyerWalletBalance': instance.buyerWalletBalance,
      'SellerWalletBalance': instance.sellerWalletBalance,
    };

OperatorBalanceResponse _$OperatorBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    OperatorBalanceResponse(
      errorCode: json['Errorcode'] as String,
      status: (json['Status'] as num).toInt(),
      record: json['Record'] as Map<String, dynamic>?,
      message: json['Message'] as String?,
    );

Map<String, dynamic> _$OperatorBalanceResponseToJson(
        OperatorBalanceResponse instance) =>
    <String, dynamic>{
      'Errorcode': instance.errorCode,
      'Status': instance.status,
      'Record': instance.record,
      'Message': instance.message,
    };

RechargeComplaintResponse _$RechargeComplaintResponseFromJson(
        Map<String, dynamic> json) =>
    RechargeComplaintResponse(
      error: json['ERROR'] as String,
      status: (json['STATUS'] as num).toInt(),
      memberReqId: json['MEMBERREQID'] as String,
      message: json['MESSAGE'] as String,
    );

Map<String, dynamic> _$RechargeComplaintResponseToJson(
        RechargeComplaintResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'MEMBERREQID': instance.memberReqId,
      'MESSAGE': instance.message,
    };
