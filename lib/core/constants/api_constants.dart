class APIConstants {
  // PlanAPI.in Configuration - Updated with correct credentials
  static const String planApiBaseUrl = 'https://planapi.in/api/Mobile';
  static const String apiUserId = '3557';
  static const String apiPassword = 'Neela@1988';
  static const String apiToken = '81bd9a2a-7857-406c-96aa-056967ba859a'; // Corrected token
  
  // Robotics Exchange API Configuration - Updated with correct credentials
  static const String roboticsBaseUrl = 'https://api.roboticexchange.in/Robotics/webservice';
  static const String roboticsApiMemberId = '3425';
  static const String roboticsApiPassword = 'Neela@415263'; // Corrected password
  
  // PlanAPI.in Direct Endpoints - Corrected based on test results (404 errors indicate wrong endpoints)
  static const String operatorDetectionEndpoint = 'MobileOperator'; // Back to original (OperatorFetchNew returned 404)
  static const String mobilePlansEndpoint = 'MobilePlans'; // Back to original (NewMobilePlans returned 404)
  static const String rOfferEndpoint = 'Roffer';
  static const String lastRechargeEndpoint = 'LastRech';
   
  // Robotics Exchange API Endpoints
  static const String roboticsRechargeEndpoint = 'GetMobileRecharge';
  static const String roboticsStatusCheckEndpoint = 'GetStatus';
  static const String roboticsWalletBalanceEndpoint = 'GetWalletBalance';
  static const String roboticsComplaintEndpoint = 'RechargeComplaint';
  static const String roboticsOperatorBalanceEndpoint = 'OperatorBalance';
  static const String roboticsLapuBalanceEndpoint = 'GetLapuWiseBal';
  static const String roboticsLapuPurchaseEndpoint = 'GetPurchase';
  static const String roboticsIpUpdateEndpoint = 'GetIpUpdate';
  
  // Full PlanAPI.in endpoint URLs
  static String get operatorDetectionUrl => '$planApiBaseUrl/$operatorDetectionEndpoint';
  static String get mobilePlansUrl => '$planApiBaseUrl/$mobilePlansEndpoint';
  static String get rOfferUrl => '$planApiBaseUrl/$rOfferEndpoint';
  static String get roffersUrl => '$planApiBaseUrl/$rOfferEndpoint';
  static String get lastRechargeUrl => '$planApiBaseUrl/$lastRechargeEndpoint';
  static String get rechargeUrl => '$roboticsBaseUrl/$roboticsRechargeEndpoint';
  static String get healthCheckUrl => '$planApiBaseUrl/Health';
  
  // Robotics Exchange API URLs
  static String get roboticsRechargeUrl => '$roboticsBaseUrl/$roboticsRechargeEndpoint';
  static String get roboticsStatusCheckUrl => '$roboticsBaseUrl/$roboticsStatusCheckEndpoint';
  static String get roboticsWalletBalanceUrl => '$roboticsBaseUrl/$roboticsWalletBalanceEndpoint';
  static String get roboticsComplaintUrl => '$roboticsBaseUrl/$roboticsComplaintEndpoint';
  static String get roboticsOperatorBalanceUrl => '$roboticsBaseUrl/$roboticsOperatorBalanceEndpoint';
  static String get roboticsLapuBalanceUrl => '$roboticsBaseUrl/$roboticsLapuBalanceEndpoint';
  static String get roboticsLapuPurchaseUrl => '$roboticsBaseUrl/$roboticsLapuPurchaseEndpoint';
  static String get roboticsIpUpdateUrl => '$roboticsBaseUrl/$roboticsIpUpdateEndpoint';
  
  // Payment Gateway Configuration
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
  static const String razorpayKeySecret = 'YOUR_RAZORPAY_KEY_SECRET';
  
  // Other Constants
  static const int requestTimeout = 30000; // 30 seconds
  static const String defaultCurrency = 'INR';
  
  // PlanAPI.in Parameter Format - Updated based on test requirements
  static const Map<String, String> planApiParameterFormat = {
    'operatorDetection': 'userid,password,format,mobile', // Original format
    'mobilePlans': 'userid,password,format,operator,circle', // Original format
    'apiKeyFormat': 'apikey,mobileno', // Alternative if API key works
  };
  
  // PlanAPI.in Operator Codes (corrected based on user's operator table)
  static const Map<String, String> planApiOperatorCodes = {
    'AIRTEL': '2',
    'BSNL TOPUP': '4',
    'BSNL SPECIAL': '5',
    'IDEA': '6',
    'RELIANCE JIO': '11',
    'VODAFONE': '23',
    'MATRIX PRECARD': '93',
  };
  
  // Robotics Exchange Operator Codes (corrected based on user's documentation)
  static const Map<String, String> roboticsOperatorCodes = {
    'AIRTEL': 'AT',
    'VODAFONE': 'VI',
    'IDEA': 'VI', // Merged with Vodafone
    'JIO': 'JO',
    'BSNL': 'BS',
    'AIRTEL_DTH': 'AD',
    'DISH_TV': 'DT',
    'TATASKY': 'TS',
    'VIDEOCON': 'VD',
    'JIO_LITE': 'JL',
  };
  
  // PlanAPI to Robotics operator code mapping
  static const Map<String, String> planApiToRoboticsMapping = {
    '2': 'AT',   // Airtel
    '11': 'JO',  // Jio
    '23': 'VI',  // Vi/Vodafone
    '6': 'VI',   // Idea (now Vi)
    '4': 'BS',   // BSNL TOPUP
    '5': 'BS',   // BSNL SPECIAL
    '93': 'MC',  // Matrix Precard
  };
  
  // Indian Telecom Circles - PlanAPI.in circle codes
  static const Map<String, String> telecomCircles = {
    'DELHI': '10',
    'UP(West)': '97', 
    'PUNJAB': '02',
    'HP': '03',
    'HARYANA': '96',
    'J&K': '55',
    'UP(East)': '54',
    'MUMBAI': '92',
    'MAHARASHTRA': '90',
    'GUJARAT': '98',
    'MP': '93',
    'RAJASTHAN': '70',
    'KOLKATTA': '31',
    'West Bengal': '51',
    'ORISSA': '53',
    'NESA': '16',
    'ASSAM': '56',
    'BIHAR': '52',
    'KARNATAKA': '06',
    'CHENNAI': '40',
    'TAMIL NADU': '94',
    'KERALA': '95',
    'AP': '49',
    'SIKKIM': '99',
    'TRIPURA': '100',
    'CHHATISGARH': '101',
    'GOA': '102',
    'MEGHALAY': '103',
    'MIZZORAM': '104',
    'JHARKHAND': '105',
  };
  
  // Popular Operators
  static const List<String> popularOperators = [
    'AIRTEL',
    'VODAFONE',
    'JIO',
    'BSNL',
    'IDEA',
  ];
} 