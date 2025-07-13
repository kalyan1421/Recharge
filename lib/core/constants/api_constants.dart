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
  
  // Robotics Exchange Operator Codes
  static const Map<String, String> roboticsOperatorCodes = {
    '2': 'AT',   // Airtel
    '11': 'JO',  // Jio
    '23': 'VI',  // Vi/Vodafone
    '6': 'VI',   // Idea (merged with Vi)
    '4': 'BS',   // BSNL TOPUP
    '5': 'BS',   // BSNL SPECIAL
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
  };
  
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
} 