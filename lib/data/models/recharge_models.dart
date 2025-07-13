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
    // Mobile Operators
    'AIRTEL': 'AT',
    'VODAFONEIDEA': 'VI',
    'JIO': 'JL',  // Use JIO LITE instead of JIO since JIO LAPU is inactive
    'BSNL': 'BS',
    'JIO LITE': 'JL',
    
    // DTH Operators
    'AIRTEL DTH': 'AD',
    'DISH TV': 'DT',
    'SUN TV': 'SD',
    'SUN DIRECT': 'SD',
    'TATASKY': 'TS',
    'TATA SKY': 'TS',
    'VIDEOCON': 'VD',
    'VIDEOCON D2H': 'VD',
    'RELIANCE BIGTV': 'VD',  // Map to VIDEOCON as similar service
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
    'CHENNAI': '20',
    'TAMIL NADU': '94',
    'KERALA': '95',
    'AP': '49',
    'All': '50',
    'JHARKHAND': '20',
  };

  /// Enhanced operator code mapping with fallback patterns
  static String getOperatorCode(String operatorName) {
    // Convert to uppercase for consistent matching
    final name = operatorName.toUpperCase();
    
    // Direct mapping check first
    if (operatorCodes.containsKey(name)) {
      return operatorCodes[name]!;
    }
    
    // Pattern matching for variations (prioritize JIO over other operators)
    if (name.contains('JIO') || name.contains('RELIANCE') || name.contains('RJI') || name.contains('RJIO')) {
      // Check if it's DTH first
      if (name.contains('DTH') || name.contains('BIGTV')) {
        return 'VD'; // RELIANCE BIGTV -> VIDEOCON
      }
      // Use JIO LITE instead of JIO since JIO LAPU is inactive
      return 'JL';
    } else if (name.contains('AIRTEL')) {
      // Check if it's DTH
      if (name.contains('DTH')) {
        return 'AD';
      }
      return 'AT';
    } else if (name.contains('VODAFONE') || name.contains('IDEA') || name.contains('VI')) {
      return 'VI';
    } else if (name.contains('BSNL')) {
      return 'BS';
    } else if (name.contains('SUN')) {
      return 'SD';
    } else if (name.contains('DISH')) {
      return 'DT';
    } else if (name.contains('TATA')) {
      return 'TS';
    } else if (name.contains('VIDEOCON')) {
      return 'VD';
    }
    
    // Default fallback to AIRTEL if no match found
    print('⚠️ Warning: Unknown operator "$operatorName", defaulting to AIRTEL');
    return 'AT';
  }

  static String getCircleCode(String circleName) {
    final upperName = circleName.toUpperCase().trim();
    
    // Try exact match first
    if (circleCodes.containsKey(upperName)) {
      return circleCodes[upperName]!;
    }
    
    // Try partial match
    for (final entry in circleCodes.entries) {
      if (upperName.contains(entry.key) || entry.key.contains(upperName)) {
        return entry.value;
      }
    }
    
    // Special cases for common variations
    if (upperName.contains('DELHI') || upperName.contains('NCR')) {
      return '10';
    }
    if (upperName.contains('MUMBAI') || upperName.contains('BOMBAY')) {
      return '92';
    }
    if (upperName.contains('KOLKATA') || upperName.contains('CALCUTTA')) {
      return '31';
    }
    if (upperName.contains('CHENNAI') || upperName.contains('MADRAS')) {
      return '40';
    }
    if (upperName.contains('BANGALORE') || upperName.contains('BENGALURU')) {
      return '06';
    }
    if (upperName.contains('HYDERABAD') || upperName.contains('TELANGANA')) {
      return '49';
    }
    if (upperName.contains('ANDHRA') || upperName.contains('AP')) {
      return '49';
    }
    
    // Default to Delhi if not found
    return '10';
  }

  /// Determine if an operator is DTH
  static bool isDthOperator(String operatorName) {
    final name = operatorName.toUpperCase();
    return name.contains('DTH') || 
           name.contains('DISH') ||
           name.contains('TATA SKY') ||
           name.contains('TATASKY') ||
           name.contains('VIDEOCON') ||
           name.contains('SUN TV') ||
           name.contains('SUN DIRECT') ||
           name.contains('BIGTV');
  }

  /// Determine if an operator is mobile (prepaid/postpaid)
  static bool isMobileOperator(String operatorName) {
    final name = operatorName.toUpperCase();
    return (name.contains('AIRTEL') && !name.contains('DTH')) ||
           name.contains('JIO') ||
           name.contains('VODAFONE') ||
           name.contains('IDEA') ||
           name.contains('VI') ||
           name.contains('BSNL') ||
           name.contains('RELIANCE') && !name.contains('BIGTV');
  }

  /// Determine plan type based on keywords
  static String getPlanType(String planName, String description) {
    final combined = '${planName.toUpperCase()} ${description.toUpperCase()}';
    
    if (combined.contains('POSTPAID') || combined.contains('POST PAID')) {
      return 'postpaid';
    } else if (combined.contains('DTH') || combined.contains('DISH') || combined.contains('TATASKY')) {
      return 'dth';
    } else {
      return 'prepaid'; // Default to prepaid
    }
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