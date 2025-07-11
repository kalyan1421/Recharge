// JSON serialization will be handled manually for now

enum ServiceType { prepaid, postpaid, dth, datacard, electricity, gas, water, insurance }
enum OperatorType { jio, airtel, vi, bsnl, tata_sky, dish_tv, sun_direct, airtel_digital_tv }

class RechargeRequest {
  final String userId;
  final String mobile;
  final String operatorCode;
  final OperatorType operatorType;
  final ServiceType serviceType;
  final double amount;
  final String circle;
  final String? planId;
  final Map<String, dynamic>? additionalParams;
  final String requestId;
  final DateTime timestamp;

  const RechargeRequest({
    required this.userId,
    required this.mobile,
    required this.operatorCode,
    required this.operatorType,
    required this.serviceType,
    required this.amount,
    required this.circle,
    this.planId,
    this.additionalParams,
    required this.requestId,
    required this.timestamp,
  });

  factory RechargeRequest.fromJson(Map<String, dynamic> json) {
    return RechargeRequest(
      userId: json['userId'] ?? '',
      mobile: json['mobile'] ?? json['mobileNumber'] ?? '',
      operatorCode: json['operatorCode'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      serviceType: ServiceType.values.firstWhere(
        (e) => e.toString() == 'ServiceType.${json['serviceType']}',
        orElse: () => ServiceType.prepaid,
      ),
      operatorType: OperatorType.values.firstWhere(
        (e) => e.toString() == 'OperatorType.${json['operatorType']}',
        orElse: () => OperatorType.jio,
      ),
      circle: json['circle'] ?? '',
      planId: json['planId'],
      requestId: json['requestId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mobile': mobile,
      'operatorCode': operatorCode,
      'amount': amount,
      'serviceType': serviceType.toString().split('.').last,
      'operatorType': operatorType.toString().split('.').last,
      'circle': circle,
      'planId': planId,
      'requestId': requestId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class RechargeResponse {
  final String transactionId;
  final String status;
  final String message;
  final double amount;
  final double balance;
  final String? operatorTransactionId;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  const RechargeResponse({
    required this.transactionId,
    required this.status,
    required this.message,
    required this.amount,
    required this.balance,
    this.operatorTransactionId,
    required this.timestamp,
    this.additionalData,
  });

  factory RechargeResponse.fromJson(Map<String, dynamic> json) {
    return RechargeResponse(
      transactionId: json['transactionId'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      operatorTransactionId: json['operatorTransactionId'] ?? json['operatorRef'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'message': message,
      'amount': amount,
      'balance': balance,
      'operatorTransactionId': operatorTransactionId,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}

class PlanDetails {
  final String planId;
  final String operator;
  final String circle;
  final double amount;
  final String validity;
  final String description;
  final List<String> benefits;
  final String planType;
  final bool isTopup;
  final bool isSpecialRecharge;

  const PlanDetails({
    required this.planId,
    required this.operator,
    required this.circle,
    required this.amount,
    required this.validity,
    required this.description,
    required this.benefits,
    required this.planType,
    this.isTopup = false,
    this.isSpecialRecharge = false,
  });

  factory PlanDetails.fromJson(Map<String, dynamic> json) {
    return PlanDetails(
      planId: json['planId'] ?? '',
      operator: json['operator'] ?? '',
      circle: json['circle'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      validity: json['validity'] ?? '',
      description: json['description'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      planType: json['planType'] ?? 'regular',
      isTopup: json['isTopup'] ?? false,
      isSpecialRecharge: json['isSpecialRecharge'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'operator': operator,
      'circle': circle,
      'amount': amount,
      'validity': validity,
      'description': description,
      'benefits': benefits,
      'planType': planType,
      'isTopup': isTopup,
      'isSpecialRecharge': isSpecialRecharge,
    };
  }
} 