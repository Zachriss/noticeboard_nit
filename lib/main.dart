import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'config/firebase_options.dart';
import 'shared_preferences/local_storage.dart';
import 'screens/student/student_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/student/profile_setup_screen.dart';
import 'providers/notification_provider.dart';
import 'providers/favourite_provider.dart';
import 'providers/feedback_provider.dart';
import 'services/notification_service.dart';
import 'services/student_auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize firebase with platform options (required for web)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init failure logged but won't block app startup
    debugPrint('Firebase initialization failed (will retry): $e');
  }

  // Initialize local storage (shared_preferences compatible with web)
  try {
    await LocalStorage.init();
  } catch (e) {
    debugPrint('LocalStorage initialization failed: $e');
  }

  // FCM notifications not supported on web; skip gracefully
  try {
    NotificationService.navigatorKey = navigatorKey;
    await NotificationService().initializeNotificationSystem();
  } catch (e) {
    debugPrint('NotificationService initialization skipped: $e');
  }

  runApp(
      MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NIT Notice Board',
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Safe async initialization that always renders the splash screen first,
  /// then navigates away once everything is ready.
  Future<void> _initializeApp() async {
    // Show splash for at least 2 seconds for branding visibility
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Retry Firebase init if it failed in main()
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init retry failed: $e');
    }

    // Retry LocalStorage init if it failed in main()
    try {
      await LocalStorage.init();
    } catch (e) {
      debugPrint('LocalStorage retry failed: $e');
    }

    if (!mounted) return;

    // Determine navigation target based on role and profile status
    // For students: check LocalStorage first, navigate immediately without waiting for Firebase
    final role = LocalStorage.userRole;
    
    Widget? homeScreen;
    
    // Student-specific logic: navigate immediately based on profile setup status
    if (role == 'student') {
      if (!LocalStorage.isProfileSetup) {
        homeScreen = const ProfileSetupScreen();
      } else {
        homeScreen = const StudentHomeScreen();
      }
    } 
    // Admin/Super Admin logic remains unchanged - requires Firebase authentication
    else if (role == 'admin' || role == 'super_admin') {
      final currentUser = FirebaseAuth.instance.currentUser;
      final isAdminSignedIn =
          currentUser != null &&
          !currentUser.isAnonymous &&
          LocalStorage.userRole != 'student';
      
      if (isAdminSignedIn) {
        homeScreen = role == 'super_admin'
            ? const SuperAdminDashboard()
            : const AdminDashboard();
      }
    }
    
    // If we determined a home screen, navigate immediately
    if (homeScreen != null) {
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => homeScreen!),
      );
      
      // For students only: perform Firebase initialization in background after navigation
      if (role == 'student') {
        _initializeStudentFirebaseInBackground();
      }
      
      return;
    }
    
    // Fallback for admin/super_admin when not signed in (shouldn't happen normally)
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
    );
  }

  /// Check if internet connectivity is available using DNS lookup.
  /// Returns true if the device can reach the internet, false otherwise.
  Future<bool> _checkInternetConnectivity() async {
    try {
      // Use a quick DNS lookup to check connectivity
      // This is more reliable than just checking network interfaces
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return false;
    }
  }

  /// Initialize Firebase services for students in the background after navigation.
  /// This includes anonymous authentication, FCM token retrieval, and notification setup.
  /// Failures are silent and will be retried when connectivity is available.
  Future<void> _initializeStudentFirebaseInBackground() async {
    // Check connectivity first using DNS lookup
    final hasInternet = await _checkInternetConnectivity();
    
    if (!hasInternet) {
      debugPrint('No internet connectivity. Student Firebase init will be retried when online.');
      // Set up periodic retry to check for connectivity
      _setupConnectivityRetry();
      return;
    }

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (e) {
          debugPrint('Firebase init in background failed: $e');
          _setupConnectivityRetry();
          return;
        }
      }

      // Perform anonymous authentication
      try {
        final studentAuth = StudentAuthService();
        await studentAuth.signInAnonymously();
        debugPrint('Student anonymous authentication completed in background');
      } catch (e) {
        debugPrint('Background anonymous auth failed: $e');
        // Continue to try FCM even if auth fails
      }

      // Initialize notification system
      try {
        NotificationService.navigatorKey = navigatorKey;
        await NotificationService().initializeNotificationSystem();
        
        // Save FCM token now that student is authenticated
        final token = await NotificationService().getFcmToken();
        if (token != null && token.isNotEmpty) {
          await NotificationService().saveTokenForCurrentUser(token);
          debugPrint('FCM token saved in background');
        }
      } catch (e) {
        debugPrint('Background notification initialization failed: $e');
      }
    } catch (e) {
      debugPrint('Student background initialization failed: $e');
      _setupConnectivityRetry();
    }
  }

  /// Sets up periodic retry to check for connectivity and initialize Firebase when available.
  void _setupConnectivityRetry() {
    // Retry every 10 seconds until successful
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final hasInternet = await _checkInternetConnectivity();
      if (hasInternet) {
        debugPrint('Internet connectivity restored. Retrying student Firebase initialization...');
        timer.cancel();
        await _initializeStudentFirebaseInBackground();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NIT Notice Board',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Campus Notice Hub',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}