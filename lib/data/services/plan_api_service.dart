import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/operator_info.dart';
import '../models/mobile_plans.dart';

class IPBlockedException implements Exception {
  final String message;
  final String blockedIP;
  const IPBlockedException({required this.message, required this.blockedIP});
  @override
  String toString() => 'IPBlockedException: $message (IP: $blockedIP)';
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException({required this.message});
  @override
  String toString() => 'AuthenticationException: $message';
}

class InvalidMobileNumberException implements Exception {
  final String message;
  const InvalidMobileNumberException({required this.message});
  @override
  String toString() => 'InvalidMobileNumberException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
  @override
  String toString() => 'NetworkException: $message';
}

class PlanApiException implements Exception {
  final String message;
  const PlanApiException({required this.message});
  @override
  String toString() => 'PlanApiException: $message';
}

class PlanApiService {
  static final PlanApiService _instance = PlanApiService._internal();
  factory PlanApiService() => _instance;
  PlanApiService._internal();

  final Logger _logger = Logger();
  static const Duration _timeout = Duration(seconds: 30);

  Future<OperatorInfo> fetchOperatorAndCircle(String mobileNumber) async {
    try {
      if (!_isValidMobileNumber(mobileNumber)) {
        throw InvalidMobileNumberException(message: 'Invalid mobile number format. Please enter a valid 10-digit Indian mobile number.');
      }
      final cleanNumber = _cleanMobileNumber(mobileNumber);
      _logger.i('Fetching operator details for: ${_maskMobileNumber(cleanNumber)}');
      
      // Try API key format first
      try {
        _logger.d('Trying API key format for operator detection...');
        final response = await http.get(
          Uri.parse(APIConstants.operatorDetectionUrl).replace(queryParameters: {
            'apikey': APIConstants.apiToken,
            'mobileno': cleanNumber,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);
        
        _logger.d('API key Operator Response Status: ${response.statusCode}');
        _logger.d('API key Operator Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseText = response.body.toLowerCase();
          if (!responseText.contains('404') && !responseText.contains('not found') && 
              !responseText.contains('error') && responseText.contains('{')) {
            final Map<String, dynamic> apiResponse = json.decode(response.body);
            
            if (apiResponse['status'] == 'success' || apiResponse['Status'] == '1' || apiResponse['ERROR'] == '0') {
              final operatorInfo = _createOperatorInfoFromResponse(apiResponse, cleanNumber);
              _logger.i('✅ Operator detected via PlanAPI (API key): ${operatorInfo.operator}');
              return operatorInfo;
            }
          }
        }
      } catch (e) {
        _logger.w('API key format for operator detection failed: $e');
      }

      // Try userid/password format
      try {
        _logger.d('Trying userid/password format for operator detection...');
        final response = await http.get(
          Uri.parse(APIConstants.operatorDetectionUrl).replace(queryParameters: {
            'userid': APIConstants.apiUserId,
            'password': APIConstants.apiPassword,
            'format': 'json',
            'mobile': cleanNumber,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);
        
        _logger.d('Userid/password Operator Response Status: ${response.statusCode}');
        _logger.d('Userid/password Operator Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseText = response.body.toLowerCase();
          if (!responseText.contains('404') && !responseText.contains('not found') && 
              !responseText.contains('error') && responseText.contains('{')) {
            final Map<String, dynamic> apiResponse = json.decode(response.body);
            
            if (apiResponse['status'] == 'success' || apiResponse['Status'] == '1' || apiResponse['ERROR'] == '0') {
              final operatorInfo = _createOperatorInfoFromResponse(apiResponse, cleanNumber);
              _logger.i('✅ Operator detected via PlanAPI (userid/password): ${operatorInfo.operator}');
              return operatorInfo;
            }
          }
        }
      } catch (e) {
        _logger.w('Userid/password format for operator detection failed: $e');
      }
      
      // Fall back to intelligent detection with clear API status
      _logger.i('Using intelligent fallback detection (PlanAPI.in unavailable)');
      return _createIntelligentOperatorInfo(cleanNumber);
      
    } on IPBlockedException {
      rethrow;
    } on SocketException {
      _logger.e('🌐 Network connectivity issue');
      throw NetworkException(message: 'Please check your internet connection');
    } on TimeoutException {
      _logger.e('⏰ Request timeout');
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('💥 Unexpected error: $e');
      throw PlanApiException(message: 'Service temporarily unavailable: ${e.toString()}');
    }
  }

  /// Create intelligent operator info with API status
  OperatorInfo _createIntelligentOperatorInfo(String mobileNumber) {
    final operatorData = _detectOperatorFromPattern(mobileNumber);
    
    return OperatorInfo(
      mobile: mobileNumber,
      operator: operatorData['name']!,
      opCode: operatorData['code']!,
      circle: 'AP', // Default circle
      circleCode: '49', // Default circle code
      error: '0',
      status: '1',
      message: '⚠️ API Detection: Pattern-based (PlanAPI.in: Check credentials)',
    );
  }

  /// Enhanced operator detection from mobile number patterns
  Map<String, String> _detectOperatorFromPattern(String mobileNumber) {
    // Enhanced pattern matching based on Indian telecom numbering plan
    final prefix3 = mobileNumber.substring(0, 3);
    final prefix4 = mobileNumber.substring(0, 4);
    
    // Jio patterns (most comprehensive)
    if (_isJioNumber(mobileNumber)) {
      return {'name': 'Jio', 'code': '11'};
    }
    
    // Airtel patterns
    if (_isAirtelNumber(mobileNumber)) {
      return {'name': 'Airtel', 'code': '2'};
    }
    
    // Vi (Vodafone Idea) patterns
    if (_isViNumber(mobileNumber)) {
      return {'name': 'Vi', 'code': '23'};
    }
    
    // BSNL patterns
    if (_isBSNLNumber(mobileNumber)) {
      return {'name': 'BSNL', 'code': '5'};
    }
    
    // Default to Jio (most common)
    return {'name': 'Jio (Default)', 'code': '11'};
  }

  bool _isJioNumber(String number) {
    // Jio has the widest range of numbers
    final prefixes = ['630', '631', '632', '633', '634', '635', '636', '637', '638', '639',
                     '700', '701', '702', '703', '704', '705', '706', '707', '708', '709',
                     '810', '811', '812', '813', '814', '815', '816', '817', '818', '819',
                     '820', '821', '822', '823', '824', '825', '826', '827', '828', '829',
                     '860', '861', '862', '863', '864', '865', '866', '867', '868', '869',
                     '870', '871', '872', '873', '874', '875', '876', '877', '878', '879',
                     '880', '881', '882', '883', '884', '885', '886', '887', '888', '889',
                     '890', '891', '892', '893', '894', '895', '896', '897', '898', '899'];
    
    return prefixes.any((prefix) => number.startsWith(prefix));
  }

  bool _isAirtelNumber(String number) {
    // Airtel specific ranges
    final prefixes = ['701', '702', '703', '704', '705', '706', '707', '708', '709',
                     '780', '781', '782', '783', '784', '785', '786', '787', '788', '789',
                     '900', '901', '902', '903', '904', '905', '906', '907', '908', '909',
                     '630', '631', '632', '633', '634', '635', '636', '637', '638', '639'];
    
    return prefixes.any((prefix) => number.startsWith(prefix));
  }

  bool _isViNumber(String number) {
    // Vi (Vodafone Idea) ranges
    final prefixes = ['901', '902', '903', '904', '905', '906', '907', '908', '909',
                     '910', '911', '912', '913', '914', '915', '916', '917', '918', '919',
                     '920', '921', '922', '923', '924', '925', '926', '927', '928', '929',
                     '930', '931', '932', '933', '934', '935', '936', '937', '938', '939',
                     '940', '941', '942', '943', '944', '945', '946', '947', '948', '949'];
    
    return prefixes.any((prefix) => number.startsWith(prefix));
  }

  bool _isBSNLNumber(String number) {
    // BSNL specific ranges
    final prefixes = ['944', '945', '946', '947', '948', '949',
                     '950', '951', '952', '953', '954', '955', '956', '957', '958', '959'];
    
    return prefixes.any((prefix) => number.startsWith(prefix));
  }

  Future<MobilePlans?> fetchMobilePlans(String operatorCode, String circleCode) async {
    try {
      _logger.i('Fetching mobile plans for operator: $operatorCode, circle: $circleCode');
      
      // Try API key format first
      try {
        _logger.d('Trying API key format for plans...');
        final response = await http.get(
          Uri.parse(APIConstants.mobilePlansUrl).replace(queryParameters: {
            'apikey': APIConstants.apiToken,
            'operatorcode': operatorCode,
            'circle': circleCode,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);
        
        _logger.d('API key format Plans Response Status: ${response.statusCode}');
        _logger.d('API key format Plans Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseText = response.body.toLowerCase();
          if (!responseText.contains('404') && !responseText.contains('not found') && 
              !responseText.contains('error') && responseText.contains('{')) {
            final Map<String, dynamic> apiResponse = json.decode(response.body);
            
            if (apiResponse['status'] == 'success' || apiResponse['Status'] == '1' || apiResponse['ERROR'] == '0') {
              final mobilePlans = _createMobilePlansFromResponse(apiResponse);
              _logger.i('✅ Plans fetched via PlanAPI (API key): ${mobilePlans.plans.length} plans');
              return mobilePlans;
            }
          }
        }
      } catch (e) {
        _logger.w('API key format for plans failed: $e');
      }

      // Try userid/password format
      try {
        _logger.d('Trying userid/password format for plans...');
        final response = await http.get(
          Uri.parse(APIConstants.mobilePlansUrl).replace(queryParameters: {
            'userid': APIConstants.apiUserId,
            'password': APIConstants.apiPassword,
            'format': 'json',
            'operator': operatorCode,
            'circle': circleCode,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);
        
        _logger.d('Userid/password Plans Response Status: ${response.statusCode}');
        _logger.d('Userid/password Plans Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseText = response.body.toLowerCase();
          if (!responseText.contains('404') && !responseText.contains('not found') && 
              !responseText.contains('error') && responseText.contains('{')) {
            final Map<String, dynamic> apiResponse = json.decode(response.body);
            
            if (apiResponse['status'] == 'success' || apiResponse['Status'] == '1' || apiResponse['ERROR'] == '0') {
              final mobilePlans = _createMobilePlansFromResponse(apiResponse);
              _logger.i('✅ Plans fetched via PlanAPI (userid/password): ${mobilePlans.plans.length} plans');
              return mobilePlans;
            }
          }
        }
      } catch (e) {
        _logger.w('Userid/password format for plans failed: $e');
      }
      
      // Fall back to demo plans with clear API status
      _logger.i('Using demo plans (PlanAPI.in unavailable)');
      return _createDemoMobilePlans(operatorCode, circleCode);
      
    } on SocketException {
      _logger.e('🌐 Network connectivity issue');
      throw NetworkException(message: 'Please check your internet connection');
    } on TimeoutException {
      _logger.e('⏰ Request timeout');
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('💥 Unexpected error: $e');
      throw PlanApiException(message: 'Service temporarily unavailable: ${e.toString()}');
    }
  }

  /// Create demo mobile plans when API is unavailable
  MobilePlans _createDemoMobilePlans(String operatorCode, String circleCode) {
    final operatorName = _getOperatorName(operatorCode);
    
    return MobilePlans(
      error: '0',
      status: '1',
      message: '⚠️ Demo Plans (PlanAPI.in: Check credentials)',
      data: [
        // Popular Talk Time plans
        PlanItem(
          rs: 149,
          validity: '28 days',
          desc: 'Get ₹149 Talk Time with 28 days validity',
          type: 'Talk Time',
        ),
        PlanItem(
          rs: 79,
          validity: '28 days',
          desc: 'Get ₹79 Talk Time with 28 days validity',
          type: 'Talk Time',
        ),
        
        // Popular Data plans  
        PlanItem(
          rs: 239,
          validity: '28 days',
          desc: '1GB/Day + Unlimited Calling',
          type: 'Data',
        ),
        PlanItem(
          rs: 299,
          validity: '28 days',
          desc: '1.5GB/Day + Unlimited Calling',
          type: 'Data',
        ),
        PlanItem(
          rs: 449,
          validity: '56 days',
          desc: '2GB/Day + Unlimited Calling',
          type: 'Data',
        ),
        
        // Popular Unlimited plans
        PlanItem(
          rs: 399,
          validity: '28 days',
          desc: 'Unlimited Everything',
          type: 'Unlimited',
        ),
        PlanItem(
          rs: 599,
          validity: '56 days',
          desc: 'Unlimited Everything + OTT',
          type: 'Unlimited',
        ),
      ],
    );
  }

  String _getOperatorName(String operatorCode) {
    switch (operatorCode) {
      case '2': return 'Airtel';
      case '11': return 'Jio';
      case '23': return 'Vi';
      case '5': return 'BSNL';
      default: return 'Unknown';
    }
  }

  // Helper methods
  bool _isValidMobileNumber(String mobileNumber) {
    final cleanNumber = _cleanMobileNumber(mobileNumber);
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(cleanNumber);
  }

  String _cleanMobileNumber(String mobileNumber) {
    return mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }

  OperatorInfo _createOperatorInfoFromResponse(Map<String, dynamic> data, String mobile) {
    return OperatorInfo(
      mobile: mobile,
      operator: data['Operator']?.toString() ?? 'Unknown',
      opCode: data['OpCode']?.toString() ?? '0',
      circle: data['Circle']?.toString() ?? 'Unknown',
      circleCode: data['CircleCode']?.toString(),
      error: data['ERROR']?.toString() ?? '1',
      status: data['STATUS']?.toString() ?? '0',
      message: data['Message']?.toString() ?? data['MESSAGE']?.toString() ?? 'Success',
    );
  }

  MobilePlans _parseNewApiResponse(Map<String, dynamic> rData) {
    final List<PlanItem> data = [];
    final List<PlanItem> trulyUnlimited = [];
    final List<PlanItem> talktime = [];
    final List<PlanItem> cricketPacks = [];
    final List<PlanItem> planVouchers = [];
    final List<PlanItem> roamingPacks = [];
    
    rData.forEach((key, value) {
      if (value is List) {
        final plans = value
            .map((item) => _parsePlanItem(item))
            .where((item) => item != null)
            .cast<PlanItem>()
            .toList();
        
        switch (key.toLowerCase()) {
          case 'data':
            data.addAll(plans);
            break;
          case 'truly unlimited':
            trulyUnlimited.addAll(plans);
            break;
          case 'talktime (top up voucher)':
          case 'talktime':
            talktime.addAll(plans);
            break;
          case 'cricket packs':
            cricketPacks.addAll(plans);
            break;
          case 'plan vouchers':
            planVouchers.addAll(plans);
            break;
          case 'inflight roaming packs':
          case 'roaming packs':
            roamingPacks.addAll(plans);
            break;
          case 'popular plans':
            data.addAll(plans);
            break;
          default:
            // Add all unknown categories to data as well
            data.addAll(plans);
            break;
        }
      }
    });
    
    return MobilePlans(
      data: data,
      trulyUnlimited: trulyUnlimited,
      talktime: talktime,
      cricketPacks: cricketPacks,
      planVouchers: planVouchers,
      roamingPacks: roamingPacks,
      status: 'SUCCESS',
      message: 'Plans fetched successfully',
    );
  }

  PlanItem? _parsePlanItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      try {
        final rs = item['rs'];
        final amount = rs is String ? int.tryParse(rs) ?? 0 : (rs?.toInt() ?? 0);
        
        if (amount > 0) {
          return PlanItem(
            rs: amount,
            validity: item['validity']?.toString() ?? '',
            desc: item['desc']?.toString() ?? '',
          );
        }
      } catch (e) {
        _logger.w('Error parsing plan item: $e');
      }
    }
    return null;
  }

  bool _isPopularPlan(int amount) {
    // Define popular plan ranges
    const popularRanges = [149, 199, 239, 299, 399, 449, 499, 599, 699, 799];
    return popularRanges.any((range) => (amount - range).abs() <= 50);
  }

  Future<List<SpecialOffer>> fetchRoffers(String operatorCode, String circleCode) async {
    try {
      _logger.i('Fetching R-offers for operator: $operatorCode, circle: $circleCode');
      
      // Try PlanAPI.in endpoint first
      try {
        final uri = Uri.parse(APIConstants.roffersUrl)
            .replace(queryParameters: {
          'userid': APIConstants.apiUserId,
          'password': APIConstants.apiPassword,
          'format': 'json',
          'operator': operatorCode,
          'circle': circleCode,
        });
        
        _logger.d('Testing PlanAPI.in R-offers URL: $uri');
        
        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${APIConstants.apiToken}',
          },
        ).timeout(_timeout);
        
        _logger.d('PlanAPI R-offers Response Status: ${response.statusCode}');
        _logger.d('PlanAPI R-offers Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseText = response.body.toLowerCase();
          if (!responseText.contains('404') && !responseText.contains('not found') && 
              !responseText.contains('error') && responseText.contains('{')) {
            final Map<String, dynamic> apiResponse = json.decode(response.body);
            
            if (apiResponse['ERROR'] == '0' && apiResponse['STATUS'] == '1') {
              final rOffers = _createRoffersFromResponse(apiResponse);
              _logger.i('✅ R-offers fetched via PlanAPI: ${rOffers.length} offers');
              return rOffers;
            }
          }
        }
      } catch (e) {
        _logger.w('PlanAPI.in R-offers endpoint is not accessible: $e');
      }
      
      // Fall back to demo R-offers with clear API status
      _logger.i('Using demo R-offers (PlanAPI.in unavailable)');
      return _createDemoRoffers(operatorCode, circleCode);
      
    } on SocketException {
      _logger.e('🌐 Network connectivity issue');
      throw NetworkException(message: 'Please check your internet connection');
    } on TimeoutException {
      _logger.e('⏰ Request timeout');
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('💥 Unexpected error: $e');
      throw PlanApiException(message: 'Service temporarily unavailable: ${e.toString()}');
    }
  }

  /// Create demo R-offers when API is unavailable
  List<SpecialOffer> _createDemoRoffers(String operatorCode, String circleCode) {
    final operatorName = _getOperatorName(operatorCode);
    
    return [
      SpecialOffer(
        operator: operatorName,
        circle: 'AP',
        planId: 'DEMO_RO_95',
        planName: 'R-Offer ₹95',
        description: 'Special Offer - 2GB Data + Unlimited Calls',
        amount: 95,
        validity: '28 days',
        planDetails: '⚠️ Demo R-offer: 2GB Data + Unlimited calls + 100 SMS/Day (PlanAPI.in: Check credentials)',
        planType: 'Special',
        planCategory: 'R-Offer',
      ),
      SpecialOffer(
        operator: operatorName,
        circle: 'AP',
        planId: 'DEMO_RO_155',
        planName: 'R-Offer ₹155',
        description: 'Special Offer - 1GB/Day + Unlimited Calls',
        amount: 155,
        validity: '24 days',
        planDetails: '⚠️ Demo R-offer: 1GB/Day Data + Unlimited calls + 100 SMS/Day (PlanAPI.in: Check credentials)',
        planType: 'Special',
        planCategory: 'R-Offer',
      ),
      SpecialOffer(
        operator: operatorName,
        circle: 'AP',
        planId: 'DEMO_RO_319',
        planName: 'R-Offer ₹319',
        description: 'Special Offer - 2GB/Day + Unlimited Calls',
        amount: 319,
        validity: '30 days',
        planDetails: '⚠️ Demo R-offer: 2GB/Day Data + Unlimited calls + 100 SMS/Day (PlanAPI.in: Check credentials)',
        planType: 'Special',
        planCategory: 'R-Offer',
      ),
    ];
  }

  /// Create MobilePlans from API response
  MobilePlans _createMobilePlansFromResponse(Map<String, dynamic> apiResponse) {
    final rData = apiResponse['RDATA'] as Map<String, dynamic>?;
    if (rData == null) {
      throw PlanApiException(message: 'No plan data received from API');
    }
    
    final plans = <Plan>[];
    
    // Parse different plan types if available
    if (rData['FULLTT'] != null) {
      final fullTTPlans = rData['FULLTT'] as List<dynamic>;
      for (final planData in fullTTPlans) {
        plans.add(_createPlanFromApiData(planData, 'Talk Time'));
      }
    }
    
    if (rData['TOPUP'] != null) {
      final topupPlans = rData['TOPUP'] as List<dynamic>;
      for (final planData in topupPlans) {
        plans.add(_createPlanFromApiData(planData, 'Top Up'));
      }
    }
    
    if (rData['3G'] != null) {
      final dataPlans = rData['3G'] as List<dynamic>;
      for (final planData in dataPlans) {
        plans.add(_createPlanFromApiData(planData, 'Data'));
      }
    }
    
    return MobilePlans(
      error: apiResponse['ERROR']?.toString() ?? '0',
      status: apiResponse['STATUS']?.toString() ?? '1',
      message: apiResponse['MESSAGE']?.toString() ?? 'Plans loaded successfully',
      data: plans.map((plan) => PlanItem(
        rs: plan.planPrice.toInt(),
        validity: plan.planValidity,
        desc: plan.planDescription,
        type: plan.planType,
      )).toList(),
    );
  }

  /// Create a Plan from API data
  Plan _createPlanFromApiData(dynamic planData, String planType) {
    final data = planData as Map<String, dynamic>;
    
    return Plan(
      operator: data['operator'] ?? 'Unknown',
      circle: data['circle'] ?? 'Unknown',
      planId: data['plancode'] ?? data['id'] ?? 'unknown',
      planName: data['desc'] ?? data['description'] ?? 'Plan ${data['rs'] ?? 'Unknown'}',
      planDescription: data['desc'] ?? data['description'] ?? 'Plan details',
      planPrice: double.tryParse(data['rs']?.toString() ?? '0') ?? 0.0,
      planValidity: data['validity'] ?? 'Unknown',
      planDetails: data['detail'] ?? data['desc'] ?? 'Plan details',
      planType: planType,
      planCategory: planType,
    );
  }

  /// Create R-offers from API response
  List<SpecialOffer> _createRoffersFromResponse(Map<String, dynamic> apiResponse) {
    final rData = apiResponse['RDATA'] as Map<String, dynamic>?;
    if (rData == null) {
      throw PlanApiException(message: 'No R-offer data received from API');
    }
    
    final offers = <SpecialOffer>[];
    
    // Parse R-offers if available
    if (rData['ROFFER'] != null) {
      final rofferData = rData['ROFFER'] as List<dynamic>;
      for (final offerData in rofferData) {
        offers.add(_createRofferFromApiData(offerData));
      }
    }
    
    return offers;
  }

  /// Create a SpecialOffer from API data
  SpecialOffer _createRofferFromApiData(dynamic offerData) {
    final data = offerData as Map<String, dynamic>;
    
    return SpecialOffer(
      operator: data['operator'] ?? 'Unknown',
      circle: data['circle'] ?? 'Unknown',
      planId: data['plancode'] ?? data['id'] ?? 'unknown',
      planName: data['desc'] ?? data['description'] ?? 'R-Offer ${data['rs'] ?? 'Unknown'}',
      description: data['desc'] ?? data['description'] ?? 'Special offer',
      amount: int.tryParse(data['rs']?.toString() ?? '0') ?? 0,
      validity: data['validity'] ?? 'Unknown',
      planDetails: data['detail'] ?? data['desc'] ?? 'Special offer details',
      planType: 'Special',
      planCategory: 'R-Offer',
    );
  }
} 