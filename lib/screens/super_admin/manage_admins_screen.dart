import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../screens/auth/login_screen.dart';
import 'system_reports_screen.dart';
import 'categories_screen.dart';
import 'users_management_screen.dart';
import 'system_settings_screen.dart';
import 'profile_screen.dart';

class ManageAdminsScreen extends StatefulWidget {
  final bool useScaffold;
  const ManageAdminsScreen({super.key, this.useScaffold = true});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
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
              } else if (value == 'profile')
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuperAdminProfileScreen(),
                  ),
                );
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final admins = users.where((u) => u.role == UserRole.admin).toList();

        if (admins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No admins found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admins will appear here once registered',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];
            return _buildAdminCard(admin);
          },
        );
      },
    );
  }

  Widget _buildAdminCard(UserModel admin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: admin.isApproved
              ? AppTheme.primaryColor
              : Colors.grey,
          child: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          admin.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(admin.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  admin.isApproved ? Icons.check_circle : Icons.pending,
                  size: 16,
                  color: admin.isApproved ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  admin.isApproved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: admin.isApproved ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: admin.isApproved
            ? null
            : ElevatedButton(
                onPressed: () => _approveAdmin(admin),
                child: const Text('Approve'),
              ),
      ),
    );
  }

  Future<void> _approveAdmin(UserModel admin) async {
    await _authService.approveAdmin(admin.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin approved'),
        backgroundColor: Colors.green,
      ),
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
