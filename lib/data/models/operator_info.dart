import 'package:json_annotation/json_annotation.dart';

part 'operator_info.g.dart';

@JsonSerializable()
class OperatorInfo {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'Mobile')
  final String mobile;
  
  @JsonKey(name: 'Operator')
  final String operator;
  
  @JsonKey(name: 'OpCode')
  final String opCode;
  
  @JsonKey(name: 'Circle')
  final String circle;
  
  @JsonKey(name: 'CircleCode')
  final String circleCode;
  
  @JsonKey(name: 'Message')
  final String message;

  OperatorInfo({
    required this.error,
    required this.status,
    required this.mobile,
    required this.operator,
    required this.opCode,
    required this.circle,
    required this.circleCode,
    required this.message,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) => _$OperatorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$OperatorInfoToJson(this);

  // Helper methods
  bool get isSuccess => error == '0' && status == '1';
  bool get isAuthenticationError => error == '3';
  
  @override
  String toString() {
    return 'OperatorInfo(error: $error, status: $status, mobile: $mobile, operator: $operator, opCode: $opCode, circle: $circle, circleCode: $circleCode, message: $message)';
  }
} 