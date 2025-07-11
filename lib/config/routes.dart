import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/mobile_verification_screen.dart';
import '../presentation/screens/auth/otp_verification_screen.dart';
import '../presentation/screens/auth/phone_signup_screen.dart';
import '../presentation/screens/auth/otp_verification_signup_screen.dart';
import '../presentation/screens/auth/registration_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/add_money_screen.dart';
import '../presentation/screens/enhanced_transaction_report_screen.dart';

/// Application routes configuration using GoRouter for navigation
class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/mobile-verification',
        name: 'mobile-verification',
        builder: (context, state) => const MobileVerificationScreen(),
      ),
      
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) => OtpVerificationScreen(
          phoneNumber: state.extra as String? ?? '',
        ),
      ),
      
      GoRoute(
        path: '/phone-signup',
        name: 'phone-signup',
        builder: (context, state) => const PhoneSignupScreen(),
      ),
      
      GoRoute(
        path: '/otp-verification-signup',
        name: 'otp-verification-signup',
        builder: (context, state) => OtpVerificationSignupScreen(
          phoneNumber: state.extra as String? ?? '',
        ),
      ),
      
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => RegistrationScreen(
          phoneNumber: state.extra as String?,
        ),
      ),
      
      // Add Money Screen
      GoRoute(
        path: '/add-money',
        name: 'add-money',
        builder: (context, state) => const AddMoneyScreen(),
      ),
      
      // Transaction Report Screen
      GoRoute(
        path: '/transaction-report',
        name: 'transaction-report',
        builder: (context, state) => const EnhancedTransactionReportScreen(),
      ),
      
      // Home Screen with Main Navigation
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Helper method to navigate to a named route
  static void navigateToRoute(BuildContext context, String routeName, {Object? extra}) {
    GoRouter.of(context).pushNamed(routeName, extra: extra);
  }
} 