import 'package:json_annotation/json_annotation.dart';

part 'recharge_models.g.dart';

@JsonSerializable()
class RechargeRequest {
  final String mobileNumber;
  final String operatorCode;
  final String amount;
  final String circle;
  final String memberRequestTxnId;
  final String? groupId;

  RechargeRequest({
    required this.mobileNumber,
    required this.operatorCode,
    required this.amount,
    required this.circle,
    required this.memberRequestTxnId,
    this.groupId,
  });

  factory RechargeRequest.fromJson(Map<String, dynamic> json) =>
      _$RechargeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RechargeRequestToJson(this);
}

@JsonSerializable()
class RechargeResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final int status;
  
  @JsonKey(name: 'ORDERID')
  final String orderId;
  
  @JsonKey(name: 'OPTRANSID')
  final String? opTransId;
  
  @JsonKey(name: 'MEMBERREQID')
  final String memberReqId;
  
  @JsonKey(name: 'MESSAGE')
  final String message;
  
  @JsonKey(name: 'COMMISSION')
  final String? commission;
  
  @JsonKey(name: 'MOBILENO')
  final String? mobileNo;
  
  @JsonKey(name: 'AMOUNT')
  final String? amount;
  
  @JsonKey(name: 'LAPUNO')
  final String? lapuNo;
  
  @JsonKey(name: 'OPNINGBAL')
  final String? openingBal;
  
  @JsonKey(name: 'CLOSINGBAL')
  final String? closingBal;

  RechargeResponse({
    required this.error,
    required this.status,
    required this.orderId,
    this.opTransId,
    required this.memberReqId,
    required this.message,
    this.commission,
    this.mobileNo,
    this.amount,
    this.lapuNo,
    this.openingBal,
    this.closingBal,
  });

  factory RechargeResponse.fromJson(Map<String, dynamic> json) =>
      _$RechargeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RechargeResponseToJson(this);

  bool get isSuccess => error == '0' && status == 1;
  bool get isFailed => error == '1' && status == 3;
  bool get isProcessing => error == '1' && status == 2;
}

@JsonSerializable()
class StatusCheckResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final int status;
  
  @JsonKey(name: 'ORDERID')
  final String orderId;
  
  @JsonKey(name: 'OPTRANSID')
  final String opTransId;
  
  @JsonKey(name: 'MEMBERREQID')
  final String memberReqId;
  
  @JsonKey(name: 'MESSAGE')
  final String message;
  
  @JsonKey(name: 'COMMISSION')
  final String? commission;
  
  @JsonKey(name: 'MOBILENO')
  final String mobileNo;
  
  @JsonKey(name: 'AMOUNT')
  final String amount;
  
  @JsonKey(name: 'LAPUNO')
  final String lapuNo;
  
  @JsonKey(name: 'OPNINGBAL')
  final String openingBal;
  
  @JsonKey(name: 'CLOSINGBAL')
  final String closingBal;

  StatusCheckResponse({
    required this.error,
    required this.status,
    required this.orderId,
    required this.opTransId,
    required this.memberReqId,
    required this.message,
    this.commission,
    required this.mobileNo,
    required this.amount,
    required this.lapuNo,
    required this.openingBal,
    required this.closingBal,
  });

  factory StatusCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$StatusCheckResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatusCheckResponseToJson(this);

  bool get isSuccess => error == '0' && status == 1;
  bool get isFailed => error == '1' && status == 3;
  bool get isProcessing => error == '1' && status == 2;
}

@JsonSerializable()
class WalletBalanceResponse {
  @JsonKey(name: 'Errorcode')
  final String errorCode;
  
  @JsonKey(name: 'Status')
  final int status;
  
  @JsonKey(name: 'Message')
  final String message;
  
  @JsonKey(name: 'BuyerWalletBalance')
  final double? buyerWalletBalance;
  
  @JsonKey(name: 'SellerWalletBalance')
  final double? sellerWalletBalance;

