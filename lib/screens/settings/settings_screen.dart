import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoRefreshEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.primaryColor),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock, color: AppTheme.primaryColor),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                  title: const Text('Push Notifications'),
                  value: _notificationsEnabled,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                  title: const Text('Auto Refresh Notices'),
                  value: _autoRefreshEnabled,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() => _autoRefreshEnabled = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: AppTheme.primaryColor),
              title: const Text('Dark Mode'),
              value: _darkModeEnabled,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
              },
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: AppTheme.primaryColor),
                  title: const Text('About App'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help, color: AppTheme.primaryColor),
                  title: const Text('Help Center'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Version Info
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}