import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../models/user_model.dart';
import 'categories_screen.dart';
import 'users_management_screen.dart';
import 'system_settings_screen.dart';

class SystemReportsScreen extends StatefulWidget {
  final bool useScaffold;
  const SystemReportsScreen({super.key, this.useScaffold = true});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final user = await _authService.getUserData(currentUser.uid);
      if (mounted) setState(() => _user = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.analytics,
          size: 64,
          color: AppTheme.primaryColor.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        const Text(
          'System Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Reports feature coming soon',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );

    if (!widget.useScaffold) return content;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            const Text(
              'NIT Noticeboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  _user?.name.isNotEmpty == true
                      ? _user!.name[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'reports', child: Text('Reports')),
              const PopupMenuItem(
                value: 'categories',
                child: Text('Categories'),
              ),
              const PopupMenuItem(value: 'users', child: Text('Users')),
              const PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.secondaryColor),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout')
                _logout();
              else if (value == 'reports')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SystemReportsScreen()),
                );
              else if (value == 'categories')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoriesScreen()),
                );
              else if (value == 'users')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersManagementScreen()),
                );
              else if (value == 'settings')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SystemSettingsScreen()),
                );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }
}
