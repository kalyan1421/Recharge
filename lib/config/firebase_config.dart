import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static final Logger _logger = Logger();
  
  // Firebase instances
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;
  
  /// Initialize Firebase with all required services
  static Future<void> initialize() async {
    try {
      _logger.i('Initializing Firebase...');
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize App Check for security
      await _initializeAppCheck();
      
      _logger.i('Firebase initialized successfully');
      
      // Initialize Firestore settings
      await _initializeFirestore();
      
      // Initialize Firebase Auth settings
      await _initializeAuth();
      
      // Initialize Analytics (only for release builds)
      if (kReleaseMode) {
        await _initializeAnalytics();
      }
      
      // Initialize Crashlytics (only for release builds)
      if (kReleaseMode) {
        await _initializeCrashlytics();
      }
      
      // Initialize Push Notifications
      await _initializeMessaging();
      
      _logger.i('All Firebase services initialized successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Firebase initialization failed: $e');
      rethrow;
    }
  }
  
  /// Initialize Firebase App Check for security
  static Future<void> _initializeAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for debug builds, reCAPTCHA for release
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
      _logger.i('Firebase App Check initialized successfully');
    } catch (e) {
      _logger.w('Firebase App Check initialization failed: $e');
      // Continue without App Check - it's not critical for basic functionality
    }
  }
  
  /// Initialize Firestore with optimized settings
  static Future<void> _initializeFirestore() async {
    try {
      // Configure settings with persistence enabled
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      _logger.i('Firestore initialized with offline persistence');
    } catch (e) {
      _logger.w('Firestore persistence not available: $e');
    }
  }

  /// Initialize Firebase Auth settings
  static Future<void> _initializeAuth() async {
    try {
      // Configure Auth settings for debug mode
      if (kDebugMode) {
        // Additional auth settings for debug mode can be added here
      }
      
      _logger.i('Firebase Auth initialized');
    } catch (e) {
      _logger.w('Firebase Auth initialization warning: $e');
    }
  }
  
  /// Initialize Firebase Analytics
  static Future<void> _initializeAnalytics() async {
    try {
      await analytics.setAnalyticsCollectionEnabled(true);
      _logger.i('Firebase Analytics initialized');
    } catch (e) {
      _logger.w('Firebase Analytics initialization failed: $e');
    }
  }
  
  /// Initialize Firebase Crashlytics
  static Future<void> _initializeCrashlytics() async {
    try {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      
      _logger.i('Firebase Crashlytics initialized');
    } catch (e) {
      _logger.w('Firebase Crashlytics initialization failed: $e');
    }
  }
  
  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted permission for notifications');
        
        // Get FCM token
        String? token = await messaging.getToken();
        _logger.i('FCM Token: $token');
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
        
        // Handle notification taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
      } else {
        _logger.w('User denied permission for notifications');
      }
    } catch (e) {
      _logger.w('Firebase Messaging initialization failed: $e');
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // TODO: Show in-app notification
    if (message.notification != null) {
      _logger.i('Notification: ${message.notification!.title}');
      _logger.i('Body: ${message.notification!.body}');
    }
    
    // TODO: Handle data payload
    if (message.data.isNotEmpty) {
      _logger.i('Data: ${message.data}');
    }
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    
    // TODO: Navigate to appropriate screen based on message data
    if (message.data.isNotEmpty) {
      _logger.i('Handling notification tap with data: ${message.data}');
    }
  }
  
  /// Get current user
  static User? get currentUser => auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  /// Sign out user
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }
  
  /// Get Firestore collection reference
  static CollectionReference getCollection(String collectionName) {
    return firestore.collection(collectionName);
  }
  
  /// Get Storage reference
  static Reference getStorageRef(String path) {
    return storage.ref().child(path);
  }
  
  /// Log analytics event
  static Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    if (kReleaseMode) {
      try {
        await analytics.logEvent(name: name, parameters: parameters);
      } catch (e) {
        _logger.w('Analytics event logging failed: $e');
      }
    }
  }
  
  /// Log custom error to Crashlytics
  static void logError(dynamic error, StackTrace? stackTrace, {String? reason}) {
    if (kReleaseMode) {
      try {
        crashlytics.recordError(error, stackTrace, reason: reason);
      } catch (e) {
        _logger.w('Error logging to Crashlytics failed: $e');
      }
    }
  }
  

}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final logger = Logger();
  logger.i('Received background message: ${message.messageId}');
  
  // TODO: Handle background message
  if (message.data.isNotEmpty) {
    logger.i('Background message data: ${message.data}');
  }
} 