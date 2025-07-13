// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operator_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperatorInfo _$OperatorInfoFromJson(Map<String, dynamic> json) => OperatorInfo(
      error: json['ERROR'] as String,
      status: json['STATUS'] as String,
      mobile: json['Mobile'] as String,
      operator: json['Operator'] as String,
      opCode: json['OpCode'] as String,
      circle: json['Circle'] as String,
      circleCode: json['CircleCode'] as String,
      message: json['Message'] as String,
    );

Map<String, dynamic> _$OperatorInfoToJson(OperatorInfo instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'Mobile': instance.mobile,
      'Operator': instance.operator,
      'OpCode': instance.opCode,
      'Circle': instance.circle,
      'CircleCode': instance.circleCode,
      'Message': instance.message,
    };
