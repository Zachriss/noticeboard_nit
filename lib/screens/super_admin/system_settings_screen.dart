import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../models/user_model.dart';
import 'system_reports_screen.dart';
import 'categories_screen.dart';
import 'users_management_screen.dart';

class SystemSettingsScreen extends StatefulWidget {
  final bool useScaffold;
  const SystemSettingsScreen({super.key, this.useScaffold = true});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
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
    if (!widget.useScaffold) return _buildContent();

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
              if (value == 'logout') {
                _logout();
              } else if (value == 'reports')
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      children: [
        _buildSectionHeader('App Settings'),
        _buildSettingsItem(
          Icons.style,
          'App Theme',
          'Change app colors and theme',
        ),
        _buildSettingsItem(
          Icons.branding_watermark,
          'App Logo',
          'Upload custom logo',
        ),
        _buildSettingsItem(
          Icons.image,
          'Splash Screen',
          'Manage splash screen',
        ),
        const Divider(),
        _buildSectionHeader('Security'),
        _buildSettingsItem(
          Icons.security,
          'Permissions',
          'Manage user permissions',
        ),
        _buildSettingsItem(
          Icons.backup,
          'Database Backup',
          'Backup system data',
        ),
        _buildSettingsItem(
          Icons.restore,
          'Restore Data',
          'Restore from backup',
        ),
        _buildSettingsItem(
          Icons.history,
          'Login History',
          'View login activity',
        ),
        const Divider(),
        _buildSectionHeader('Emergency Controls'),
        _buildSettingsItem(
          Icons.lock,
          'Lock Admin Accounts',
          'Suspend admin access',
        ),
        _buildSettingsItem(
          Icons.block,
          'Disable Posting',
          'Temporarily disable notices',
        ),
        _buildSettingsItem(
          Icons.announcement,
          'Broadcast Announcement',
          'Send urgent message',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
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
