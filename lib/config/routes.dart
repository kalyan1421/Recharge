import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/mobile_verification_screen.dart';
import '../presentation/screens/auth/otp_verification_screen.dart';
import '../presentation/screens/auth/otp_verification_signup_screen.dart';
import '../presentation/screens/auth/phone_signup_screen.dart';
import '../presentation/screens/auth/registration_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/recharge_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const PhoneSignupScreen(),
    ),
    GoRoute(
      path: '/mobile-verification',
      builder: (context, state) => const MobileVerificationScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) => OtpVerificationScreen(
        phoneNumber: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/otp-verification-signup',
      builder: (context, state) => OtpVerificationSignupScreen(
        phoneNumber: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/registration',
      builder: (context, state) => RegistrationScreen(
        phoneNumber: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/recharge',
      builder: (context, state) => const RechargeScreen(),
    ),
  ],
); 