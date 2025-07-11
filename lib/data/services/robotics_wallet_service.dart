import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';

class RoboticsWalletService {
  static final RoboticsWalletService _instance = RoboticsWalletService._internal();
  factory RoboticsWalletService() => _instance;
  RoboticsWalletService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  /// Check wallet balance using robotics exchange API
  Future<WalletBalanceResponse> checkWalletBalance() async {
    try {
      _logger.i('Checking wallet balance with Robotics Exchange');

      final url = Uri.parse(APIConstants.roboticsWalletBalanceUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
      });

      _logger.d('Wallet Balance URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Wallet Balance Response Status: ${response.statusCode}');
      _logger.d('Wallet Balance Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        final message = apiResponse['Message']?.toString() ?? 'Unknown error';

        if (errorCode == '0' && status == '1') {
          // Success case
          final buyerBalance = double.tryParse(apiResponse['BuyerWalletBalance']?.toString() ?? '0') ?? 0.0;
          final sellerBalance = double.tryParse(apiResponse['SellerWalletBalance']?.toString() ?? '0') ?? 0.0;

          return WalletBalanceResponse(
            success: true,
            buyerBalance: buyerBalance,
            sellerBalance: sellerBalance,
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        } else {
          // Error case
          return WalletBalanceResponse(
            success: false,
            buyerBalance: 0.0,
            sellerBalance: 0.0,
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking wallet balance: $e');
      return WalletBalanceResponse(
        success: false,
        buyerBalance: 0.0,
        sellerBalance: 0.0,
        message: 'Failed to check wallet balance: ${e.toString()}',
        timestamp: DateTime.now(),
        errorCode: '999',
        status: '3',
      );
    }
  }

  /// Check operator balances using robotics exchange API
  Future<OperatorBalanceResponse> checkOperatorBalances() async {
    try {
      _logger.i('Checking operator balances with Robotics Exchange');

      final url = Uri.parse(APIConstants.roboticsOperatorBalanceUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
      });

      _logger.d('Operator Balance URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Operator Balance Response Status: ${response.statusCode}');
      _logger.d('Operator Balance Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        final message = apiResponse['Message']?.toString() ?? 'Unknown error';

        if (errorCode == '0' && status == '1') {
          // Success case
          final record = apiResponse['Record'] as Map<String, dynamic>? ?? {};
          
          return OperatorBalanceResponse(
            success: true,
            balances: record,
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        } else {
          // Error case
          return OperatorBalanceResponse(
            success: false,
            balances: {},
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking operator balances: $e');
      return OperatorBalanceResponse(
        success: false,
        balances: {},
        message: 'Failed to check operator balances: ${e.toString()}',
        timestamp: DateTime.now(),
        errorCode: '999',
        status: '3',
      );
    }
  }

  /// Check lapu-wise balance for specific operator
  Future<LapuBalanceResponse> checkLapuBalance(String operatorCode) async {
    try {
      _logger.i('Checking lapu balance for operator: $operatorCode');

      final url = Uri.parse(APIConstants.roboticsLapuBalanceUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Operator_code': operatorCode,
      });

      _logger.d('Lapu Balance URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Lapu Balance Response Status: ${response.statusCode}');
      _logger.d('Lapu Balance Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        final message = apiResponse['Message']?.toString() ?? 'Unknown error';

        if (errorCode == '0' && status == '1') {
          // Success case
          final lapuData = apiResponse['LapuData'] as List<dynamic>? ?? [];
          
          return LapuBalanceResponse(
            success: true,
            lapuData: lapuData.map((item) => item as Map<String, dynamic>).toList(),
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        } else {
          // Error case
          return LapuBalanceResponse(
            success: false,
            lapuData: [],
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking lapu balance: $e');
      return LapuBalanceResponse(
        success: false,
        lapuData: [],
        message: 'Failed to check lapu balance: ${e.toString()}',
        timestamp: DateTime.now(),
        errorCode: '999',
        status: '3',
      );
    }
  }

  /// Check lapu purchase for Airtel and Idea
  Future<LapuPurchaseResponse> checkLapuPurchase(String lapuNumber, String operatorCode) async {
    try {
      _logger.i('Checking lapu purchase for number: $lapuNumber, operator: $operatorCode');

      final url = Uri.parse(APIConstants.roboticsLapuPurchaseUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'LapuNumber': lapuNumber,
        'Operator_code': operatorCode,
      });

      _logger.d('Lapu Purchase URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Lapu Purchase Response Status: ${response.statusCode}');
      _logger.d('Lapu Purchase Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        final message = apiResponse['Message']?.toString() ?? 'Unknown error';

        if (errorCode == '0' && status == '1') {
          // Success case
          return LapuPurchaseResponse(
            success: true,
            purchaseData: apiResponse,
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        } else {
          // Error case
          return LapuPurchaseResponse(
            success: false,
            purchaseData: {},
            message: message,
            timestamp: DateTime.now(),
            errorCode: errorCode,
            status: status,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error checking lapu purchase: $e');
      return LapuPurchaseResponse(
        success: false,
        purchaseData: {},
        message: 'Failed to check lapu purchase: ${e.toString()}',
        timestamp: DateTime.now(),
        errorCode: '999',
        status: '3',
      );
    }
  }

  /// Update IP address for API access
  Future<IpUpdateResponse> updateIpAddress(String ipAddress) async {
    try {
      _logger.i('Updating IP address: $ipAddress');

      final url = Uri.parse(APIConstants.roboticsIpUpdateUrl).replace(queryParameters: {
        'Apimember_id': APIConstants.roboticsApiMemberId,
        'Api_password': APIConstants.roboticsApiPassword,
        'Ipaddress': ipAddress,
      });

      _logger.d('IP Update URL: $url');

      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      _logger.d('IP Update Response Status: ${response.statusCode}');
      _logger.d('IP Update Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = response.data as Map<String, dynamic>;

        final errorCode = apiResponse['Errorcode']?.toString() ?? '1';
        final status = apiResponse['Status']?.toString() ?? '3';
        final message = apiResponse['Message']?.toString() ?? 'Unknown error';

        return IpUpdateResponse(
          success: errorCode == '0' && status == '1',
          message: message,
          timestamp: DateTime.now(),
          errorCode: errorCode,
          status: status,
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error updating IP address: $e');
      return IpUpdateResponse(
        success: false,
        message: 'Failed to update IP address: ${e.toString()}',
        timestamp: DateTime.now(),
        errorCode: '999',
        status: '3',
      );
    }
  }
}

/// Response classes for wallet operations
class WalletBalanceResponse {
  final bool success;
  final double buyerBalance;
  final double sellerBalance;
  final String message;
  final DateTime timestamp;
  final String errorCode;
  final String status;

  WalletBalanceResponse({
    required this.success,
    required this.buyerBalance,
    required this.sellerBalance,
    required this.message,
    required this.timestamp,
    required this.errorCode,
    required this.status,
  });
}

class OperatorBalanceResponse {
  final bool success;
  final Map<String, dynamic> balances;
  final String message;
  final DateTime timestamp;
  final String errorCode;
  final String status;

  OperatorBalanceResponse({
    required this.success,
    required this.balances,
    required this.message,
    required this.timestamp,
    required this.errorCode,
    required this.status,
  });
}

class LapuBalanceResponse {
  final bool success;
  final List<Map<String, dynamic>> lapuData;
  final String message;
  final DateTime timestamp;
  final String errorCode;
  final String status;

  LapuBalanceResponse({
    required this.success,
    required this.lapuData,
    required this.message,
    required this.timestamp,
    required this.errorCode,
    required this.status,
  });
}

class LapuPurchaseResponse {
  final bool success;
  final Map<String, dynamic> purchaseData;
  final String message;
  final DateTime timestamp;
  final String errorCode;
  final String status;

  LapuPurchaseResponse({
    required this.success,
    required this.purchaseData,
    required this.message,
    required this.timestamp,
    required this.errorCode,
    required this.status,
  });
}

class IpUpdateResponse {
  final bool success;
  final String message;
  final DateTime timestamp;
  final String errorCode;
  final String status;

  IpUpdateResponse({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.errorCode,
    required this.status,
  });
} 