class APIConstants {
  // PlanAPI.in Configuration - Direct API Integration
  static const String planApiBaseUrl = 'https://planapi.in/api/Mobile';
  static const String apiUserId = '3557';
  static const String apiPassword = 'Neela@1988';
  static const String apiToken = '26f19318-b8c7-4a29-8404-02c9ba48680a';
  
  // Robotics Exchange API Configuration
  static const String roboticsBaseUrl = 'https://api.roboticexchange.in/Robotics/webservice';
  static const String roboticsApiMemberId = '3425';
  static const String roboticsApiPassword = 'Apipassword';
  
  // PlanAPI.in Direct Endpoints
  static const String operatorDetectionEndpoint = 'MobileOperator';
  static const String mobilePlansEndpoint = 'MobilePlans';
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
  
  // PlanAPI.in Operator Codes
  static const Map<String, String> planApiOperatorCodes = {
    'AIRTEL': '2',
    'VODAFONE': '23',
    'IDEA': '6',
    'JIO': '11',
    'BSNL': '5',
    'TATA_DOCOMO': '16',
    'UNINOR': '17',
    'RELIANCE': '18',
    'MTNL': '19',
    'VIDEOCON': '20',
  };
  
  // Robotics Exchange Operator Codes
  static const Map<String, String> roboticsOperatorCodes = {
    'AIRTEL': '2',
    'VODAFONE': '4',
    'IDEA': '4',
    'JIO': '31',
    'BSNL': '6',
    'TATA_DOCOMO': '16',
    'UNINOR': '17',
    'RELIANCE': '18',
    'MTNL': '19',
    'VIDEOCON': '20',
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