  WalletBalanceResponse({
    required this.errorCode,
    required this.status,
    required this.message,
    this.buyerWalletBalance,
    this.sellerWalletBalance,
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletBalanceResponseToJson(this);

  bool get isSuccess => errorCode == '0' && status == 1;
}

@JsonSerializable()
class OperatorBalanceResponse {
  @JsonKey(name: 'Errorcode')
  final String errorCode;
  
  @JsonKey(name: 'Status')
  final int status;
  
  @JsonKey(name: 'Record')
  final Map<String, dynamic>? record;
  
  @JsonKey(name: 'Message')
  final String? message;

  OperatorBalanceResponse({
    required this.errorCode,
    required this.status,
    this.record,
    this.message,
  });

  factory OperatorBalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$OperatorBalanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OperatorBalanceResponseToJson(this);

  bool get isSuccess => errorCode == '0' && status == 1;
}

@JsonSerializable()
class RechargeComplaintResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final int status;
  
  @JsonKey(name: 'MEMBERREQID')
  final String memberReqId;
  
  @JsonKey(name: 'MESSAGE')
  final String message;

  RechargeComplaintResponse({
    required this.error,
    required this.status,
    required this.memberReqId,
    required this.message,
  });

  factory RechargeComplaintResponse.fromJson(Map<String, dynamic> json) =>
      _$RechargeComplaintResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RechargeComplaintResponseToJson(this);

  bool get isSuccess => error == '0' && status == 1;
}

// Operator and Circle mapping classes
class OperatorMapping {
  static const Map<String, String> operatorCodes = {
    'AIRTEL': 'AT',
    'VODAFONEIDEA': 'VI',
    'JIO': 'JO',
    'SUN TV': 'SD',
    'BSNL': 'BS',
    'AIRTEL DTH': 'AD',
    'DISH TV': 'DT',
    'TATASKY': 'TS',
    'VIDEOCON': 'VD',
    'JIO LITE': 'JL',
  };

  static const Map<String, String> circleCodes = {
    'DELHI': '10',
    'UP(West)': '97',
    'PUNJAB': '02',
    'HP': '03',
    'HARYANA': '96',
    'J&K': '55',
    'UP(East)': '54',
    'MUMBAI': '92',
    'MAHARASHTRA': '90',
    'GUJARAT': '98',
    'MP': '93',
    'RAJASTHAN': '70',
    'KOLKATTA': '31',
    'West Bengal': '51',
    'ORISSA': '53',
    'ASSAM': '56',
    'NESA': '16',
    'BIHAR': '52',
    'KARNATAKA': '06',
    'CHENNAI': '40',
    'TAMIL NADU': '94',
    'KERALA': '95',
    'AP': '49',
    'All': '50',
    'JHARKHAND': '20',
  };

  static String getOperatorCode(String operatorName) {
    return operatorCodes[operatorName.toUpperCase()] ?? 'AT';
  }

  static String getCircleCode(String circleName) {
    return circleCodes[circleName.toUpperCase()] ?? '10';
  }
}

// Error code mapping
class RechargeErrorCodes {
  static const Map<String, String> errorMessages = {
    '1': 'Authentication Failed!',
    '2': 'Invalid Request!',
    '3': 'Invalid Mobile Number!',
    '4': 'Invalid Amount! Amount must be between 10 and 25000',
    '5': 'Invalid Operator!',
    '6': 'Internal Server Error!',
    '7': 'Invalid User',
    '8': 'Invalid Rule',
    '9': 'Insufficient Balance',
    '10': 'Low Api Balance',
    '11': 'Invalid Operator',
    '12': 'Operator_Mismatch',
    '16': 'Duplicate Request!',
    '17': 'User Not Active!',
    '18': 'Invalid Request From IP....',
    '20': 'Invalid Data',
    '21': 'Frequent Request. Retry After Some time.',
    '22': 'Invalid Request-Id(max 30 digits allowed)',
    '25': 'Stock not available for this margin.',
    '26': 'No record found',
    '27': 'Duplicate Resend Request.',
    '30': 'Request is processed!',
    '31': 'Error, Contact to Administrator',
    '38': 'Purchase margin not set.',
    '40': 'Recharge Amount not valid for this Operator in this Circle',
    '41': 'Invalid Rule. Please set Rule for this Operator first!',
    '42': 'Lapu is already Exists',
    '43': 'Invalid Api Token',
    '44': 'Invalid Api parameter',
    '154': 'Requested Operator Currently Offline',
  };

  static String getErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? 'Unknown error occurred';
  }
}

enum RechargeStatus {
  success,
  failed,
  processing,
  pending,
}

extension RechargeStatusExtension on RechargeStatus {
  String get displayName {
    switch (this) {
      case RechargeStatus.success:
        return 'Success';
      case RechargeStatus.failed:
        return 'Failed';
      case RechargeStatus.processing:
        return 'Processing';
      case RechargeStatus.pending:
        return 'Pending';
    }
  }
} 