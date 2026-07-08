import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_badge.dart';
import '../shared_preferences/local_storage.dart';
import '../services/student_auth_service.dart';
import '../services/auth_service.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/help/help_center_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/login_screen.dart';

/// Reusable AppBar for all student screens
/// Provides consistent styling across Home, Favourite, Events, Feedback, and FAQs screens
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final BuildContext screenContext;

  const CommonAppBar({
    super.key,
    this.title,
    this.onProfileTap,
    this.onLogout,
    required this.screenContext,
  });

  void _showProfileMenu() {
    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                LocalStorage.userName.isNotEmpty
                    ? LocalStorage.userName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocalStorage.userName.isNotEmpty
                  ? LocalStorage.userName
                  : 'Student',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${LocalStorage.userDepartment} • ${LocalStorage.userYear}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.secondaryColor),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
                if (onLogout != null) onLogout!();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: screenContext,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await StudentAuthService().signOut();
              } catch (e) {
                // Ignore sign out errors
              }
              try {
                await AuthService().logout();
              } catch (e) {
                // Ignore
              }
              if (screenContext.mounted) {
                Navigator.pushAndRemoveUntil(
                  screenContext,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text(
            title ?? 'NIT Noticeboard',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return NotificationBadge(
              count: provider.unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            );
          },
        ),
        GestureDetector(
          onTap: () {
            _showProfileMenu();
            if (onProfileTap != null) onProfileTap!();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                LocalStorage.userName.isNotEmpty
                    ? LocalStorage.userName[0].toUpperCase()
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
            const PopupMenuItem(value: 'downloads', child: Text('Downloads')),
            const PopupMenuItem(
              value: 'help_center',
              child: Text('Help Center'),
            ),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(value: 'about', child: Text('About App')),
            const PopupMenuItem(
              value: 'admin_login',
              child: Text('Admin Login'),
            ),
          ],
          onSelected: (value) {
            if (value == 'admin_login') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } else if (value == 'about') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            } else if (value == 'help_center') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
