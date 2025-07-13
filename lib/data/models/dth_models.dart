import 'package:json_annotation/json_annotation.dart';

part 'dth_models.g.dart';

// DTH Operator Detection Response
@JsonSerializable()
class DthOperatorResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'Message')
  final String message;
  
  @JsonKey(name: 'DthNumber')
  final String dthNumber;
  
  @JsonKey(name: 'DthName')
  final String dthName;
  
  @JsonKey(name: 'DthOpCode')
  final String dthOpCode;

  DthOperatorResponse({
    required this.error,
    required this.status,
    required this.message,
    required this.dthNumber,
    required this.dthName,
    required this.dthOpCode,
  });

  factory DthOperatorResponse.fromJson(Map<String, dynamic> json) =>
      _$DthOperatorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DthOperatorResponseToJson(this);

  bool get isSuccess => error == '0' && status == '1';
}

// DTH Plans Response
@JsonSerializable()
class DthPlansResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'Operator')
  final String operator;
  
  @JsonKey(name: 'RDATA')
  final DthRData? rdata;
  
  @JsonKey(name: 'MESSAGE')
  final String message;

  DthPlansResponse({
    required this.error,
    required this.status,
    required this.operator,
    this.rdata,
    required this.message,
  });

  factory DthPlansResponse.fromJson(Map<String, dynamic> json) =>
      _$DthPlansResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DthPlansResponseToJson(this);

  bool get isSuccess => error == '0' && status == '0';
}

@JsonSerializable()
class DthRData {
  @JsonKey(name: 'Combo')
  final List<DthCombo>? combo;

  DthRData({
    this.combo,
  });

  factory DthRData.fromJson(Map<String, dynamic> json) =>
      _$DthRDataFromJson(json);

  Map<String, dynamic> toJson() => _$DthRDataToJson(this);
}

@JsonSerializable()
class DthCombo {
  @JsonKey(name: 'Language')
  final String language;
  
  @JsonKey(name: 'PackCount')
  final String packCount;
  
  @JsonKey(name: 'Details')
  final List<DthPlanDetail> details;

  DthCombo({
    required this.language,
    required this.packCount,
    required this.details,
  });

  factory DthCombo.fromJson(Map<String, dynamic> json) =>
      _$DthComboFromJson(json);

  Map<String, dynamic> toJson() => _$DthComboToJson(this);
}

@JsonSerializable()
class DthPlanDetail {
  @JsonKey(name: 'PlanName')
  final String planName;
  
  @JsonKey(name: 'Channels')
  final String channels;
  
  @JsonKey(name: 'PaidChannels')
  final String paidChannels;
  
  @JsonKey(name: 'HdChannels')
  final String hdChannels;
  
  @JsonKey(name: 'last_update')
  final String lastUpdate;
  
  @JsonKey(name: 'PricingList')
  final List<DthPricing> pricingList;

  DthPlanDetail({
    required this.planName,
    required this.channels,
    required this.paidChannels,
    required this.hdChannels,
    required this.lastUpdate,
    required this.pricingList,
  });

  factory DthPlanDetail.fromJson(Map<String, dynamic> json) =>
      _$DthPlanDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DthPlanDetailToJson(this);
}

@JsonSerializable()
class DthPricing {
  @JsonKey(name: 'Amount')
  final String amount;
  
  @JsonKey(name: 'Month')
  final String month;

  DthPricing({
    required this.amount,
    required this.month,
  });

  factory DthPricing.fromJson(Map<String, dynamic> json) =>
      _$DthPricingFromJson(json);

  Map<String, dynamic> toJson() => _$DthPricingToJson(this);

  // Get numeric amount by removing currency symbol
  double get numericAmount {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount) ?? 0.0;
  }
}

// DTH Info Check Response
@JsonSerializable()
class DthInfoResponse {
  @JsonKey(name: 'error')
  final String error;
  
  @JsonKey(name: 'DATA')
  final DthInfoData? data;
  
  @JsonKey(name: 'Message')
  final String message;

  DthInfoResponse({
    required this.error,
    this.data,
    required this.message,
  });

  factory DthInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$DthInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DthInfoResponseToJson(this);

  bool get isSuccess => error == '0';
}

@JsonSerializable()
class DthInfoData {
  @JsonKey(name: 'VC')
  final String vc;
  
  @JsonKey(name: 'Name')
  final String name;
  
  @JsonKey(name: 'Rmn')
  final String rmn;
  
  @JsonKey(name: 'Balance')
  final String balance;
  
  @JsonKey(name: 'Monthly')
  final String monthly;
  
  @JsonKey(name: 'Next Recharge Date')
  final String nextRechargeDate;
  
