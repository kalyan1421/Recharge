// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_plans.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobilePlansResponse _$MobilePlansResponseFromJson(Map<String, dynamic> json) =>
    MobilePlansResponse(
      error: json['ERROR'] as String,
      status: json['STATUS'] as String,
      operator: json['Operator'] as String,
      circle: json['Circle'] as String,
      rdata: json['RDATA'] == null
          ? null
          : MobilePlansData.fromJson(json['RDATA'] as Map<String, dynamic>),
      message: json['MESSAGE'] as String,
    );

Map<String, dynamic> _$MobilePlansResponseToJson(
        MobilePlansResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'Operator': instance.operator,
      'Circle': instance.circle,
      'RDATA': instance.rdata,
      'MESSAGE': instance.message,
    };

PlanItem _$PlanItemFromJson(Map<String, dynamic> json) => PlanItem(
      rs: json['rs'],
      validity: json['validity'] as String,
      desc: json['desc'] as String,
    );

Map<String, dynamic> _$PlanItemToJson(PlanItem instance) => <String, dynamic>{
      'rs': instance.rs,
      'validity': instance.validity,
      'desc': instance.desc,
    };

ROfferResponse _$ROfferResponseFromJson(Map<String, dynamic> json) =>
    ROfferResponse(
      error: json['ERROR'] as String,
      status: json['STATUS'] as String,
      mobileNo: json['MOBILENO'] as String,
      rdata: (json['RDATA'] as List<dynamic>?)
          ?.map((e) => ROfferItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['MESSAGE'] as String,
    );

Map<String, dynamic> _$ROfferResponseToJson(ROfferResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'MOBILENO': instance.mobileNo,
      'RDATA': instance.rdata,
      'MESSAGE': instance.message,
    };

ROfferItem _$ROfferItemFromJson(Map<String, dynamic> json) => ROfferItem(
      price: json['price'] as String,
      commissionUnit: json['commissionUnit'] as String,
      offerText: json['ofrtext'] as String,
      logDescription: json['logdesc'] as String,
      commissionAmount: json['commissionAmount'] as String,
    );

Map<String, dynamic> _$ROfferItemToJson(ROfferItem instance) =>
    <String, dynamic>{
      'price': instance.price,
      'commissionUnit': instance.commissionUnit,
      'ofrtext': instance.offerText,
      'logdesc': instance.logDescription,
      'commissionAmount': instance.commissionAmount,
    };
