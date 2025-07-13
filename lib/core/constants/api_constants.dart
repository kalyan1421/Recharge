class APIConstants {
  // Plan API Configuration
  static const String planApiBaseUrl = 'https://planapi.in/api';
  static const String planApiOperatorDetectionUrl = '$planApiBaseUrl/Mobile/OperatorFetchNew';
  
  // API Credentials
  static const String planApiUserId = '3557';
  static const String planApiPassword = 'Neela@1988';
  
  // Robotics Exchange API Configuration
  static const String roboticsApiMemberId = '3425';
  static const String roboticsApiPassword = 'Neela@415263';
  static const String roboticsBaseUrl = 'https://api.roboticexchange.in/Robotics/webservice';
  
  // Robotics Exchange API Endpoints
  static const String roboticsRechargeUrl = '$roboticsBaseUrl/GetMobileRecharge';
  static const String roboticsStatusCheckUrl = '$roboticsBaseUrl/GetStatus';
  static const String roboticsWalletBalanceUrl = '$roboticsBaseUrl/GetWalletBalance';
  static const String roboticsOperatorBalanceUrl = '$roboticsBaseUrl/OperatorBalance';
  
  // Operator Codes (based on your documentation)
  static const Map<String, String> operatorCodes = {
    '23': 'VODAFONE',
    '11': 'RELIANCE JIO',
    '6': 'IDEA',
    '5': 'BSNL SPECIAL',
    '4': 'BSNL TOPUP',
    '2': 'AIRTEL',
  };
  
  // Correct Robotics Exchange Operator Codes
  static const Map<String, String> roboticsOperatorCodes = {
    'AIRTEL': 'AT',
    'VODAFONE': 'VI',
    'VODAFONEIDEA': 'VI',
    'VI': 'VI',
    'IDEA': 'VI',
    'JIO': 'JO',
    'RELIANCE JIO': 'JO',
    'BSNL': 'BS',
    'BSNL TOPUP': 'BS',
    'BSNL SPECIAL': 'BS',
    'DISH TV': 'DT',
    'TATASKY': 'TS',
    'VIDEOCON': 'VD',
    'SUN TV': 'SD',
    'JIO LITE': 'JL',
    'MATRIX': 'MX',
    'MATRIX PRECARD': 'MX',
  };
  
  // Circle Codes (based on your documentation)
  static const Map<String, String> circleCodes = {
    '105': 'JHARKHAND',
    '104': 'MIZZORAM',
    '103': 'MEGHALAY',
    '102': 'GOA',
    '101': 'CHHATISGARH',
    '100': 'TRIPURA',
    '99': 'SIKKIM',
    '49': 'AP', // Andhra Pradesh
    '95': 'KERALA',
    '94': 'TAMIL NADU',
    '40': 'CHENNAI',
    '06': 'KARNATAKA',
    '52': 'BIHAR',
    '16': 'NESA',
    '56': 'ASSAM',
    '53': 'ORISSA',
    '51': 'WEST BENGAL',
    '31': 'KOLKATA',
    '70': 'RAJASTHAN',
    '93': 'MP', // Madhya Pradesh
    '98': 'GUJARAT',
    '90': 'MAHARASHTRA',
    '92': 'MUMBAI',
    '54': 'UP(EAST)',
    '55': 'J&K', // Jammu & Kashmir
  };
  
  // Telecom Circles for Robotics Exchange
  static const Map<String, String> telecomCircles = {
    'DELHI': '10',
    'MUMBAI': '92',
    'KOLKATA': '31',
    'CHENNAI': '40',
    'RAJASTHAN': '70',
    'GUJARAT': '98',
    'MAHARASHTRA': '90',
    'KARNATAKA': '06',
    'TAMIL NADU': '94',
    'ANDHRA PRADESH': '49',
    'KERALA': '95',
    'WEST BENGAL': '51',
    'BIHAR': '52',
    'UTTAR PRADESH (EAST)': '54',
    'UTTAR PRADESH (WEST)': '97',
    'PUNJAB': '02',
    'HIMACHAL PRADESH': '03',
    'HARYANA': '96',
    'JAMMU & KASHMIR': '55',
    'ASSAM': '56',
    'ORISSA': '53',
    'MADHYA PRADESH': '93',
    'JHARKHAND': '105',
    'CHHATTISGARH': '101',
    'GOA': '102',
    'SIKKIM': '99',
    'TRIPURA': '100',
    'MEGHALAYA': '103',
    'MIZORAM': '104',
    'NESA': '16',
    'UP(West)': '97',
    'UP(East)': '54',
    'HP': '03',
    'J&K': '55',
    'MP': '93',
    'AP': '49',
  };
  
  // Get Robotics operator code from operator name with smart matching
  static String getRoboticsOperatorCode(String operatorName) {
    final upperName = operatorName.toUpperCase().trim();
    
    // Try exact match first
    if (roboticsOperatorCodes.containsKey(upperName)) {
      return roboticsOperatorCodes[upperName]!;
    }
    
    // Try partial match with priority order
    final priorityMatches = [
      // Airtel variations
      {'patterns': ['AIRTEL', 'AIR TEL'], 'code': 'AT'},
      
      // Jio variations
      {'patterns': ['JIO', 'RELIANCE JIO', 'RELIANCE', 'RJI'], 'code': 'JO'},
      
      // Vi/Vodafone/Idea variations
      {'patterns': ['VI', 'VODAFONE', 'IDEA', 'VODAFONEIDEA', 'VODAFONE IDEA'], 'code': 'VI'},
      
      // BSNL variations
      {'patterns': ['BSNL', 'BHARAT SANCHAR', 'BHARAT SANCHAR NIGAM'], 'code': 'BS'},
      
      // DTH operators
      {'patterns': ['DISH TV', 'DISH'], 'code': 'DT'},
      {'patterns': ['TATASKY', 'TATA SKY'], 'code': 'TS'},
      {'patterns': ['VIDEOCON', 'VIDEOCON D2H'], 'code': 'VD'},
      {'patterns': ['SUN TV', 'SUN DIRECT'], 'code': 'SD'},
    ];
    
    // Check priority matches
    for (final match in priorityMatches) {
      final patterns = match['patterns'] as List<String>;
      final code = match['code'] as String;
      
      for (final pattern in patterns) {
        if (upperName.contains(pattern) || pattern.contains(upperName)) {
          return code;
        }
      }
    }
    
    // Fallback: try any partial match
    for (final entry in roboticsOperatorCodes.entries) {
      if (upperName.contains(entry.key) || entry.key.contains(upperName)) {
        return entry.value;
      }
    }
    
    // Default to JIO if not found (most common)
    return 'JO';
  }
  
  // Get circle code from circle name with smart matching
  static String getCircleCode(String circleName) {
    final upperName = circleName.toUpperCase().trim();
    
    // Try exact match first
    if (telecomCircles.containsKey(upperName)) {
      return telecomCircles[upperName]!;
    }
    
    // Try partial match
    for (final entry in telecomCircles.entries) {
      if (upperName.contains(entry.key) || entry.key.contains(upperName)) {
        return entry.value;
      }
    }
    
    // Special cases for common variations
    if (upperName.contains('DELHI') || upperName.contains('NCR')) {
      return '10';
    }
    if (upperName.contains('MUMBAI') || upperName.contains('BOMBAY')) {
      return '92';
    }
    if (upperName.contains('KOLKATA') || upperName.contains('CALCUTTA')) {
      return '31';
    }
    if (upperName.contains('CHENNAI') || upperName.contains('MADRAS')) {
      return '40';
    }
    if (upperName.contains('BANGALORE') || upperName.contains('BENGALURU')) {
      return '06';
    }
    if (upperName.contains('HYDERABAD') || upperName.contains('TELANGANA')) {
      return '49';
    }
    
    // Default to Delhi if not found
    return '10';
  }
  
  // Validate mobile number for Indian numbers
  static bool isValidMobileNumber(String number) {
    // Remove any spaces or special characters
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if it's a valid 10-digit Indian mobile number
    if (cleanNumber.length == 10) {
      // Check if it starts with valid Indian mobile prefixes (6-9)
      final firstDigit = int.tryParse(cleanNumber[0]) ?? 0;
      return firstDigit >= 6 && firstDigit <= 9;
    }
    
    // Check if it's a valid number with country code
    if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
      final mobileNumber = cleanNumber.substring(2);
      final firstDigit = int.tryParse(mobileNumber[0]) ?? 0;
      return firstDigit >= 6 && firstDigit <= 9;
    }
    
    return false;
  }
  
  // Clean mobile number (remove country code, spaces, special chars)
  static String cleanMobileNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Remove country code if present
    if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
      return cleanNumber.substring(2);
    }
    
    return cleanNumber;
  }
  
  // Validation methods
  static bool isValidOperatorCode(String code) {
    return operatorCodes.containsKey(code);
  }
  
  static bool isValidCircleCode(String code) {
    return circleCodes.containsKey(code);
  }
  
  static String getOperatorName(String code) {
    return operatorCodes[code] ?? 'Unknown Operator';
  }
  
  static String getCircleName(String code) {
    return circleCodes[code] ?? 'Unknown Circle';
  }
  
  // Recharge amount validation
  static bool isValidRechargeAmount(double amount) {
    return amount >= 10.0 && amount <= 25000.0;
  }
  
  static String getRechargeAmountError(double amount) {
    if (amount < 10.0) {
      return 'Minimum recharge amount is ₹10';
    }
    if (amount > 25000.0) {
      return 'Maximum recharge amount is ₹25,000';
    }
    return '';
  }
} 