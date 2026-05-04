import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class SuperAdminProfileScreen extends StatefulWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  State<SuperAdminProfileScreen> createState() =>
      _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends State<SuperAdminProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final user = await _authService.getUserData(currentUser.uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _user == null
          ? _buildNotLoggedIn()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              _user!.name.isNotEmpty
                                  ? _user!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _user!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user!.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(
                                _user!.role,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getRoleName(_user!.role),
                              style: TextStyle(
                                color: _getRoleColor(_user!.role),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Details
                  Card(
                    child: Column(
                      children: [
                        if (_user!.department != null)
                          _buildProfileItem(
                            icon: Icons.school,
                            label: 'Department',
                            value: _user!.department!,
                          ),
                        if (_user!.year != null)
                          _buildProfileItem(
                            icon: Icons.calendar_today,
                            label: 'Year',
                            value: _user!.year!,
                          ),
                        _buildProfileItem(
                          icon: Icons.verified,
                          label: 'Status',
                          value: _user!.isApproved ? 'Approved' : 'Pending',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Not logged in',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.admin:
        return Colors.orange;
      case UserRole.student:
        return AppTheme.primaryColor;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.student:
        return 'Student';
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
