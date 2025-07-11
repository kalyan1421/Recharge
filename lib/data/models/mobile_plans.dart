import 'package:json_annotation/json_annotation.dart';

part 'mobile_plans.g.dart';

@JsonSerializable()
class MobilePlans {
  @JsonKey(name: 'DATA')
  final List<PlanItem> data;
  
  @JsonKey(name: 'TRULY UNLIMITED')
  final List<PlanItem> trulyUnlimited;
  
  @JsonKey(name: 'TALKTIME')
  final List<PlanItem> talktime;
  
  @JsonKey(name: 'CRICKET PACKS')
  final List<PlanItem> cricketPacks;
  
  @JsonKey(name: 'PLAN VOUCHERS')
  final List<PlanItem> planVouchers;
  
  @JsonKey(name: 'ROAMING PACK')
  final List<PlanItem> roamingPacks;
  
  @JsonKey(name: 'status')
  final String? status;
  
  @JsonKey(name: 'message')
  final String? message;
  
  @JsonKey(name: 'error')
  final String? error;

  const MobilePlans({
    this.data = const [],
    this.trulyUnlimited = const [],
    this.talktime = const [],
    this.cricketPacks = const [],
    this.planVouchers = const [],
    this.roamingPacks = const [],
    this.status,
    this.message,
    this.error,
  });

  factory MobilePlans.fromJson(Map<String, dynamic> json) => _$MobilePlansFromJson(json);
  Map<String, dynamic> toJson() => _$MobilePlansToJson(this);

  // Helper method to get all plans combined
  List<PlanItem> get allPlans {
    return [
      ...data,
      ...trulyUnlimited,
      ...talktime,
      ...cricketPacks,
      ...planVouchers,
      ...roamingPacks,
    ];
  }
  
  // Helper method to get all plans as Plan objects (for backwards compatibility)
  List<Plan> get plans {
    return allPlans.map((planItem) => Plan.fromPlanItem(planItem)).toList();
  }

  // Helper method to get plans by category
  List<PlanItem> getPlansByCategory(PlanCategory category) {
    switch (category) {
      case PlanCategory.data:
        return data;
      case PlanCategory.trulyUnlimited:
        return trulyUnlimited;
      case PlanCategory.talktime:
        return talktime;
      case PlanCategory.cricketPacks:
        return cricketPacks;
      case PlanCategory.planVouchers:
        return planVouchers;
      case PlanCategory.roamingPacks:
        return roamingPacks;
    }
  }

  bool get isValid => status?.toUpperCase() == 'SUCCESS' || allPlans.isNotEmpty;
}

// Plan class for backwards compatibility
@JsonSerializable()
class Plan {
  final String operator;
  final String circle;
  final String planId;
  final String planName;
  final String planDescription;
  final double planPrice;
  final String planValidity;
  final String planDetails;
  final String planType;
  final String planCategory;

  const Plan({
    required this.operator,
    required this.circle,
    required this.planId,
    required this.planName,
    required this.planDescription,
    required this.planPrice,
    required this.planValidity,
    required this.planDetails,
    required this.planType,
    required this.planCategory,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);

  // Create Plan from PlanItem
  factory Plan.fromPlanItem(PlanItem planItem) {
    return Plan(
      operator: 'Unknown',
      circle: 'Unknown',
      planId: planItem.rs.toString(),
      planName: '₹${planItem.rs}',
      planDescription: planItem.cleanDescription,
      planPrice: planItem.rs.toDouble(),
      planValidity: planItem.validity,
      planDetails: planItem.desc,
      planType: planItem.type ?? 'Unknown',
      planCategory: planItem.type ?? 'Unknown',
    );
  }
}

@JsonSerializable()
class PlanItem {
  @JsonKey(name: 'rs')
  final int rs;
  
  @JsonKey(name: 'validity')
  final String validity;
  
  @JsonKey(name: 'desc')
  final String desc;
  
  @JsonKey(name: 'type')
  final String? type;
  
  @JsonKey(name: 'last_update')
  final String? lastUpdate;

