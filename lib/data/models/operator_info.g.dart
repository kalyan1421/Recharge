// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operator_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperatorInfo _$OperatorInfoFromJson(Map<String, dynamic> json) => OperatorInfo(
      operator: json['Operator'] as String?,
      opCode: json['OpCode'] as String?,
      circle: json['Circle'] as String?,
      circleCode: json['CircleCode'] as String?,
      mobile: json['Mobile'] as String,
      status: json['Status'] as String?,
      message: json['Message'] as String?,
      error: json['ERROR'] as String?,
    );

Map<String, dynamic> _$OperatorInfoToJson(OperatorInfo instance) =>
    <String, dynamic>{
      'Operator': instance.operator,
      'OpCode': instance.opCode,
      'Circle': instance.circle,
      'CircleCode': instance.circleCode,
      'Mobile': instance.mobile,
      'Status': instance.status,
      'Message': instance.message,
      'ERROR': instance.error,
    };
