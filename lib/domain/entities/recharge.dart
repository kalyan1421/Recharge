import '../../data/models/recharge_request.dart';

enum RechargeStatus { pending, success, failed, cancelled }

class RechargeHistory {
  final String rechargeId;
  final String userId;
  final String mobile;
  final String operatorCode;
  final String operatorName;
  final ServiceType serviceType;
  final double amount;
  final RechargeStatus status;
  final DateTime timestamp;
  final String? operatorTransactionId;
  final String? planId;
  final String circle;

  const RechargeHistory({
    required this.rechargeId,
    required this.userId,
    required this.mobile,
    required this.operatorCode,
    required this.operatorName,
    required this.serviceType,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.operatorTransactionId,
    this.planId,
    required this.circle,
  });

  Map<String, dynamic> toJson() {
    return {
      'rechargeId': rechargeId,
      'userId': userId,
      'mobile': mobile,
      'operatorCode': operatorCode,
      'operatorName': operatorName,
      'serviceType': serviceType.toString().split('.').last,
      'amount': amount,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'operatorTransactionId': operatorTransactionId,
      'planId': planId,
      'circle': circle,
    };
  }

  factory RechargeHistory.fromJson(Map<String, dynamic> json) {
    return RechargeHistory(
      rechargeId: json['rechargeId'] ?? '',
      userId: json['userId'] ?? '',
      mobile: json['mobile'] ?? '',
      operatorCode: json['operatorCode'] ?? '',
      operatorName: json['operatorName'] ?? '',
      serviceType: ServiceType.values.firstWhere(
        (e) => e.toString() == 'ServiceType.${json['serviceType']}',
        orElse: () => ServiceType.prepaid,
      ),
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: RechargeStatus.values.firstWhere(
        (e) => e.toString() == 'RechargeStatus.${json['status']}',
        orElse: () => RechargeStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      operatorTransactionId: json['operatorTransactionId'],
      planId: json['planId'],
      circle: json['circle'] ?? '',
    );
  }
}

class Operator {
  final String code;
  final String name;
  final ServiceType type;

  const Operator({
    required this.code,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type.toString().split('.').last,
    };
  }

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: ServiceType.values.firstWhere(
        (e) => e.toString() == 'ServiceType.${json['type']}',
        orElse: () => ServiceType.prepaid,
      ),
    );
  }
} 