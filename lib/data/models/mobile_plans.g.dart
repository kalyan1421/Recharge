// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_plans.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobilePlans _$MobilePlansFromJson(Map<String, dynamic> json) => MobilePlans(
      data: (json['DATA'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      trulyUnlimited: (json['TRULY UNLIMITED'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      talktime: (json['TALKTIME'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cricketPacks: (json['CRICKET PACKS'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      planVouchers: (json['PLAN VOUCHERS'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      roamingPacks: (json['ROAMING PACK'] as List<dynamic>?)
              ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: json['status'] as String?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$MobilePlansToJson(MobilePlans instance) =>
    <String, dynamic>{
      'DATA': instance.data,
      'TRULY UNLIMITED': instance.trulyUnlimited,
      'TALKTIME': instance.talktime,
      'CRICKET PACKS': instance.cricketPacks,
      'PLAN VOUCHERS': instance.planVouchers,
      'ROAMING PACK': instance.roamingPacks,
      'status': instance.status,
      'message': instance.message,
      'error': instance.error,
    };

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
      operator: json['operator'] as String,
      circle: json['circle'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      planDescription: json['planDescription'] as String,
      planPrice: (json['planPrice'] as num).toDouble(),
      planValidity: json['planValidity'] as String,
      planDetails: json['planDetails'] as String,
      planType: json['planType'] as String,
      planCategory: json['planCategory'] as String,
    );

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
      'operator': instance.operator,
      'circle': instance.circle,
      'planId': instance.planId,
      'planName': instance.planName,
      'planDescription': instance.planDescription,
      'planPrice': instance.planPrice,
      'planValidity': instance.planValidity,
      'planDetails': instance.planDetails,
      'planType': instance.planType,
      'planCategory': instance.planCategory,
    };

PlanItem _$PlanItemFromJson(Map<String, dynamic> json) => PlanItem(
      rs: (json['rs'] as num).toInt(),
      validity: json['validity'] as String,
      desc: json['desc'] as String,
      type: json['type'] as String?,
      lastUpdate: json['last_update'] as String?,
    );

Map<String, dynamic> _$PlanItemToJson(PlanItem instance) => <String, dynamic>{
      'rs': instance.rs,
      'validity': instance.validity,
      'desc': instance.desc,
      'type': instance.type,
      'last_update': instance.lastUpdate,
    };

SpecialOffer _$SpecialOfferFromJson(Map<String, dynamic> json) => SpecialOffer(
      amount: (json['amount'] as num).toInt(),
      validity: json['validity'] as String,
      description: json['description'] as String,
      offerType: json['offer_type'] as String?,
      lastRecharged: json['last_recharged'] as String?,
      operator: json['operator'] as String?,
      circle: json['circle'] as String?,
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      planPrice: (json['plan_price'] as num?)?.toDouble(),
      planDetails: json['plan_details'] as String?,
      planType: json['plan_type'] as String?,
      planCategory: json['plan_category'] as String?,
    );

Map<String, dynamic> _$SpecialOfferToJson(SpecialOffer instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'validity': instance.validity,
      'description': instance.description,
      'offer_type': instance.offerType,
      'last_recharged': instance.lastRecharged,
      'operator': instance.operator,
      'circle': instance.circle,
      'plan_id': instance.planId,
      'plan_name': instance.planName,
      'plan_price': instance.planPrice,
      'plan_details': instance.planDetails,
      'plan_type': instance.planType,
      'plan_category': instance.planCategory,
    };