  const PlanItem({
    required this.rs,
    required this.validity,
    required this.desc,
    this.type,
    this.lastUpdate,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => _$PlanItemFromJson(json);
  Map<String, dynamic> toJson() => _$PlanItemToJson(this);

  // Helper getter for formatted price
  String get formattedPrice => '₹$rs';

  // Helper getter for validity display
  String get validityDisplay {
    if (validity.isEmpty) return 'N/A';
    
    // Try to parse and format validity
    final RegExp dayPattern = RegExp(r'(\d+)\s*days?', caseSensitive: false);
    final match = dayPattern.firstMatch(validity);
    
    if (match != null) {
      final days = int.tryParse(match.group(1) ?? '');
      if (days != null) {
        if (days >= 365) {
          final years = (days / 365).floor();
          return years == 1 ? '1 Year' : '$years Years';
        } else if (days >= 30) {
          final months = (days / 30).floor();
          return months == 1 ? '1 Month' : '$months Months';
        } else {
          return days == 1 ? '1 Day' : '$days Days';
        }
      }
    }
    
    return validity;
  }

  // Helper getter for description without HTML tags
  String get cleanDescription {
    return desc
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  // Helper method to extract data amount from description
  String? get dataAmount {
    final RegExp dataPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(GB|MB|TB)', caseSensitive: false);
    final match = dataPattern.firstMatch(cleanDescription);
    return match?.group(0);
  }

  // Helper method to check if plan is popular (based on common amounts)
  bool get isPopular {
    const popularAmounts = [199, 299, 399, 499, 599, 699, 999, 1499, 2999];
    return popularAmounts.contains(rs);
  }

  @override
  String toString() {
    return 'PlanItem(rs: $rs, validity: $validity, desc: $cleanDescription)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanItem &&
        other.rs == rs &&
        other.validity == validity &&
        other.desc == desc;
  }

  @override
  int get hashCode {
    return rs.hashCode ^ validity.hashCode ^ desc.hashCode;
  }
}

@JsonSerializable()
class SpecialOffer {
  @JsonKey(name: 'amount')
  final int amount;
  
  @JsonKey(name: 'validity')
  final String validity;
  
  @JsonKey(name: 'description')
  final String description;
  
  @JsonKey(name: 'offer_type')
  final String? offerType;
  
  @JsonKey(name: 'last_recharged')
  final String? lastRecharged;
  
  @JsonKey(name: 'operator')
  final String? operator;
  
  @JsonKey(name: 'circle')
  final String? circle;
  
  @JsonKey(name: 'plan_id')
  final String? planId;
  
  @JsonKey(name: 'plan_name')
  final String? planName;
  
  @JsonKey(name: 'plan_price')
  final double? planPrice;
  
  @JsonKey(name: 'plan_details')
  final String? planDetails;
  
  @JsonKey(name: 'plan_type')
  final String? planType;
  
  @JsonKey(name: 'plan_category')
  final String? planCategory;

  const SpecialOffer({
    required this.amount,
    required this.validity,
    required this.description,
    this.offerType,
    this.lastRecharged,
    this.operator,
    this.circle,
    this.planId,
    this.planName,
    this.planPrice,
    this.planDetails,
    this.planType,
    this.planCategory,
  });

  factory SpecialOffer.fromJson(Map<String, dynamic> json) => _$SpecialOfferFromJson(json);
  Map<String, dynamic> toJson() => _$SpecialOfferToJson(this);

  // Helper getter for formatted price
  String get formattedPrice => planPrice != null ? '₹${planPrice!.toInt()}' : '₹$amount';
  
  // Helper getter for formatted amount (backwards compatibility)
  String get formattedAmount => formattedPrice;

  // Helper getter for validity display
  String get validityDisplay {
    if (validity.isEmpty) return 'N/A';
    
    // Try to parse and format validity
    final RegExp dayPattern = RegExp(r'(\d+)\s*days?', caseSensitive: false);
    final match = dayPattern.firstMatch(validity);
    
    if (match != null) {
      final days = int.tryParse(match.group(1) ?? '');
      if (days != null) {
        if (days >= 365) {
          final years = (days / 365).floor();
          return years == 1 ? '1 Year' : '$years Years';
        } else if (days >= 30) {
          final months = (days / 30).floor();
          return months == 1 ? '1 Month' : '$months Months';
        } else {
          return days == 1 ? '1 Day' : '$days Days';
        }
      }
    }
    
    return validity;
  }

  // Helper getter for description without HTML tags
  String get cleanDescription {
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  @override
  String toString() {
    return 'SpecialOffer(amount: $amount, validity: $validity, description: $cleanDescription)';
  }
}

enum PlanCategory {
  data,
  trulyUnlimited,
  talktime,
  cricketPacks,
  planVouchers,
  roamingPacks,
}

extension PlanCategoryExtension on PlanCategory {
  String get displayName {
    switch (this) {
      case PlanCategory.data:
        return 'Data';
      case PlanCategory.trulyUnlimited:
        return 'Unlimited';
      case PlanCategory.talktime:
        return 'Talktime';
      case PlanCategory.cricketPacks:
        return 'Cricket';
      case PlanCategory.planVouchers:
        return 'Vouchers';
      case PlanCategory.roamingPacks:
        return 'Roaming';
    }
  }

  String get icon {
    switch (this) {
      case PlanCategory.data:
        return '📶';
      case PlanCategory.trulyUnlimited:
        return '🚀';
      case PlanCategory.talktime:
        return '📞';
      case PlanCategory.cricketPacks:
        return '🏏';
      case PlanCategory.planVouchers:
        return '🎟️';
      case PlanCategory.roamingPacks:
        return '🌏';
    }
  }
} 