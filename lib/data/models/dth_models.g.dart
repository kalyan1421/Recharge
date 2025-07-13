// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DthOperatorResponse _$DthOperatorResponseFromJson(Map<String, dynamic> json) =>
    DthOperatorResponse(
      error: json['ERROR'] as String,
      status: json['STATUS'] as String,
      message: json['Message'] as String,
      dthNumber: json['DthNumber'] as String,
      dthName: json['DthName'] as String,
      dthOpCode: json['DthOpCode'] as String,
    );

Map<String, dynamic> _$DthOperatorResponseToJson(
        DthOperatorResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'Message': instance.message,
      'DthNumber': instance.dthNumber,
      'DthName': instance.dthName,
      'DthOpCode': instance.dthOpCode,
    };

DthPlansResponse _$DthPlansResponseFromJson(Map<String, dynamic> json) =>
    DthPlansResponse(
      error: json['ERROR'] as String,
      status: json['STATUS'] as String,
      operator: json['Operator'] as String,
      rdata: json['RDATA'] == null
          ? null
          : DthRData.fromJson(json['RDATA'] as Map<String, dynamic>),
      message: json['MESSAGE'] as String,
    );

Map<String, dynamic> _$DthPlansResponseToJson(DthPlansResponse instance) =>
    <String, dynamic>{
      'ERROR': instance.error,
      'STATUS': instance.status,
      'Operator': instance.operator,
      'RDATA': instance.rdata,
      'MESSAGE': instance.message,
    };

DthRData _$DthRDataFromJson(Map<String, dynamic> json) => DthRData(
      combo: (json['Combo'] as List<dynamic>?)
          ?.map((e) => DthCombo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DthRDataToJson(DthRData instance) => <String, dynamic>{
      'Combo': instance.combo,
    };

DthCombo _$DthComboFromJson(Map<String, dynamic> json) => DthCombo(
      language: json['Language'] as String,
      packCount: json['PackCount'] as String,
      details: (json['Details'] as List<dynamic>)
          .map((e) => DthPlanDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DthComboToJson(DthCombo instance) => <String, dynamic>{
      'Language': instance.language,
      'PackCount': instance.packCount,
      'Details': instance.details,
    };

DthPlanDetail _$DthPlanDetailFromJson(Map<String, dynamic> json) =>
    DthPlanDetail(
      planName: json['PlanName'] as String,
      channels: json['Channels'] as String,
      paidChannels: json['PaidChannels'] as String,
      hdChannels: json['HdChannels'] as String,
      lastUpdate: json['last_update'] as String,
      pricingList: (json['PricingList'] as List<dynamic>)
          .map((e) => DthPricing.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DthPlanDetailToJson(DthPlanDetail instance) =>
    <String, dynamic>{
      'PlanName': instance.planName,
      'Channels': instance.channels,
      'PaidChannels': instance.paidChannels,
      'HdChannels': instance.hdChannels,
      'last_update': instance.lastUpdate,
      'PricingList': instance.pricingList,
    };

DthPricing _$DthPricingFromJson(Map<String, dynamic> json) => DthPricing(
      amount: json['Amount'] as String,
      month: json['Month'] as String,
    );

Map<String, dynamic> _$DthPricingToJson(DthPricing instance) =>
    <String, dynamic>{
      'Amount': instance.amount,
      'Month': instance.month,
    };

DthInfoResponse _$DthInfoResponseFromJson(Map<String, dynamic> json) =>
    DthInfoResponse(
      error: json['error'] as String,
      data: json['DATA'] == null
          ? null
          : DthInfoData.fromJson(json['DATA'] as Map<String, dynamic>),
      message: json['Message'] as String,
    );

Map<String, dynamic> _$DthInfoResponseToJson(DthInfoResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'DATA': instance.data,
      'Message': instance.message,
    };

DthInfoData _$DthInfoDataFromJson(Map<String, dynamic> json) => DthInfoData(
      vc: json['VC'] as String,
      name: json['Name'] as String,
      rmn: json['Rmn'] as String,
      balance: json['Balance'] as String,
      monthly: json['Monthly'] as String,
      nextRechargeDate: json['Next Recharge Date'] as String,
      plan: json['Plan'] as String,
      address: json['Address'] as String,
      city: json['City'] as String,
      district: json['District'] as String,
      state: json['State'] as String,
      pinCode: json['PIN Code'] as String,
    );

Map<String, dynamic> _$DthInfoDataToJson(DthInfoData instance) =>
    <String, dynamic>{
      'VC': instance.vc,
      'Name': instance.name,
      'Rmn': instance.rmn,
      'Balance': instance.balance,
      'Monthly': instance.monthly,
      'Next Recharge Date': instance.nextRechargeDate,
      'Plan': instance.plan,
      'Address': instance.address,
      'City': instance.city,
      'District': instance.district,
      'State': instance.state,
      'PIN Code': instance.pinCode,
    };

DthRechargeRequest _$DthRechargeRequestFromJson(Map<String, dynamic> json) =>
    DthRechargeRequest(
      dthNumber: json['dthNumber'] as String,
      operatorName: json['operatorName'] as String,
      planApiOperatorCode: json['planApiOperatorCode'] as String,
      roboticsOperatorCode: json['roboticsOperatorCode'] as String,
      amount: json['amount'] as String,
      planName: json['planName'] as String,
      duration: json['duration'] as String,
      channels: json['channels'] as String,
    );

Map<String, dynamic> _$DthRechargeRequestToJson(DthRechargeRequest instance) =>
    <String, dynamic>{
      'dthNumber': instance.dthNumber,
      'operatorName': instance.operatorName,
      'planApiOperatorCode': instance.planApiOperatorCode,
      'roboticsOperatorCode': instance.roboticsOperatorCode,
      'amount': instance.amount,
      'planName': instance.planName,
      'duration': instance.duration,
      'channels': instance.channels,
    };

PostpaidPlanInfo _$PostpaidPlanInfoFromJson(Map<String, dynamic> json) =>
    PostpaidPlanInfo(
      planName: json['planName'] as String,
      amount: json['amount'] as String,
      validity: json['validity'] as String,
      description: json['description'] as String,
      benefits:
          (json['benefits'] as List<dynamic>).map((e) => e as String).toList(),
      type: $enumDecode(_$RechargeTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$PostpaidPlanInfoToJson(PostpaidPlanInfo instance) =>
    <String, dynamic>{
      'planName': instance.planName,
      'amount': instance.amount,
      'validity': instance.validity,
      'description': instance.description,
      'benefits': instance.benefits,
      'type': _$RechargeTypeEnumMap[instance.type]!,
    };

const _$RechargeTypeEnumMap = {
  RechargeType.prepaid: 'prepaid',
  RechargeType.postpaid: 'postpaid',
  RechargeType.dth: 'dth',
};
