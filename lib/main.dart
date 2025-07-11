import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'core/theme/app_theme.dart';
import 'config/routes.dart';
import 'config/provider_setup.dart';
import 'config/firebase_config.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI
  await _configureSystemUI();
  
  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for development
  }
  
  // Initialize ResponsiveBuilder with custom breakpoints
  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(
      tablet: 768,
      desktop: 1024,
      watch: 200,
    ),
  );
  
  // Run the app
  runApp(const SamyPayApp());
}

/// Configure system UI overlay style
Future<void> _configureSystemUI() async {
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class SamyPayApp extends StatelessWidget {
  const SamyPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderSetup.createApp(
      child: MaterialApp.router(
        title: 'SamyPay',
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        
        // Routing Configuration
        routerConfig: AppRouter.router,
        
        // Localization Configuration
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
        ],
        
        // App Configuration
        builder: (context, child) {
          return ResponsiveBuilder(
            builder: (context, sizingInformation) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_getTextScaleFactor(sizingInformation)),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
        
        // Error handling
        onGenerateTitle: (context) => 'SamyPay',
      ),
    );
  }
  
  /// Get appropriate text scale factor based on device type
  double _getTextScaleFactor(SizingInformation sizingInformation) {
    if (sizingInformation.isDesktop) {
      return 1.0;
    } else if (sizingInformation.isTablet) {
      return 1.1;
    } else {
      return 1.0;
    }
  }
}