  @JsonKey(name: 'Plan')
  final String plan;
  
  @JsonKey(name: 'Address')
  final String address;
  
  @JsonKey(name: 'City')
  final String city;
  
  @JsonKey(name: 'District')
  final String district;
  
  @JsonKey(name: 'State')
  final String state;
  
  @JsonKey(name: 'PIN Code')
  final String pinCode;

  DthInfoData({
    required this.vc,
    required this.name,
    required this.rmn,
    required this.balance,
    required this.monthly,
    required this.nextRechargeDate,
    required this.plan,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
  });

  factory DthInfoData.fromJson(Map<String, dynamic> json) =>
      _$DthInfoDataFromJson(json);

  Map<String, dynamic> toJson() => _$DthInfoDataToJson(this);

  double get numericBalance {
    return double.tryParse(balance) ?? 0.0;
  }
}

// DTH Operator Mapping
class DthOperatorMapping {
  // PlanAPI DTH Operator Codes
  static const Map<String, String> planApiOperatorCodes = {
    'AIRTEL DTH': '24',
    'DISH TV': '25',
    'RELIANCE BIGTV': '26',
    'SUN DIRECT': '27',
    'TATA SKY': '28',
    'VIDEOCON D2H': '29',
  };

  // Robotics Exchange DTH Operator Codes
  static const Map<String, String> roboticsOperatorCodes = {
    'AIRTEL DTH': 'AD',
    'DISH TV': 'DT',
    'SUN DIRECT': 'SD',
    'TATA SKY': 'TS',
    'VIDEOCON D2H': 'VD',
  };

  // Map PlanAPI operator code to Robotics Exchange operator code
  static String getPlanApiOperatorCode(String operatorName) {
    final upperName = operatorName.toUpperCase();
    
    // Try exact match first
    if (planApiOperatorCodes.containsKey(upperName)) {
      return planApiOperatorCodes[upperName]!;
    }
    
    // Try partial matching
    for (final entry in planApiOperatorCodes.entries) {
      if (upperName.contains(entry.key) || entry.key.contains(upperName)) {
        return entry.value;
      }
    }
    
    // Default to AIRTEL DTH if no match found
    return '24';
  }

  static String getRoboticsOperatorCode(String operatorName) {
    final upperName = operatorName.toUpperCase();
    
    // Try exact match first
    if (roboticsOperatorCodes.containsKey(upperName)) {
      return roboticsOperatorCodes[upperName]!;
    }
    
    // Try partial matching
    for (final entry in roboticsOperatorCodes.entries) {
      if (upperName.contains(entry.key) || entry.key.contains(upperName)) {
        return entry.value;
      }
    }
    
    // Default to AIRTEL DTH if no match found
    return 'AD';
  }

  // Map PlanAPI operator code to Robotics Exchange operator code
  static String mapPlanApiToRobotics(String planApiCode) {
    const mapping = {
      '24': 'AD', // AIRTEL DTH
      '25': 'DT', // DISH TV
      '26': 'VD', // RELIANCE BIGTV -> VIDEOCON (similar service)
      '27': 'SD', // SUN DIRECT
      '28': 'TS', // TATA SKY
      '29': 'VD', // VIDEOCON D2H
    };
    
    return mapping[planApiCode] ?? 'AD';
  }
}

// DTH Recharge Request
@JsonSerializable()
class DthRechargeRequest {
  final String dthNumber;
  final String operatorName;
  final String planApiOperatorCode;
  final String roboticsOperatorCode;
  final String amount;
  final String planName;
  final String duration;
  final String channels;

  DthRechargeRequest({
    required this.dthNumber,
    required this.operatorName,
    required this.planApiOperatorCode,
    required this.roboticsOperatorCode,
    required this.amount,
    required this.planName,
    required this.duration,
    required this.channels,
  });

  factory DthRechargeRequest.fromJson(Map<String, dynamic> json) =>
      _$DthRechargeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DthRechargeRequestToJson(this);
}

// Postpaid Support
enum RechargeType {
  prepaid,
  postpaid,
  dth,
}

@JsonSerializable()
class PostpaidPlanInfo {
  final String planName;
  final String amount;
  final String validity;
  final String description;
  final List<String> benefits;
  final RechargeType type;

  PostpaidPlanInfo({
    required this.planName,
    required this.amount,
    required this.validity,
    required this.description,
    required this.benefits,
    required this.type,
  });

  factory PostpaidPlanInfo.fromJson(Map<String, dynamic> json) =>
      _$PostpaidPlanInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PostpaidPlanInfoToJson(this);

  double get numericAmount {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount) ?? 0.0;
  }
} 