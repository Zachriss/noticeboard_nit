import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'shared_preferences/local_storage.dart';
import 'screens/student/student_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/student/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize local storage
  await LocalStorage.init();
  
  runApp(const MyApp());
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
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final role = LocalStorage.userRole;
    
    // Check if profile needs setup (for students first launch)
    if (role == 'student' && !LocalStorage.isProfileSetup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      return;
    }

    // Navigate based on role
    Widget homeScreen;
    switch (role) {
      case 'admin':
        homeScreen = const AdminDashboard();
        break;
      case 'super_admin':
        homeScreen = const SuperAdminDashboard();
        break;
      case 'student':
      default:
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
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
