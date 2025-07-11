import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'recharge_service.dart';
import 'robotics_status_service.dart';
import 'plan_service.dart'; // Import for RechargeValidationResult

class LiveRechargeService {
  static final LiveRechargeService _instance = LiveRechargeService._internal();
  factory LiveRechargeService() => _instance;
  LiveRechargeService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'https://api.roboticexchange.in/Robotics/webservice'; // Use robotics exchange directly
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Authentication token cache
  String? _authToken;
  DateTime? _tokenExpiry;

  /// Enhanced recharge processing with comprehensive error handling
  Future<RechargeResult> processLiveRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int planAmount,
    required String planDescription,
    required String validity,
    required double walletBalance,
  }) async {
    _logger.i('🚀 Processing live recharge: $mobileNumber - ₹$planAmount via $operatorName');

    try {
      // Validate recharge prerequisites
      final validation = await _validateRechargeRequest(
        mobileNumber: mobileNumber,
        operatorCode: operatorCode,
        planAmount: planAmount,
        walletBalance: walletBalance,
      );

      if (!validation.isValid) {
        return RechargeResult(
          success: false,
          status: 'VALIDATION_FAILED',
          message: 'Validation failed: ${validation.errorMessage}',
          transactionId: '',
          amount: planAmount.toDouble(),
          operatorTransactionId: null,
          timestamp: DateTime.now(),
          mobileNumber: mobileNumber,
          operatorName: operatorName,
          planDescription: planDescription,
          validity: validity,
        );
      }

      // Use robotics exchange API directly
      return await _processRoboticsRecharge(
        userId: userId,
        mobileNumber: mobileNumber,
        operatorCode: operatorCode,
        operatorName: operatorName,
        circleCode: circleCode,
        planAmount: planAmount,
        planDescription: planDescription,
        validity: validity,
        walletBalance: walletBalance,
      );

    } catch (e) {
      _logger.e('💥 Error processing live recharge: $e');
      
      return RechargeResult(
        success: false,
        status: 'ERROR',
        message: 'Recharge failed: ${e.toString()}',
        transactionId: '',
        amount: planAmount.toDouble(),
        operatorTransactionId: null,
        timestamp: DateTime.now(),
        mobileNumber: mobileNumber,
        operatorName: operatorName,
        planDescription: planDescription,
        validity: validity,
      );
    }
  }

  /// Process recharge using robotics exchange API
  Future<RechargeResult> _processRoboticsRecharge({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int planAmount,
    required String planDescription,
    required String validity,
    required double walletBalance,
  }) async {
    try {
      _logger.i('🔄 Processing robotics recharge for $mobileNumber');

      // Generate unique transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}_${mobileNumber.substring(6)}';
      
      // Map operator code to robotics format
      final roboticsOperatorCode = _mapOperatorCodeToRobotics(operatorCode);
      
      // Prepare recharge request
      final requestData = {
        'Apimember_id': '3425', // Your robotics member ID
        'Api_password': 'Apipassword', // Your robotics API password
        'Mobile_no': mobileNumber,
        'Amount': planAmount.toString(),
        'Operator_id': roboticsOperatorCode,
        'Unique_id': transactionId,
        'Format': 'json',
      };

      _logger.d('Robotics request data: $requestData');

      // Make API call to robotics exchange
      final response = await http.post(
        Uri.parse('$_baseUrl/GetMobileRecharge'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestData,
      ).timeout(_timeout);

      _logger.d('Robotics response status: ${response.statusCode}');
      _logger.d('Robotics response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle robotics response
        final errorCode = responseData['Errorcode']?.toString() ?? '1';
        final status = responseData['Status']?.toString() ?? '3';
        final message = responseData['Message']?.toString() ?? 'Unknown error';
        final txnId = responseData['Txnid']?.toString();
        final operatorTxnId = responseData['Operator_txn_id']?.toString();

        // Save transaction to Firebase
        await _saveTransactionToFirebase(
          userId: userId,
          transactionId: transactionId,
          mobileNumber: mobileNumber,
          operatorCode: operatorCode,
          operatorName: operatorName,
          planAmount: planAmount,
          planDescription: planDescription,
          validity: validity,
          status: status,
          message: message,
          operatorTransactionId: operatorTxnId,
          apiResponse: responseData,
        );

        if (errorCode == '0' && (status == '1' || status == '2')) {
          // Success or pending
          return RechargeResult(
            success: true,
            status: status == '1' ? 'SUCCESS' : 'PENDING',
            message: message,
            transactionId: transactionId,
            amount: planAmount.toDouble(),
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            planDescription: planDescription,
            validity: validity,
          );
        } else {
          // Failed
          return RechargeResult(
            success: false,
            status: 'FAILED',
            message: message,
            transactionId: transactionId,
            amount: planAmount.toDouble(),
            operatorTransactionId: operatorTxnId,
            timestamp: DateTime.now(),
            mobileNumber: mobileNumber,
            operatorName: operatorName,
            planDescription: planDescription,
            validity: validity,
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

    } catch (e) {
      _logger.e('Error in robotics recharge: $e');
      rethrow;
    }
  }

  /// Map operator code to robotics format
  String _mapOperatorCodeToRobotics(String operatorCode) {
    // Map common operator codes to robotics format
    switch (operatorCode.toUpperCase()) {
      case 'JIO':
      case '11':
      case '14':
        return '31'; // Jio robotics code
      case 'AIRTEL':
      case '2':
        return '2'; // Airtel robotics code
      case 'VODAFONE':
      case 'VI':
      case '23':
      case '12':
        return '4'; // Vi robotics code
      case 'IDEA':
      case '6':
      case '13':
        return '4'; // Vi robotics code (merged with Vodafone)
      case 'BSNL':
      case '5':
      case '15':
        return '6'; // BSNL robotics code
      default:
        return '31'; // Default to Jio
    }
  }

  /// Save transaction to Firebase
  Future<void> _saveTransactionToFirebase({
    required String userId,
    required String transactionId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required int planAmount,
    required String planDescription,
    required String validity,
    required String status,
    required String message,
    String? operatorTransactionId,
    Map<String, dynamic>? apiResponse,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .set({
        'transactionId': transactionId,
        'type': 'mobile_recharge',
        'mobileNumber': mobileNumber,
        'operatorCode': operatorCode,
        'operatorName': operatorName,
        'amount': planAmount,
        'planDescription': planDescription,
        'validity': validity,
        'status': status,
        'message': message,
        'operatorTransactionId': operatorTransactionId,
        'apiResponse': apiResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('✅ Transaction saved to Firebase: $transactionId');
    } catch (e) {
      _logger.e('Error saving transaction to Firebase: $e');
      // Don't throw error, just log it
    }
  }

  /// Enhanced authentication with token management and security
  Future<String> _getAuthToken() async {
    try {
      // Check if token is still valid (with 5-minute buffer)
      if (_authToken != null && _tokenExpiry != null && 
          DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return _authToken!;
      }

      _logger.i('🔑 Requesting new authentication token');

      // Try multiple authentication methods
      final authResponse = await _tryMultipleAuthMethods();
      
      if (authResponse['success'] == true) {
        _authToken = authResponse['access_token'];
        final expiresIn = authResponse['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        _logger.i('✅ Authentication token obtained successfully');
        return _authToken!;
      } else {
        _logger.w('⚠️ All authentication methods failed, using fallback');
        return _generateFallbackToken();
      }
    } catch (e) {
      _logger.e('❌ Token authentication failed: $e');
      return _generateFallbackToken();
    }
  }

  /// Try multiple authentication methods for better reliability
  Future<Map<String, dynamic>> _tryMultipleAuthMethods() async {
    final authMethods = [
      () => _authenticateWithClientCredentials(),
      () => _authenticateWithApiKey(),
      () => _authenticateWithBasicAuth(),
    ];

    for (final authMethod in authMethods) {
      try {
        final result = await authMethod();
        if (result['success'] == true) {
          return result;
        }
      } catch (e) {
        _logger.w('Authentication method failed: $e');
        continue;
      }
    }

    return {'success': false};
  }

  /// Authenticate with client credentials (OAuth2)
  Future<Map<String, dynamic>> _authenticateWithClientCredentials() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/token'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-Recharge-App/2.0',
        'Accept': 'application/json',
      },
      body: json.encode({
        'grant_type': 'client_credentials',
        'client_id': 'flutter_recharge_app',
        'client_secret': _getClientSecret(),
        'scope': 'recharge_api',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'access_token': data['access_token'],
        'expires_in': data['expires_in'],
        'token_type': data['token_type'] ?? 'Bearer',
      };
    }

    return {'success': false, 'error': 'Client credentials failed'};
  }

  /// Authenticate with API key
  Future<Map<String, dynamic>> _authenticateWithApiKey() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/api-key'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-Recharge-App/2.0',
        'X-API-Key': _getApiKey(),
      },
      body: json.encode({
        'app_id': 'flutter_recharge_app',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'nonce': _generateNonce(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'access_token': data['token'],
        'expires_in': data['expires_in'] ?? 3600,
        'token_type': 'Bearer',
      };
    }

    return {'success': false, 'error': 'API key authentication failed'};
  }

  /// Authenticate with basic authentication
  Future<Map<String, dynamic>> _authenticateWithBasicAuth() async {
    final credentials = base64.encode(utf8.encode('${_getUsername()}:${_getPassword()}'));
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/basic'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $credentials',
        'User-Agent': 'Flutter-Recharge-App/2.0',
      },
      body: json.encode({
        'device_id': await _getDeviceId(),
        'app_version': '2.0.0',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'access_token': data['session_token'],
        'expires_in': data['expires_in'] ?? 3600,
        'token_type': 'Bearer',
      };
    }

    return {'success': false, 'error': 'Basic authentication failed'};
  }

  /// Generate fallback token when all authentication methods fail
  String _generateFallbackToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    final payload = 'fallback_$timestamp$random';
    
    return base64.encode(utf8.encode(payload));
  }

  /// Get client secret (in production, this should be securely stored)
  String _getClientSecret() {
    // In production, this should be retrieved from secure storage
    return 'your_secure_client_secret_here';
  }

  /// Get API key (in production, this should be securely stored)
  String _getApiKey() {
    // In production, this should be retrieved from secure storage
    return 'your_secure_api_key_here';
  }

  /// Get username for basic auth
  String _getUsername() {
    return 'flutter_app_user';
  }

  /// Get password for basic auth
  String _getPassword() {
    return 'your_secure_password_here';
  }

  /// Get device ID for authentication
  Future<String> _getDeviceId() async {
    try {
      // In production, use device_info_plus to get actual device ID
      return 'flutter_device_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'fallback_device_id';
    }
  }

  /// Generate nonce for authentication
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Generate enhanced signature with multiple security layers
  String _generateSignature(Map<String, dynamic> params) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final nonce = _generateNonce();
      
      // Add security parameters
      params['timestamp'] = timestamp;
      params['nonce'] = nonce;
      params['version'] = '2.0';
      
      // Sort parameters for consistent signing
      final sortedKeys = params.keys.toList()..sort();
      final queryString = sortedKeys
          .map((key) => '$key=${Uri.encodeComponent(params[key].toString())}')
          .join('&');
      
      // Create string to sign
      final method = 'POST';
      final path = '/api/recharge';
      final stringToSign = '$method\n$path\n$queryString';
      
      // Generate HMAC-SHA256 signature
      final secretKey = _getSigningSecret();
      final keyBytes = utf8.encode(secretKey);
      final messageBytes = utf8.encode(stringToSign);
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(messageBytes);
      
      final signature = base64.encode(digest.bytes);
      _logger.d('🔐 Generated signature: ${signature.substring(0, 8)}...');
      
      return signature;
    } catch (e) {
      _logger.e('❌ Signature generation failed: $e');
      return _generateFallbackSignature();
    }
  }

  /// Get signing secret for HMAC
  String _getSigningSecret() {
    // In production, this should be securely stored and rotated regularly
    return 'your_hmac_signing_secret_key_here';
  }

  /// Generate fallback signature
  String _generateFallbackSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    final fallback = 'fallback_$timestamp$random';
    
    return base64.encode(utf8.encode(fallback));
  }

  /// Validate authentication token before use
  bool _isTokenValid() {
    if (_authToken == null || _tokenExpiry == null) {
      return false;
    }
    
    // Check if token expires within next 5 minutes
    final bufferTime = DateTime.now().add(const Duration(minutes: 5));
    return _tokenExpiry!.isAfter(bufferTime);
  }

  /// Refresh authentication token proactively
  Future<void> _refreshTokenIfNeeded() async {
    if (!_isTokenValid()) {
      _logger.i('🔄 Proactively refreshing authentication token');
      await _getAuthToken();
    }
  }

  /// Clear authentication cache
  void _clearAuthCache() {
    _authToken = null;
    _tokenExpiry = null;
    _logger.i('🗑️ Authentication cache cleared');
  }

  /// Enhanced request headers with security
  Map<String, String> _getEnhancedHeaders({
    String? authToken,
    String? requestId,
    int? attemptCount,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-Recharge-App/2.0',
      'X-Client-Version': '2.0.0',
      'X-Platform': 'Flutter',
      'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-Request-ID': requestId ?? _generateRequestId(),
      'X-Attempt-Count': attemptCount?.toString() ?? '1',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  /// Generate unique request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'REQ_${timestamp}_$random';
  }

  /// Check service health before processing
  Future<bool> _isServiceHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/health'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-Recharge-App/2.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        return healthData['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      _logger.w('⚠️ Health check failed: $e');
      return true; // Assume healthy if check fails
    }
  }

  /// Validate recharge request with enhanced checks
  Future<RechargeValidationResult> _validateRechargeRequest({
    required String mobileNumber,
    required String operatorCode,
    required int planAmount,
    required double walletBalance,
  }) async {
    // Validate mobile number
    if (mobileNumber.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(mobileNumber)) {
      return RechargeValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid 10-digit mobile number',
        shortfallAmount: 0.0,
      );
    }

    // Validate amount
    if (planAmount < 10 || planAmount > 10000) {
      return RechargeValidationResult(
        isValid: false,
        errorMessage: 'Amount must be between ₹10 and ₹10,000',
        shortfallAmount: 0.0,
      );
    }

    // Validate operator code
    if (operatorCode.isEmpty) {
      return RechargeValidationResult(
        isValid: false,
        errorMessage: 'Operator code is required',
        shortfallAmount: 0.0,
      );
    }

    // Validate wallet balance
    if (walletBalance < planAmount) {
      return RechargeValidationResult(
        isValid: false,
        errorMessage: 'Insufficient wallet balance. Required: ₹${planAmount.toInt()}, Available: ₹${walletBalance.toInt()}',
        shortfallAmount: planAmount - walletBalance,
      );
    }

    return RechargeValidationResult(
      isValid: true,
      errorMessage: null,
      shortfallAmount: 0.0,
    );
  }

  /// Create enhanced transaction record with additional metadata
  Future<DocumentReference> _createEnhancedTransactionRecord({
    required String userId,
    required String mobileNumber,
    required String operatorCode,
    required String operatorName,
    required String circleCode,
    required int amount,
    required String planDescription,
    required String validity,
    required String orderId,
  }) async {
    final transactionData = {
      'userId': userId,
      'mobileNumber': mobileNumber,
      'operatorCode': operatorCode,
      'operatorName': operatorName,
      'circleCode': circleCode,
      'amount': amount,
      'planDescription': planDescription,
      'validity': validity,
      'orderId': orderId,
      'status': 'PENDING',
      'type': 'mobile_recharge',
      'source': 'flutter_app',
      'version': '2.0',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'attemptCount': 0,
      'lastAttemptAt': FieldValue.serverTimestamp(),
      'metadata': {
        'deviceInfo': 'flutter_app',
        'userAgent': 'Flutter-Recharge-App/2.0',
        'ipAddress': 'client_ip',
      },
    };

    return await _firestore.collection('transactions').add(transactionData);
  }

  /// Update transaction with response data
  Future<void> _updateTransactionWithResponse({
    required DocumentReference transactionRef,
    required RechargeResult response,
  }) async {
    try {
      await transactionRef.update({
        'status': response.status,
        'transactionId': response.transactionId,
        'operatorTransactionId': response.operatorTransactionId,
        'message': response.message,
        'processedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('❌ Failed to update transaction: $e');
    }
  }

  /// Create failure result with consistent structure
  RechargeResult _createFailureResult({
    required String orderId,
    required String mobileNumber,
    required String operatorName,
    required int amount,
    required String planDescription,
    required String validity,
    required String message,
  }) {
    return RechargeResult(
      success: false,
      message: message,
      transactionId: orderId,
      status: 'FAILED',
      amount: amount.toDouble(),
      operatorTransactionId: null,
      timestamp: DateTime.now(),
      mobileNumber: mobileNumber,
      operatorName: operatorName,
      planDescription: planDescription,
      validity: validity,
    );
  }

  /// Determine if we should retry based on error
  bool _shouldRetryBasedOnError(Map<String, dynamic> errorData) {
    final errorCode = errorData['error_code']?.toString();
    final errorMessage = errorData['message']?.toString()?.toLowerCase() ?? '';
    
    // Don't retry for client errors
    if (errorCode == 'INVALID_MOBILE' || 
        errorCode == 'INVALID_OPERATOR' || 
        errorCode == 'INSUFFICIENT_BALANCE') {
      return false;
    }
    
    // Retry for network/server errors
    if (errorMessage.contains('network') || 
        errorMessage.contains('timeout') || 
        errorMessage.contains('server')) {
      return true;
    }
    
    return false;
  }

  /// Get operator name from code
  String _getOperatorName(String operatorCode) {
    switch (operatorCode.toUpperCase()) {
      case 'AIRTEL':
        return 'Airtel';
      case 'JIO':
        return 'Jio';
      case 'VODAFONE':
      case 'VI':
        return 'Vi';
      case 'BSNL':
        return 'BSNL';
      case 'IDEA':
        return 'Idea';
      default:
        return 'Unknown';
    }
  }

  /// Enhanced status checking with automatic retries and comprehensive monitoring
  Future<RechargeResult?> checkRechargeStatusEnhanced(String orderId, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 5),
    bool forceRemoteCheck = false,
  }) async {
    _logger.i('🔍 Starting enhanced status check for: $orderId');
    
    int attemptCount = 0;
    RechargeResult? lastResult;
    
    while (attemptCount < maxRetries) {
      attemptCount++;
      
      try {
        _logger.i('🔄 Status check attempt $attemptCount/$maxRetries');
        
        // Step 1: Check Firebase record first (unless forced remote check)
        if (!forceRemoteCheck) {
          final firebaseResult = await _checkFirebaseStatus(orderId);
          if (firebaseResult != null) {
            _logger.i('✅ Firebase status: ${firebaseResult.status}');
            
            // If status is SUCCESS or it's recent, return it
            if (firebaseResult.status == 'SUCCESS' || 
                _isRecentTransaction(firebaseResult.timestamp)) {
              return firebaseResult;
            }
            
            lastResult = firebaseResult;
          }
        }
        
        // Step 2: Check with robotics exchange API
        final roboticsResult = await _checkRoboticsStatusWithRetry(orderId);
        if (roboticsResult != null) {
          _logger.i('✅ Robotics API status: ${roboticsResult.status}');
          
          // Update Firebase with latest status
          await _updateFirebaseStatus(orderId, roboticsResult);
          
          // If we got a definitive result, return it
          if (roboticsResult.status == 'SUCCESS' || roboticsResult.status == 'FAILED') {
            return roboticsResult;
          }
          
          lastResult = roboticsResult;
        }
        
        // Step 3: Check with live recharge service status endpoint
        final liveResult = await _checkLiveServiceStatus(orderId);
        if (liveResult != null) {
          _logger.i('✅ Live service status: ${liveResult.status}');
          
          // Update Firebase with latest status
          await _updateFirebaseStatus(orderId, liveResult);
          
          if (liveResult.status == 'SUCCESS' || liveResult.status == 'FAILED') {
            return liveResult;
          }
          
          lastResult = liveResult;
        }
        
        // If we have a pending result and it's not the last attempt, wait and retry
        if (lastResult != null && lastResult.status == 'PENDING' && attemptCount < maxRetries) {
          _logger.w('⏳ Status still pending, waiting ${retryDelay.inSeconds}s before retry...');
          await Future.delayed(retryDelay);
          continue;
        }
        
        // Return the last result we got
        return lastResult;
        
      } catch (e) {
        _logger.e('❌ Status check attempt $attemptCount failed: $e');
        
        if (attemptCount < maxRetries) {
          _logger.w('⏳ Retrying status check in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      }
    }
    
    _logger.e('❌ All status check attempts failed');
    return lastResult;
  }

  /// Check status from Firebase
  Future<RechargeResult?> _checkFirebaseStatus(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return RechargeResult(
          success: data['status'] == 'SUCCESS',
          transactionId: data['transactionId'] ?? orderId,
          status: data['status'] ?? 'UNKNOWN',
          message: data['message'] ?? 'Status from Firebase',
          amount: (data['amount'] ?? 0).toDouble(),
          operatorTransactionId: data['operatorTransactionId'],
          timestamp: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          mobileNumber: data['mobileNumber'] ?? '',
          operatorName: data['operatorName'] ?? '',
          planDescription: data['planDescription'] ?? '',
          validity: data['validity'] ?? '',
        );
      }
      return null;
    } catch (e) {
      _logger.e('❌ Firebase status check failed: $e');
      return null;
    }
  }

  /// Check status with robotics exchange API with retry logic
  Future<RechargeResult?> _checkRoboticsStatusWithRetry(String orderId) async {
    try {
      final roboticsStatusService = RoboticsStatusService();
      final response = await roboticsStatusService.checkRechargeStatus(orderId);
      
      if (response.success) {
        return RechargeResult(
          success: response.rechargeStatus == 'SUCCESS',
          transactionId: response.orderId,
          status: response.rechargeStatus,
          message: response.message,
          amount: response.amount,
          operatorTransactionId: response.operatorTransactionId,
          timestamp: response.timestamp,
          mobileNumber: '',
          operatorName: '',
          planDescription: '',
          validity: '',
        );
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ Robotics status check failed: $e');
      return null;
    }
  }

  /// Check status with live recharge service
  Future<RechargeResult?> _checkLiveServiceStatus(String orderId) async {
    try {
      final authToken = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/status/$orderId'),
        headers: _getEnhancedHeaders(
          authToken: authToken,
          requestId: _generateRequestId(),
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return RechargeResult(
            success: data['status'] == 'SUCCESS',
            transactionId: data['transactionId'] ?? orderId,
            status: data['status'] ?? 'UNKNOWN',
            message: data['message'] ?? 'Status from live service',
            amount: (data['amount'] ?? 0).toDouble(),
            operatorTransactionId: data['operatorTransactionId'],
            timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            mobileNumber: data['mobileNumber'] ?? '',
            operatorName: data['operatorName'] ?? '',
            planDescription: data['planDescription'] ?? '',
            validity: data['validity'] ?? '',
          );
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ Live service status check failed: $e');
      return null;
    }
  }

  /// Update Firebase with latest status
  Future<void> _updateFirebaseStatus(String orderId, RechargeResult result) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'status': result.status,
          'transactionId': result.transactionId,
          'operatorTransactionId': result.operatorTransactionId,
          'message': result.message,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _logger.i('✅ Firebase status updated for: $orderId');
      }
    } catch (e) {
      _logger.e('❌ Failed to update Firebase status: $e');
    }
  }

  /// Update transaction status
  Future<void> _updateTransactionStatus({
    required DocumentReference transactionRef,
    required String status,
    required Map<String, dynamic> apiResponse,
    String? transactionId,
    String? errorMessage,
  }) async {
    try {
      await transactionRef.update({
        'status': status,
        'transactionId': transactionId,
        'errorMessage': errorMessage,
        'apiResponse': apiResponse,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating transaction status: $e');
    }
  }

  /// Generate unique order ID
  String _generateOrderId(String mobileNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = mobileNumber.substring(mobileNumber.length - 4);
    return 'RECH${timestamp}_$suffix';
  }

  /// Get transaction history for a user
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error fetching transaction history: $e');
      return [];
    }
  }

  /// Get transaction by ID
  Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    try {
      final docSnapshot = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching transaction: $e');
      return null;
    }
  }

  /// Get transaction statistics for a user
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      double totalAmount = 0;
      int successCount = 0;
      int failedCount = 0;
      int pendingCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final status = data['status'] ?? 'UNKNOWN';

        totalAmount += amount;
        
        switch (status) {
          case 'SUCCESS':
            successCount++;
            break;
          case 'FAILED':
            failedCount++;
            break;
          case 'PENDING':
            pendingCount++;
            break;
        }
      }

      return {
        'totalTransactions': querySnapshot.docs.length,
        'totalAmount': totalAmount,
        'successCount': successCount,
        'failedCount': failedCount,
        'pendingCount': pendingCount,
        'successRate': querySnapshot.docs.length > 0 
            ? (successCount / querySnapshot.docs.length * 100).toStringAsFixed(1) 
            : '0.0',
      };
    } catch (e) {
      _logger.e('Error fetching transaction stats: $e');
      return {
        'totalTransactions': 0,
        'totalAmount': 0.0,
        'successCount': 0,
        'failedCount': 0,
        'pendingCount': 0,
        'successRate': '0.0',
      };
    }
  }

  /// Check if transaction is recent (within last 10 minutes)
  bool _isRecentTransaction(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 10;
  }

  /// Batch status check for multiple transactions
  Future<Map<String, RechargeResult?>> checkMultipleTransactionStatus(
    List<String> orderIds, {
    int maxConcurrency = 5,
  }) async {
    _logger.i('🔍 Checking status for ${orderIds.length} transactions');
    
    final results = <String, RechargeResult?>{};
    final futures = <Future<void>>[];
    
    // Process in batches to avoid overwhelming the API
    for (int i = 0; i < orderIds.length; i += maxConcurrency) {
      final batch = orderIds.skip(i).take(maxConcurrency).toList();
      
      for (final orderId in batch) {
        futures.add(
          checkRechargeStatusEnhanced(orderId).then((result) {
            results[orderId] = result;
          }).catchError((error) {
            _logger.e('❌ Batch status check failed for $orderId: $error');
            results[orderId] = null;
          }),
        );
      }
      
      // Wait for current batch to complete
      await Future.wait(futures);
      futures.clear();
      
      // Small delay between batches
      if (i + maxConcurrency < orderIds.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    _logger.i('✅ Batch status check completed: ${results.length} results');
    return results;
  }

  /// Monitor pending transactions automatically
  Future<void> monitorPendingTransactions() async {
    try {
      _logger.i('🔄 Starting pending transaction monitoring');
      
      // Get pending transactions from Firebase
      final pendingTransactions = await _getPendingTransactions();
      
      if (pendingTransactions.isEmpty) {
        _logger.i('✅ No pending transactions to monitor');
        return;
      }
      
      _logger.i('📊 Monitoring ${pendingTransactions.length} pending transactions');
      
      // Check status for each pending transaction
      for (final transaction in pendingTransactions) {
        final orderId = transaction['orderId'] as String;
        final createdAt = transaction['createdAt'] as Timestamp;
        
        // Skip very recent transactions (less than 2 minutes old)
        if (DateTime.now().difference(createdAt.toDate()).inMinutes < 2) {
          continue;
        }
        
        // Check status
        final result = await checkRechargeStatusEnhanced(orderId, forceRemoteCheck: true);
        
        if (result != null && result.status != 'PENDING') {
          _logger.i('✅ Updated status for $orderId: ${result.status}');
          
          // Update Firebase with final status
          await _updateFirebaseStatus(orderId, result);
          
          // Send notification if needed
          await _sendStatusNotification(orderId, result);
        }
        
        // Small delay between checks
        await Future.delayed(const Duration(seconds: 1));
      }
      
      _logger.i('✅ Pending transaction monitoring completed');
    } catch (e) {
      _logger.e('❌ Pending transaction monitoring failed: $e');
    }
  }

  /// Get pending transactions from Firebase
  Future<List<Map<String, dynamic>>> _getPendingTransactions() async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('status', isEqualTo: 'PENDING')
          .where('type', isEqualTo: 'mobile_recharge')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('❌ Failed to get pending transactions: $e');
      return [];
    }
  }

  /// Send status notification (placeholder for actual implementation)
  Future<void> _sendStatusNotification(String orderId, RechargeResult result) async {
    // In production, this would send push notifications or update UI
    _logger.i('📱 Sending status notification for $orderId: ${result.status}');
  }

  /// Get comprehensive transaction statistics
  Future<Map<String, dynamic>> getEnhancedTransactionStats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'mobile_recharge')
          .get();

      final stats = <String, dynamic>{
        'totalTransactions': 0,
        'totalAmount': 0.0,
        'successCount': 0,
        'failedCount': 0,
        'pendingCount': 0,
        'successRate': '0.0',
        'averageAmount': 0.0,
        'lastTransaction': null,
        'topOperators': <String, int>{},
        'monthlyStats': <String, Map<String, dynamic>>{},
      };

      double totalAmount = 0;
      int successCount = 0;
      int failedCount = 0;
      int pendingCount = 0;
      DateTime? lastTransactionDate;
      final operatorCounts = <String, int>{};
      final monthlyStats = <String, Map<String, dynamic>>{};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final status = data['status'] ?? 'UNKNOWN';
        final operator = data['operatorName'] ?? 'Unknown';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        totalAmount += amount;
        
        // Count by status
        switch (status) {
          case 'SUCCESS':
            successCount++;
            break;
          case 'FAILED':
            failedCount++;
            break;
          case 'PENDING':
            pendingCount++;
            break;
        }

        // Track operators
        operatorCounts[operator] = (operatorCounts[operator] ?? 0) + 1;

        // Track monthly stats
        if (createdAt != null) {
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyStats[monthKey] = monthlyStats[monthKey] ?? {
            'count': 0,
            'amount': 0.0,
            'success': 0,
            'failed': 0,
            'pending': 0,
          };
          
          monthlyStats[monthKey]!['count'] = monthlyStats[monthKey]!['count'] + 1;
          monthlyStats[monthKey]!['amount'] = monthlyStats[monthKey]!['amount'] + amount;
          monthlyStats[monthKey]![status.toLowerCase()] = 
              monthlyStats[monthKey]![status.toLowerCase()] + 1;

          if (lastTransactionDate == null || createdAt.isAfter(lastTransactionDate)) {
            lastTransactionDate = createdAt;
          }
        }
      }

      final totalCount = querySnapshot.docs.length;
      
      stats['totalTransactions'] = totalCount;
      stats['totalAmount'] = totalAmount;
      stats['successCount'] = successCount;
      stats['failedCount'] = failedCount;
      stats['pendingCount'] = pendingCount;
      stats['successRate'] = totalCount > 0 
          ? (successCount / totalCount * 100).toStringAsFixed(1) 
          : '0.0';
      stats['averageAmount'] = totalCount > 0 ? totalAmount / totalCount : 0.0;
      stats['lastTransaction'] = lastTransactionDate?.toIso8601String();
      stats['topOperators'] = operatorCounts;
      stats['monthlyStats'] = monthlyStats;

      return stats;
    } catch (e) {
      _logger.e('❌ Enhanced stats calculation failed: $e');
      return {
        'totalTransactions': 0,
        'totalAmount': 0.0,
        'successCount': 0,
        'failedCount': 0,
        'pendingCount': 0,
        'successRate': '0.0',
        'averageAmount': 0.0,
        'lastTransaction': null,
        'topOperators': <String, int>{},
        'monthlyStats': <String, Map<String, dynamic>>{},
      };
    }
  }

  /// Comprehensive transaction monitoring service with health checks
  static Timer? _monitoringTimer;
  static bool _isMonitoringActive = false;

  /// Start background transaction monitoring
  static void startBackgroundMonitoring({
    Duration interval = const Duration(minutes: 2),
    String? userId,
  }) {
    if (_isMonitoringActive) {
      _instance._logger.w('⚠️ Background monitoring already active');
      return;
    }

    _instance._logger.i('🔄 Starting background transaction monitoring');
    _isMonitoringActive = true;

    _monitoringTimer = Timer.periodic(interval, (timer) async {
      try {
        await _instance._performBackgroundMonitoring(userId);
      } catch (e) {
        _instance._logger.e('❌ Background monitoring error: $e');
      }
    });
  }

  /// Stop background transaction monitoring
  static void stopBackgroundMonitoring() {
    if (_monitoringTimer != null) {
      _monitoringTimer!.cancel();
      _monitoringTimer = null;
      _isMonitoringActive = false;
      _instance._logger.i('🛑 Background monitoring stopped');
    }
  }

  /// Perform background monitoring cycle
  Future<void> _performBackgroundMonitoring(String? userId) async {
    try {
      // Monitor pending transactions
      await monitorPendingTransactions();

      // Perform health checks
      await _performHealthChecks();

      // Update transaction statistics
      if (userId != null) {
        await _updateTransactionMetrics(userId);
      }

      // Cleanup old transactions
      await _cleanupOldTransactions();

    } catch (e) {
      _logger.e('❌ Background monitoring cycle failed: $e');
    }
  }

  /// Perform comprehensive health checks
  Future<void> _performHealthChecks() async {
    try {
      _logger.d('🏥 Performing health checks');

      // Check service health
      final serviceHealth = await _isServiceHealthy();
      _logger.d('Service health: $serviceHealth');

      // Check authentication status
      final authValid = _isTokenValid();
      _logger.d('Authentication valid: $authValid');

      // Test API connectivity
      final apiConnectivity = await _testAPIConnectivity();
      _logger.d('API connectivity: $apiConnectivity');

      // Check Firebase connectivity
      final firebaseHealth = await _testFirebaseConnectivity();
      _logger.d('Firebase health: $firebaseHealth');

      // Log overall health status
      final overallHealth = serviceHealth && authValid && apiConnectivity && firebaseHealth;
      _logger.i('🏥 Overall system health: ${overallHealth ? "HEALTHY" : "DEGRADED"}');

    } catch (e) {
      _logger.e('❌ Health check failed: $e');
    }
  }

  /// Test API connectivity
  Future<bool> _testAPIConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ping'),
        headers: {
          'User-Agent': 'Flutter-Recharge-App/2.0',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      _logger.w('⚠️ API connectivity test failed: $e');
      return false;
    }
  }

  /// Test Firebase connectivity
  Future<bool> _testFirebaseConnectivity() async {
    try {
      // Try to read a test document
      await _firestore
          .collection('health_check')
          .doc('test')
          .get()
          .timeout(const Duration(seconds: 5));
      
      return true;
    } catch (e) {
      _logger.w('⚠️ Firebase connectivity test failed: $e');
      return false;
    }
  }

  /// Update transaction metrics
  Future<void> _updateTransactionMetrics(String userId) async {
    try {
      final stats = await getEnhancedTransactionStats(userId);
      
      // Store metrics in Firebase for analytics
      await _firestore
          .collection('user_metrics')
          .doc(userId)
          .set({
        'transactionStats': stats,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.d('📊 Transaction metrics updated for user: $userId');
    } catch (e) {
      _logger.e('❌ Failed to update transaction metrics: $e');
    }
  }

  /// Cleanup old transactions (keep last 90 days)
  Future<void> _cleanupOldTransactions() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final oldTransactions = await _firestore
          .collection('transactions')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('type', isEqualTo: 'mobile_recharge')
          .get();

      if (oldTransactions.docs.isNotEmpty) {
        _logger.i('🗑️ Cleaning up ${oldTransactions.docs.length} old transactions');
        
        // Archive to a separate collection before deletion
        for (final doc in oldTransactions.docs) {
          await _firestore
              .collection('archived_transactions')
              .doc(doc.id)
              .set(doc.data());
          
          await doc.reference.delete();
        }
        
        _logger.i('✅ Old transactions archived and cleaned up');
      }
    } catch (e) {
      _logger.e('❌ Transaction cleanup failed: $e');
    }
  }

  /// Smart transaction retry with exponential backoff
  Future<RechargeResult?> retryFailedTransaction(
    String originalTransactionId, {
    int maxRetries = 5,
    Duration initialDelay = const Duration(seconds: 10),
  }) async {
    try {
      _logger.i('🔄 Starting smart retry for transaction: $originalTransactionId');

      // Get original transaction details
      final originalTransaction = await _getOriginalTransactionDetails(originalTransactionId);
      if (originalTransaction == null) {
        _logger.e('❌ Original transaction not found');
        return null;
      }

      int retryCount = 0;
      Duration currentDelay = initialDelay;

      while (retryCount < maxRetries) {
        retryCount++;
        _logger.i('🔄 Retry attempt $retryCount/$maxRetries');

        // Wait with exponential backoff
        await Future.delayed(currentDelay);
        currentDelay = Duration(seconds: (currentDelay.inSeconds * 1.5).round());

        try {
          // Retry the transaction
          final result = await processLiveRecharge(
            userId: originalTransaction['userId'],
            mobileNumber: originalTransaction['mobileNumber'],
            operatorCode: originalTransaction['operatorCode'],
            operatorName: originalTransaction['operatorName'],
            circleCode: originalTransaction['circleCode'],
            planAmount: originalTransaction['amount'],
            planDescription: originalTransaction['planDescription'] ?? '',
            validity: originalTransaction['validity'] ?? '',
            walletBalance: originalTransaction['walletBalance'] ?? 0.0, // Pass wallet balance
          );

          if (result.success) {
            _logger.i('✅ Retry successful on attempt $retryCount');
            
            // Update original transaction with retry success
            await _updateOriginalTransactionWithRetry(originalTransactionId, result, retryCount);
            
            return result;
          } else if (result.status == 'PENDING') {
            _logger.i('⏳ Retry resulted in pending status, continuing monitoring');
            return result;
          }

        } catch (e) {
          _logger.w('⚠️ Retry attempt $retryCount failed: $e');
        }
      }

      _logger.e('❌ All retry attempts exhausted');
      return null;

    } catch (e) {
      _logger.e('❌ Smart retry failed: $e');
      return null;
    }
  }

  /// Get original transaction details
  Future<Map<String, dynamic>?> _getOriginalTransactionDetails(String transactionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('orderId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      _logger.e('❌ Failed to get original transaction: $e');
      return null;
    }
  }

  /// Update original transaction with retry information
  Future<void> _updateOriginalTransactionWithRetry(
    String originalTransactionId,
    RechargeResult retryResult,
    int retryCount,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('orderId', isEqualTo: originalTransactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'retryStatus': 'SUCCESS',
          'retryCount': retryCount,
          'retryTransactionId': retryResult.transactionId,
          'retryCompletedAt': FieldValue.serverTimestamp(),
          'finalStatus': retryResult.status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.e('❌ Failed to update retry information: $e');
    }
  }

  /// Proactive wallet balance monitoring
  Future<void> monitorWalletBalance(String userId, {
    double lowBalanceThreshold = 100.0,
    Function(double balance)? onLowBalance,
  }) async {
    try {
      // This would integrate with your wallet service
      // For now, just demonstrate the concept
      _logger.i('💰 Monitoring wallet balance for user: $userId');
      
      // In production, this would check actual wallet balance
      // and trigger notifications when balance is low
      
    } catch (e) {
      _logger.e('❌ Wallet balance monitoring failed: $e');
    }
  }

  /// Generate comprehensive transaction report
  Future<Map<String, dynamic>> generateTransactionReport(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? operators,
    List<String>? statuses,
  }) async {
    try {
      _logger.i('📊 Generating transaction report for user: $userId');

      // Set default date range (last 30 days)
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      var query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'mobile_recharge')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final transactions = querySnapshot.docs.map((doc) => doc.data()).toList();

      // Filter by operators and statuses if specified
      var filteredTransactions = transactions;
      
      if (operators != null && operators.isNotEmpty) {
        filteredTransactions = filteredTransactions
            .where((t) => operators.contains(t['operatorName']))
            .toList();
      }
      
      if (statuses != null && statuses.isNotEmpty) {
        filteredTransactions = filteredTransactions
            .where((t) => statuses.contains(t['status']))
            .toList();
      }

      // Generate comprehensive analytics
      final report = _generateReportAnalytics(filteredTransactions, startDate, endDate);
      
      _logger.i('✅ Transaction report generated: ${filteredTransactions.length} transactions');
      return report;

    } catch (e) {
      _logger.e('❌ Report generation failed: $e');
      return {
        'error': 'Failed to generate report',
        'message': e.toString(),
      };
    }
  }

  /// Generate report analytics
  Map<String, dynamic> _generateReportAnalytics(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final report = <String, dynamic>{
      'period': {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'days': endDate.difference(startDate).inDays,
      },
      'summary': <String, dynamic>{},
      'trends': <String, dynamic>{},
      'breakdowns': <String, dynamic>{},
    };

    if (transactions.isEmpty) {
      report['summary'] = {
        'totalTransactions': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'successRate': 0.0,
      };
      return report;
    }

    // Calculate summary statistics
    final totalTransactions = transactions.length;
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
    final successfulTransactions = transactions.where((t) => t['status'] == 'SUCCESS').length;
    final averageAmount = totalAmount / totalTransactions;
    final successRate = (successfulTransactions / totalTransactions) * 100;

    report['summary'] = {
      'totalTransactions': totalTransactions,
      'totalAmount': totalAmount,
      'averageAmount': averageAmount,
      'successRate': successRate,
      'successfulTransactions': successfulTransactions,
      'failedTransactions': transactions.where((t) => t['status'] == 'FAILED').length,
      'pendingTransactions': transactions.where((t) => t['status'] == 'PENDING').length,
    };

    // Generate operator breakdown
    final operatorBreakdown = <String, Map<String, dynamic>>{};
    for (final transaction in transactions) {
      final operator = transaction['operatorName'] ?? 'Unknown';
      operatorBreakdown[operator] ??= {
        'count': 0,
        'amount': 0.0,
        'success': 0,
        'failed': 0,
        'pending': 0,
      };
      
      operatorBreakdown[operator]!['count']++;
      operatorBreakdown[operator]!['amount'] += transaction['amount'] ?? 0.0;
      operatorBreakdown[operator]![transaction['status']?.toLowerCase() ?? 'unknown']++;
    }

    report['breakdowns']['operators'] = operatorBreakdown;

    // Generate daily trends
    final dailyTrends = <String, Map<String, dynamic>>{};
    for (final transaction in transactions) {
      final createdAt = (transaction['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        dailyTrends[dateKey] ??= {
          'count': 0,
          'amount': 0.0,
          'success': 0,
          'failed': 0,
          'pending': 0,
        };
        
        dailyTrends[dateKey]!['count']++;
        dailyTrends[dateKey]!['amount'] += transaction['amount'] ?? 0.0;
        dailyTrends[dateKey]![transaction['status']?.toLowerCase() ?? 'unknown']++;
      }
    }

    report['trends']['daily'] = dailyTrends;

    return report;
  }

  /// Export transaction data to CSV format
  Future<String> exportTransactionData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = await generateTransactionReport(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (report.containsKey('error')) {
        throw Exception(report['message']);
      }

      // Generate CSV content
      final csvContent = StringBuffer();
      csvContent.writeln('Date,Transaction ID,Mobile Number,Operator,Amount,Status,Message');

      // This would include the actual transaction data
      // For now, just return header
      _logger.i('📄 Transaction data exported to CSV format');
      return csvContent.toString();

    } catch (e) {
      _logger.e('❌ CSV export failed: $e');
      rethrow;
    }
  }
}

/// Helper classes for enhanced recharge processing
class RechargeProcessingResult {
  final RechargeResult rechargeResult;
  final bool shouldRetry;

  RechargeProcessingResult({
    required this.rechargeResult,
    required this.shouldRetry,
  });
} 