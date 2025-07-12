import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/operator_info.dart';

class OperatorDetectionService {
  static final OperatorDetectionService _instance = OperatorDetectionService._internal();
  factory OperatorDetectionService() => _instance;
  OperatorDetectionService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();

  /// Auto-detect operator and circle from mobile number using PlanAPI.in
  Future<OperatorInfo?> detectOperator(String mobileNumber) async {
    try {
      // Validate mobile number
      if (!_isValidMobileNumber(mobileNumber)) {
        throw Exception('Invalid mobile number format. Please enter a valid 10-digit Indian mobile number.');
      }

      // Clean mobile number (remove spaces, +91, etc.)
      final cleanNumber = _cleanMobileNumber(mobileNumber);
      
      _logger.i('Detecting operator for mobile number: ${_maskMobileNumber(cleanNumber)}');

      // Try API key format first
      try {
        _logger.d('Trying API key format...');
        final response = await _dio.get(
          APIConstants.operatorDetectionUrl,
          queryParameters: {
            'apikey': APIConstants.apiToken,
            'mobileno': cleanNumber,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        _logger.d('API key format response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200 && response.data != null) {
          final responseData = response.data;
          
          // Check if API returned success
          if (responseData['status'] == 'success' || responseData['Status'] == '1' || responseData['ERROR'] == '0') {
            final operatorInfo = OperatorInfo(
              mobile: cleanNumber,
              operator: responseData['Operator'] ?? responseData['operator'] ?? 'Unknown',
              opCode: responseData['OpCode'] ?? responseData['operator_code'] ?? '11',
              circle: responseData['Circle'] ?? responseData['circle'] ?? 'AP',
              circleCode: responseData['CircleCode'] ?? responseData['circle_code'] ?? '49',
              error: '0',
              status: '1',
              message: 'Operator detected successfully',
            );
            
            _logger.i('✅ Operator detected successfully: ${operatorInfo.operator} (${operatorInfo.opCode}) - ${operatorInfo.circle}');
            return operatorInfo;
          }
        }
      } catch (e) {
        _logger.w('API key format failed: $e');
      }

      // Try original userid/password format
      try {
        _logger.d('Trying userid/password format...');
        final response = await _dio.get(
          APIConstants.operatorDetectionUrl,
          queryParameters: {
            'userid': APIConstants.apiUserId,
            'password': APIConstants.apiPassword,
            'format': 'json',
            'mobile': cleanNumber,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        _logger.d('Userid/password format response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200 && response.data != null) {
          final responseData = response.data;
          
          // Check if API returned success
          if (responseData['status'] == 'success' || responseData['Status'] == '1' || responseData['ERROR'] == '0') {
            final operatorInfo = OperatorInfo(
              mobile: cleanNumber,
              operator: responseData['Operator'] ?? responseData['operator'] ?? 'Unknown',
              opCode: responseData['OpCode'] ?? responseData['operator_code'] ?? '11',
              circle: responseData['Circle'] ?? responseData['circle'] ?? 'AP',
              circleCode: responseData['CircleCode'] ?? responseData['circle_code'] ?? '49',
              error: '0',
              status: '1',
              message: 'Operator detected successfully',
            );
            
            _logger.i('✅ Operator detected successfully: ${operatorInfo.operator} (${operatorInfo.opCode}) - ${operatorInfo.circle}');
            return operatorInfo;
          }
        }
      } catch (e) {
        _logger.w('Userid/password format failed: $e');
      }

      // If both API calls fail, use intelligent detection
      _logger.i('Both API formats failed, using intelligent fallback detection');
      return _createIntelligentOperatorInfo(mobileNumber);
      
    } catch (e) {
      _logger.e('❌ Operator detection failed: $e');
      
      // Fallback to intelligent detection
      _logger.i('Using intelligent fallback detection');
      return _createIntelligentOperatorInfo(mobileNumber);
    }
  }

  /// Create intelligent operator info based on mobile number patterns
  OperatorInfo _createIntelligentOperatorInfo(String mobileNumber) {
    final cleanNumber = _cleanMobileNumber(mobileNumber);
    final operatorData = _detectOperatorFromPattern(cleanNumber);
    
    return OperatorInfo(
      mobile: cleanNumber,
      operator: operatorData['name']!,
      opCode: operatorData['code']!,
      circle: 'AP', // Default circle
      circleCode: '49', // Default circle code
      error: '0',
      status: '1',
      message: '⚠️ Pattern-based detection (API unavailable)',
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

  /// Validate mobile number format
  bool _isValidMobileNumber(String mobileNumber) {
    final cleanNumber = _cleanMobileNumber(mobileNumber);
    // Valid Indian mobile numbers start with 6, 7, 8, or 9 and have 10 digits
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(cleanNumber);
  }

  /// Clean mobile number by removing non-digit characters
  String _cleanMobileNumber(String mobileNumber) {
    // Remove all non-digit characters
    String cleaned = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove country code if present
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    
    return cleaned;
  }

  /// Mask mobile number for logging privacy
  String _maskMobileNumber(String mobileNumber) {
    if (mobileNumber.length >= 10) {
      return '${mobileNumber.substring(0, 3)}***${mobileNumber.substring(7)}';
    }
    return mobileNumber;
  }

  /// Get available operators (demo data when API unavailable)
  Future<List<String>> getAvailableOperators() async {
    try {
      _logger.i('Fetching available operators');
      
      // Fall back to demo data
      _logger.i('Using demo operator list');
      return [
        'Airtel',
        'Jio',
        'Vi',
        'BSNL',
        'Idea',
      ];
    } catch (e) {
      _logger.e('Error fetching operators: $e');
      return ['Airtel', 'Jio', 'Vi', 'BSNL']; // Default fallback
    }
  }

  /// Get available circles (demo data when API unavailable)
  Future<List<String>> getAvailableCircles() async {
    try {
      _logger.i('Fetching available circles');
      
      // Fall back to demo data since API doesn't provide circle list
      _logger.i('Using demo circle list');
      return [
        'Andhra Pradesh',
        'Assam',
        'Bihar',
        'Chennai',
        'Delhi',
        'Gujarat',
        'Haryana',
        'Himachal Pradesh',
        'Jammu Kashmir',
        'Karnataka',
        'Kerala',
        'Kolkata',
        'Madhya Pradesh',
        'Maharashtra',
        'Mumbai',
        'North East',
        'Orissa',
        'Punjab',
        'Rajasthan',
        'Tamil Nadu',
        'UP East',
        'UP West',
        'West Bengal',
      ];
    } catch (e) {
      _logger.e('Error fetching circles: $e');
      return ['Andhra Pradesh', 'Delhi', 'Mumbai', 'Karnataka']; // Default fallback
    }
  }

  /// Create manual operator info for user selection
  OperatorInfo createManualOperatorInfo(String mobileNumber, String operatorName, String circleName) {
    try {
      _logger.i('Creating manual operator info: $operatorName, $circleName');
      
      // Get operator code from name
      final operatorCode = _getOperatorCodeFromName(operatorName);
      final circleCode = _getCircleCodeFromName(circleName);
      
      return OperatorInfo(
        mobile: mobileNumber,
        operator: operatorName,
        opCode: operatorCode,
        circle: circleName,
        circleCode: circleCode,
        error: '0',
        status: '1',
        message: '✅ Manual Selection: $operatorName - $circleName',
      );
    } catch (e) {
      _logger.e('Error creating manual operator info: $e');
      // Return default fallback
      return OperatorInfo(
        mobile: mobileNumber,
        operator: 'Jio',
        opCode: '11',
        circle: 'Andhra Pradesh',
        circleCode: '49',
        error: '0',
        status: '1',
        message: '⚠️ Default Selection: Jio - Andhra Pradesh',
      );
    }
  }

  /// Get operator code from name
  String _getOperatorCodeFromName(String operatorName) {
    switch (operatorName.toLowerCase()) {
      case 'airtel':
        return '2';
      case 'jio':
        return '11';
      case 'vi':
      case 'vodafone':
        return '23';
      case 'idea':
        return '6';
      case 'bsnl':
        return '5';
      default:
        return '11'; // Default to Jio
    }
  }

  /// Get circle code from name
  String _getCircleCodeFromName(String circleName) {
    switch (circleName.toLowerCase()) {
      case 'andhra pradesh':
        return '49';
      case 'assam':
        return '51';
      case 'bihar':
        return '52';
      case 'chennai':
        return '53';
      case 'delhi':
        return '54';
      case 'gujarat':
        return '55';
      case 'haryana':
        return '56';
      case 'himachal pradesh':
        return '57';
      case 'jammu kashmir':
        return '58';
      case 'karnataka':
        return '59';
      case 'kerala':
        return '60';
      case 'kolkata':
        return '61';
      case 'madhya pradesh':
        return '62';
      case 'maharashtra':
        return '63';
      case 'mumbai':
        return '64';
      case 'north east':
        return '65';
      case 'orissa':
        return '66';
      case 'punjab':
        return '67';
      case 'rajasthan':
        return '68';
      case 'tamil nadu':
        return '69';
      case 'up east':
        return '70';
      case 'up west':
        return '71';
      case 'west bengal':
        return '72';
      default:
        return '49'; // Default to Andhra Pradesh
    }
  }

  /// Check if operator supports the service
  bool isOperatorSupported(String operatorCode) {
    const supportedOperators = ['2', '11', '23', '6', '5'];
    return supportedOperators.contains(operatorCode);
  }

  /// Get operator display name from code
  String getOperatorDisplayName(String operatorCode) {
    const operatorNames = {
      '2': 'Airtel',
      '11': 'Jio',
      '23': 'Vodafone',
      '6': 'Idea',
      '5': 'BSNL',
    };
    return operatorNames[operatorCode] ?? operatorCode;
  }

  /// Get circle display name from code
  String getCircleDisplayName(String circleCode) {
    // Convert circle code to display name using predefined mapping
    const circleMapping = {
      '49': 'Andhra Pradesh',
      '51': 'Assam',
      '52': 'Bihar',
      '53': 'Chennai',
      '54': 'Delhi',
      '55': 'Gujarat',
      '56': 'Haryana',
      '57': 'Himachal Pradesh',
      '58': 'Jammu Kashmir',
      '59': 'Karnataka',
      '60': 'Kerala',
      '61': 'Kolkata',
      '62': 'Madhya Pradesh',
      '63': 'Maharashtra',
      '64': 'Mumbai',
      '65': 'North East',
      '66': 'Orissa',
      '67': 'Punjab',
      '68': 'Rajasthan',
      '69': 'Tamil Nadu',
      '70': 'UP East',
      '71': 'UP West',
      '72': 'West Bengal',
    };
    return circleMapping[circleCode] ?? circleCode;
  }
} 