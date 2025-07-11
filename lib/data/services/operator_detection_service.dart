import 'package:logger/logger.dart';
import '../models/operator_info.dart';
import 'plan_api_service.dart';

class OperatorDetectionService {
  static final OperatorDetectionService _instance = OperatorDetectionService._internal();
  factory OperatorDetectionService() => _instance;
  OperatorDetectionService._internal();

  final Logger _logger = Logger();
  final PlanApiService _apiService = PlanApiService();

  /// Auto-detect operator and circle from mobile number
  /// Uses PlanAPI.in for accurate detection
  Future<OperatorInfo?> detectOperator(String mobileNumber) async {
    try {
      // Validate mobile number
      if (!_isValidMobileNumber(mobileNumber)) {
        throw Exception('Invalid mobile number format. Please enter a valid 10-digit Indian mobile number.');
      }

      // Clean mobile number (remove spaces, +91, etc.)
      final cleanNumber = _cleanMobileNumber(mobileNumber);
      
      _logger.i('Detecting operator for mobile number: ${_maskMobileNumber(cleanNumber)}');

      // Use PlanAPI.in for operator detection
      final operatorInfo = await _apiService.fetchOperatorAndCircle(cleanNumber);
      
      _logger.i('✅ Operator detected successfully: ${operatorInfo.operator} (${operatorInfo.opCode}) - ${operatorInfo.circle}');
      return operatorInfo;
      
    } catch (e) {
      _logger.e('❌ Operator detection failed: $e');
      // Instead of returning null, throw the error to let the UI handle it
      throw Exception('Failed to detect operator: ${e.toString()}');
    }
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
      
      // Try to get from API first (if available)
      try {
        final response = await _apiService.fetchOperatorAndCircle('9999999999');
        if (response.error == '0') {
          _logger.i('✅ Using API for operator list');
          return ['Airtel', 'Jio', 'Vi', 'BSNL'];
        }
      } catch (e) {
        _logger.w('API unavailable for operator list: $e');
      }
      
      // Fall back to demo data
      _logger.i('Using demo operator list (API unavailable)');
      return [
        'Airtel',
        'Jio',
        'Vi',
        'BSNL',
        'MTNL',
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
      _logger.i('Using demo circle list (API unavailable)');
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
      case 'idea':
        return '23';
      case 'bsnl':
        return '5';
      case 'mtnl':
        return '6';
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