import 'package:json_annotation/json_annotation.dart';

part 'mobile_plans.g.dart';

@JsonSerializable()
class MobilePlansResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'Operator')
  final String operator;
  
  @JsonKey(name: 'Circle')
  final String circle;
  
  @JsonKey(name: 'RDATA')
  final MobilePlansData? rdata;
  
  @JsonKey(name: 'MESSAGE')
  final String message;

  MobilePlansResponse({
    required this.error,
    required this.status,
    required this.operator,
    required this.circle,
    this.rdata,
    required this.message,
  });

  factory MobilePlansResponse.fromJson(Map<String, dynamic> json) => _$MobilePlansResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MobilePlansResponseToJson(this);

  bool get isSuccess => error == '0' && status == '0';
  bool get isAuthenticationError => error == '1' && status == '3';
}

class MobilePlansData {
  final Map<String, dynamic> _rawData;

  MobilePlansData(this._rawData);

  factory MobilePlansData.fromJson(Map<String, dynamic> json) {
    return MobilePlansData(json);
  }

  Map<String, dynamic> toJson() => _rawData;

  List<PlanCategory> getAllCategories() {
    List<PlanCategory> categories = [];
    
    // Iterate through all keys in the raw data
    for (final entry in _rawData.entries) {
      final categoryName = entry.key;
      final categoryData = entry.value;
      
      // Skip if not a list
      if (categoryData is! List) continue;
      
      // Convert each item to PlanItem
      final plans = <PlanItem>[];
      for (final item in categoryData) {
        if (item is Map<String, dynamic>) {
          try {
            plans.add(PlanItem.fromJson(item));
          } catch (e) {
            print('Error parsing plan item: $e');
          }
        }
      }
      
      // Add category if it has plans
      if (plans.isNotEmpty) {
        categories.add(PlanCategory(name: categoryName, plans: plans));
      }
    }
    
    return categories;
  }
}

@JsonSerializable()
class PlanItem {
  @JsonKey(name: 'rs')
  final dynamic rs; // Can be int or string
  
  @JsonKey(name: 'validity')
  final String validity;
  
  @JsonKey(name: 'desc')
  final String desc;

  PlanItem({
    required this.rs,
    required this.validity,
    required this.desc,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => _$PlanItemFromJson(json);
  Map<String, dynamic> toJson() => _$PlanItemToJson(this);

  int get price => rs is int ? rs : int.tryParse(rs.toString()) ?? 0;
  String get priceString => rs.toString();
}

class PlanCategory {
  final String name;
  final List<PlanItem> plans;

  PlanCategory({
    required this.name,
    required this.plans,
  });
}

class PlanDetails {
  final String price;
  final String validity;
  final String desc;
  final String type;

  PlanDetails({
    required this.price,
    required this.validity,
    required this.desc,
    required this.type,
  });

  factory PlanDetails.fromPlanItem(PlanItem item, String type) {
    return PlanDetails(
      price: item.priceString,
      validity: item.validity,
      desc: item.desc,
      type: type,
    );
  }

  int get priceValue => int.tryParse(price) ?? 0;
}

// R-OFFER Response Models
@JsonSerializable()
class ROfferResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'MOBILENO')
  final String mobileNo;
  
  @JsonKey(name: 'RDATA')
  final List<ROfferItem>? rdata;
  
  @JsonKey(name: 'MESSAGE')
  final String message;

  ROfferResponse({
    required this.error,
    required this.status,
    required this.mobileNo,
    this.rdata,
    required this.message,
  });

  factory ROfferResponse.fromJson(Map<String, dynamic> json) => _$ROfferResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ROfferResponseToJson(this);

  bool get isSuccess => error == '0' && status == '1';
  bool get isAuthenticationError => error == '1' && status == '3';
}

@JsonSerializable()
class ROfferItem {
  @JsonKey(name: 'price')
  final String price;
  
  @JsonKey(name: 'commissionUnit')
  final String commissionUnit;
  
  @JsonKey(name: 'ofrtext')
  final String offerText;
  
  @JsonKey(name: 'logdesc')
  final String logDescription;
  
  @JsonKey(name: 'commissionAmount')
  final String commissionAmount;

  ROfferItem({
    required this.price,
    required this.commissionUnit,
    required this.offerText,
    required this.logDescription,
    required this.commissionAmount,
  });

  factory ROfferItem.fromJson(Map<String, dynamic> json) => _$ROfferItemFromJson(json);
  Map<String, dynamic> toJson() => _$ROfferItemToJson(this);

  int get priceValue => int.tryParse(price) ?? 0;
}

// Recharge Status Check Response Model
@JsonSerializable()
class RechargeStatusResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'MOBILENO')
  final String mobileNo;
  
  @JsonKey(name: 'MESSAGE')
  final String message;
  
  @JsonKey(name: 'Amount')
  final String? amount;
  
  @JsonKey(name: 'RechargeDate')
  final String? rechargeDate;

  RechargeStatusResponse({
    required this.error,
    required this.status,
    required this.mobileNo,
    required this.message,
    this.amount,
    this.rechargeDate,
  });

  factory RechargeStatusResponse.fromJson(Map<String, dynamic> json) => _$RechargeStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RechargeStatusResponseToJson(this);

  bool get isSuccess => error == '0' && status == '1';
  bool get hasRechargeData => amount != null && rechargeDate != null;
  
  double? get amountValue => amount != null ? double.tryParse(amount!) : null;
}

// Recharge Expiry Check Response Model
@JsonSerializable()
class RechargeExpiryResponse {
  @JsonKey(name: 'ERROR')
  final String error;
  
  @JsonKey(name: 'STATUS')
  final String status;
  
  @JsonKey(name: 'MOBILENO')
  final String mobileNo;
  
  @JsonKey(name: 'MESSAGE')
  final String message;
  
  @JsonKey(name: 'OUTGOING')
  final String? outgoing;
  
  @JsonKey(name: 'INCOMING')
  final String? incoming;

  RechargeExpiryResponse({
    required this.error,
    required this.status,
    required this.mobileNo,
    required this.message,
    this.outgoing,
    this.incoming,
  });

  factory RechargeExpiryResponse.fromJson(Map<String, dynamic> json) => _$RechargeExpiryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RechargeExpiryResponseToJson(this);

  bool get isSuccess => error == '0' && status == '1';
  bool get hasExpiryData => outgoing != null && incoming != null;
  
  DateTime? get outgoingDate => outgoing != null ? DateTime.tryParse(outgoing!) : null;
  DateTime? get incomingDate => incoming != null ? DateTime.tryParse(incoming!) : null;
} 