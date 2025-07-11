import 'package:json_annotation/json_annotation.dart';

part 'operator_info.g.dart';

@JsonSerializable()
class OperatorInfo {
  @JsonKey(name: 'Operator')
  final String? operator;
  
  @JsonKey(name: 'OpCode')
  final String? opCode;
  
  @JsonKey(name: 'Circle')
  final String? circle;
  
  @JsonKey(name: 'CircleCode')
  final String? circleCode;
  
  @JsonKey(name: 'Mobile')
  final String mobile;
  
  @JsonKey(name: 'Status')
  final String? status;
  
  @JsonKey(name: 'Message')
  final String? message;
  
  @JsonKey(name: 'ERROR')
  final String? error;

  const OperatorInfo({
    this.operator,
    this.opCode,
    this.circle,
    this.circleCode,
    required this.mobile,
    this.status,
    this.message,
    this.error,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) => _$OperatorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$OperatorInfoToJson(this);

  // Helper method to get operator logo
  String get operatorLogo {
    if (operator == null || operator!.isEmpty) {
      return 'assets/operators/default.png';
    }
    switch (operator!.toUpperCase()) {
      case 'AIRTEL':
        return 'assets/operators/airtel.png';
      case 'VODAFONE':
        return 'assets/operators/vodafone.png';
      case 'JIO':
        return 'assets/operators/jio.png';
      case 'IDEA':
        return 'assets/operators/idea.png';
      case 'BSNL':
        return 'assets/operators/bsnl.png';
      default:
        return 'assets/operators/default.png';
    }
  }

  // Helper method to check if detection was successful
  bool get isValid => error != '1' && operator != null && operator!.isNotEmpty;
  
  // Helper method to check if there's an API error
  bool get hasError => error == '1' || message?.contains('Invalid') == true;

  @override
  String toString() {
    return 'OperatorInfo(operator: $operator, opCode: $opCode, circle: $circle, circleCode: $circleCode, mobile: $mobile, error: $error, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperatorInfo &&
        other.operator == operator &&
        other.opCode == opCode &&
        other.circle == circle &&
        other.circleCode == circleCode &&
        other.mobile == mobile &&
        other.error == error;
  }

  @override
  int get hashCode {
    return (operator?.hashCode ?? 0) ^
        (opCode?.hashCode ?? 0) ^
        (circle?.hashCode ?? 0) ^
        (circleCode?.hashCode ?? 0) ^
        mobile.hashCode ^
        (error?.hashCode ?? 0);
  }
} 