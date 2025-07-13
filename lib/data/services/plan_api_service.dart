import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/mobile_plans.dart';
import '../models/operator_info.dart';
import 'proxy_service.dart';

class PlanApiService {
  final ProxyService _proxyService;
  final Logger _logger = Logger();

  PlanApiService({ProxyService? proxyService}) 
      : _proxyService = proxyService ?? ProxyService();

  /// Fetch mobile plans for a specific operator and circle
  Future<MobilePlansResponse> fetchMobilePlans({
    required String operatorCode,
    required String circleCode,
  }) async {
    try {
      _logger.i('Fetching mobile plans for operator: $operatorCode, circle: $circleCode');

      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }

      // Make API request through proxy
      final response = await _proxyService.get(
        '/Mobile/NewMobilePlans',
        queryParameters: {
          'apimember_id': APIConstants.planApiUserId,
          'api_password': APIConstants.planApiPassword,
          'operatorcode': operatorCode,
          'cricle': circleCode, // Note: API uses 'cricle' not 'circle'
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Check for API-level errors
        if (data['ERROR'] == '1' && data['STATUS'] == '3') {
          throw Exception('Authentication failed: ${data['MESSAGE'] ?? 'Invalid credentials'}');
        }
        
        final plansResponse = MobilePlansResponse.fromJson(data);
        
        if (plansResponse.isSuccess) {
          _logger.i('✅ Mobile plans fetched successfully');
          _logger.i('Operator: ${plansResponse.operator}, Circle: ${plansResponse.circle}');
          
          if (plansResponse.rdata != null) {
            final categories = plansResponse.rdata!.getAllCategories();
            _logger.i('Found ${categories.length} plan categories');
            for (var category in categories) {
              _logger.i('- ${category.name}: ${category.plans.length} plans');
            }
          }
        } else {
          throw Exception(plansResponse.message);
        }
        
        return plansResponse;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch mobile plans: $e');
      throw Exception('Failed to fetch mobile plans: $e');
    }
  }

  /// Alias method for backward compatibility
  Future<MobilePlansResponse> getMobilePlans({
    required String operatorCode,
    required String circleCode,
  }) async {
    // Convert circle name to circle code if needed
    String actualCircleCode = circleCode;
    
    // If circleCode contains a name instead of a code, convert it
    if (circleCode.contains(' ') || circleCode.length > 3) {
      actualCircleCode = APIConstants.getCircleCode(circleCode);
      _logger.i('Converted circle name "$circleCode" to circle code "$actualCircleCode"');
    }
    
    return fetchMobilePlans(
      operatorCode: operatorCode,
      circleCode: actualCircleCode,
    );
  }

  /// Fetch R-offers for a specific operator and mobile number
  /// Note: R-offers work only for Airtel and VI (Vodafone Idea), not for Jio
  Future<ROfferResponse> fetchROffers({
    required String operatorCode,
    required String mobileNumber,
  }) async {
    try {
      _logger.i('Fetching R-offers for operator: $operatorCode, mobile: ${_maskMobileNumber(mobileNumber)}');

      // Clean mobile number
      String cleanNumber = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanNumber.startsWith('91')) {
        cleanNumber = cleanNumber.substring(2);
      }
      if (cleanNumber.length != 10) {
        throw Exception('Invalid mobile number length');
      }

      // Check if operator supports R-offers
      final operatorName = APIConstants.getOperatorName(operatorCode).toLowerCase();
      if (!operatorName.contains('airtel') && !operatorName.contains('vodafone') && !operatorName.contains('idea')) {
        throw Exception('R-offers are only available for Airtel and VI (Vodafone Idea) operators');
      }

      // Test proxy connection first
      final isProxyConnected = await _proxyService.testConnection();
      if (!isProxyConnected) {
        throw Exception('Cannot connect to proxy server at ${ProxyService.proxyHost}:${ProxyService.proxyPort}');
      }

      // Make API request through proxy
      final response = await _proxyService.get(
        '/Mobile/RofferCheck',
        queryParameters: {
          'apimember_id': APIConstants.planApiUserId,
          'api_password': APIConstants.planApiPassword,
          'operator_code': operatorCode,
          'mobile_no': cleanNumber,
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Check for API-level errors
        if (data['ERROR'] == '1' && data['STATUS'] == '3') {
          throw Exception('Authentication failed: ${data['MESSAGE'] ?? 'Invalid credentials'}');
        }
        
        final rOfferResponse = ROfferResponse.fromJson(data);
        
        if (rOfferResponse.isSuccess) {
          _logger.i('✅ R-offers fetched successfully');
          _logger.i('Mobile: ${rOfferResponse.mobileNo}');
          
          if (rOfferResponse.rdata != null) {
            _logger.i('Found ${rOfferResponse.rdata!.length} R-offers');
          }
        } else {
          throw Exception(rOfferResponse.message);
        }
        
        return rOfferResponse;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch R-offers: $e');
      throw Exception('Failed to fetch R-offers: $e');
    }
  }

  /// Fetch mobile plans using operator info
  Future<MobilePlansResponse> fetchMobilePlansFromOperatorInfo(OperatorInfo operatorInfo) async {
    return getMobilePlans(
      operatorCode: operatorInfo.opCode,
      circleCode: operatorInfo.circleCode,
    );
  }

  /// Fetch R-offers using operator info
  Future<ROfferResponse> fetchROffersFromOperatorInfo({
    required OperatorInfo operatorInfo,
    required String mobileNumber,
  }) async {
    return fetchROffers(
      operatorCode: operatorInfo.opCode,
      mobileNumber: mobileNumber,
    );
  }

  void dispose() {
    _proxyService.dispose();
  }

  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }

  /// Alias method for backward compatibility
  Future<ROfferResponse> getROffers({
    required OperatorInfo operatorInfo,
    required String mobileNumber,
  }) async {
    return fetchROffersFromOperatorInfo(
      operatorInfo: operatorInfo,
      mobileNumber: mobileNumber,
    );
  }
}
