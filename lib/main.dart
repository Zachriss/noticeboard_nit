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

    final role = LocalStorage.userRole;

    // For students, auto sign in with Firebase Anonymous Auth
    if (role == 'student') {
      try {
        final studentAuth = StudentAuthService();
        await studentAuth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous auth failed: $e');
      }
    }

    if (!mounted) return;

    Widget homeScreen;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdminSignedIn =
        currentUser != null &&
        !currentUser.isAnonymous &&
        LocalStorage.userRole != 'student';

    if (role == 'student' && !LocalStorage.isProfileSetup) {
      homeScreen = const ProfileSetupScreen();
    } else if ((role == 'admin' || role == 'super_admin') && isAdminSignedIn) {
      homeScreen = role == 'super_admin'
          ? const SuperAdminDashboard()
          : const AdminDashboard();
    } else {
      homeScreen = const StudentHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => homeScreen),
    );
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