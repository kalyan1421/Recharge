class AppConstants {
  // App Info
  static const String appName = 'SamyPay';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Complete Recharge & Payment Solution';
  
  // API Endpoints
  static const String baseUrl = 'https://api.samypay.com/v1';
  static const String dataYugeApiUrl = 'https://api.datayuge.com/v1/lookup';
  
  // Recharge API Keys (Demo keys - Replace with actual keys)
  static const String pay2allApiKey = 'pay2all_demo_key';
  static const String roundpayApiKey = 'roundpay_demo_key';
  
  // Razorpay Configuration
  static const String razorpayKeyId = 'rzp_test_1234567890';
  static const String razorpayKeySecret = 'your_secret_key';
  
  // Cashfree Configuration
  static const String cashfreeAppId = 'your_cashfree_app_id';
  static const String cashfreeSecretKey = 'your_cashfree_secret_key';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String rechargesCollection = 'recharges';
  static const String bankAccountsCollection = 'bankAccounts';
  static const String fundRequestsCollection = 'fundRequests';
  static const String walletsCollection = 'wallets';
  
  // Storage Paths
  static const String kycDocumentsPath = 'kyc_documents';
  static const String profileImagesPath = 'profile_images';
  
  // Validation Constants
  static const int phoneNumberLength = 10;
  static const int otpLength = 6;
  static const double minWalletAmount = 500.0;
  static const double maxWalletAmount = 50000.0;
  static const double minRechargeAmount = 10.0;
  static const double maxRechargeAmount = 10000.0;
  
  // Transaction Types
  static const String transactionTypeRecharge = 'RECHARGE';
  static const String transactionTypeAddMoney = 'ADD_MONEY';
  static const String transactionTypeTransfer = 'TRANSFER';
  static const String transactionTypeWithdraw = 'WITHDRAW';
  static const String transactionTypeFundRequest = 'FUND_REQUEST';
  
  // Transaction Status
  static const String statusPending = 'PENDING';
  static const String statusSuccess = 'SUCCESS';
  static const String statusFailed = 'FAILED';
  static const String statusCancelled = 'CANCELLED';
  
  // Recharge Categories
  static const String rechargePrepaid = 'PREPAID';
  static const String rechargePostpaid = 'POSTPAID';
  static const String rechargeDth = 'DTH';
  
  // KYC Status
  static const String kycPending = 'PENDING';
  static const String kycVerified = 'VERIFIED';
  static const String kycRejected = 'REJECTED';
  
  // Account Types
  static const String accountTypePersonal = 'PERSONAL';
  static const String accountTypeBusiness = 'BUSINESS';
  
  // Operators (for fallback detection)
  static const Map<String, String> operatorCodes = {
    'AIRTEL': 'AI',
    'VI': 'VI',
    'JIO': 'JI',
    'BSNL': 'BS',
    'IDEA': 'ID',
    'TATA_DOCOMO': 'TD',
  };
  
  // Circles
  static const List<String> circles = [
    'DELHI',
    'MUMBAI',
    'KOLKATA',
    'CHENNAI',
    'BANGALORE',
    'HYDERABAD',
    'PUNE',
    'GUJARAT',
    'RAJASTHAN',
    'MAHARASHTRA',
    'KARNATAKA',
    'TAMIL_NADU',
    'ANDHRA_PRADESH',
    'TELANGANA',
    'KERALA',
    'WEST_BENGAL',
    'BIHAR',
    'UTTAR_PRADESH',
    'MADHYA_PRADESH',
    'ODISHA',
    'ASSAM',
    'HARYANA',
    'PUNJAB',
    'HIMACHAL_PRADESH',
    'JAMMU_KASHMIR',
    'UTTARAKHAND',
    'JHARKHAND',
    'CHHATTISGARH',
    'GOA',
    'MANIPUR',
    'MEGHALAYA',
    'MIZORAM',
    'NAGALAND',
    'SIKKIM',
    'TRIPURA',
    'ARUNACHAL_PRADESH',
  ];
  
  // Error Messages
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Please check your internet connection.';
  static const String errorInvalidPhone = 'Please enter a valid phone number.';
  static const String errorInvalidOtp = 'Please enter a valid OTP.';
  static const String errorInsufficientBalance = 'Insufficient wallet balance.';
  static const String errorPaymentFailed = 'Payment failed. Please try again.';
  static const String errorUnauthorized = 'Please login to continue.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorTimeout = 'Request timeout. Please try again.';
  
  // Success Messages
  static const String successRecharge = 'Recharge completed successfully!';
  static const String successAddMoney = 'Money added to wallet successfully!';
  static const String successKycSubmitted = 'KYC documents submitted successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  
  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
  static const String keyUserPhone = 'user_phone';
  static const String keyUserName = 'user_name';
  static const String keyWalletBalance = 'wallet_balance';
  static const String keyKycStatus = 'kyc_status';
  static const String keyFirstTime = 'first_time';
  
  // Regular Expressions
  static const String phoneRegex = r'^[6-9]\d{9}$';
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String panRegex = r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$';
  static const String aadharRegex = r'^[2-9]{1}[0-9]{3}[0-9]{4}[0-9]{4}$';
  static const String ifscRegex = r'^[A-Z]{4}0[A-Z0-9]{6}$';
  
  // Plan Types
  static const String planTypeUnlimited = 'UNLIMITED';
  static const String planTypeData = 'DATA';
  static const String planTypeTalktime = 'TALKTIME';
  static const String planTypeRoaming = 'ROAMING';
  static const String planTypeRatecutter = 'RATECUTTER';
  
  // Payment Methods
  static const String paymentMethodUpi = 'UPI';
  static const String paymentMethodCard = 'CARD';
  static const String paymentMethodNetbanking = 'NETBANKING';
  static const String paymentMethodWallet = 'WALLET';
  
  // File Size Limits (in bytes)
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageSize = 2 * 1024 * 1024; // 2MB
  
  // Supported File Types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedDocumentTypes = ['pdf', 'jpg', 'jpeg', 'png'];
} 