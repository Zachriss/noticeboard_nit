import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../screens/auth/login_screen.dart';
import 'system_reports_screen.dart';
import 'categories_screen.dart';
import 'system_settings_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  final bool useScaffold;
  const UsersManagementScreen({super.key, this.useScaffold = true});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final AuthService _authService = AuthService();
  String _searchQuery = '';
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

  Stream<List<UserModel>> get usersStream => _authService.getAllUsers();

  Future<void> _showAddUserDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Email Address'),
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Password'),
              ),
              DropdownMenu<String>(
                label: const Text('User Role'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'student', label: 'Student'),
                  DropdownMenuEntry(value: 'admin', label: 'Admin'),
                  DropdownMenuEntry(value: 'superAdmin', label: 'Super Admin'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserDialog(UserModel user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String? selectedRole;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email address';
                      }
                      // Simple email validation
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                   DropdownMenuFormField<String>(
                     initialSelection: selectedRole ?? user.role.name,
                     label: const Text('User Role'),
                     dropdownMenuEntries: const [
                       DropdownMenuEntry(value: 'student', label: 'Student'),
                       DropdownMenuEntry(value: 'admin', label: 'Admin'),
                       DropdownMenuEntry(value: 'superAdmin', label: 'Super Admin'),
                     ],
                     onSelected: (value) {
                       setState(() => selectedRole = value);
                     },
                     validator: (value) {
                       if (value == null) {
                         return 'Please select a role';
                       }
                       return null;
                     },
                   ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          final updatedUser = user.copyWith(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            role: UserRole.values.firstWhere(
                              (e) => e.name == selectedRole,
                              orElse: () => user.role,
                            ),
                          );

                          await _authService.updateUserProfile(updatedUser);
                          
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User updated successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update user: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      }
                    },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await _authService.updateUserStatus(user.id, !user.isDisabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${user.isDisabled ? 'enabled' : 'disabled'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user')),
          );
        }
      }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];
              final filteredUsers = _searchQuery.isEmpty
                  ? users
                  : users
                        .where(
                          (user) =>
                              user.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              user.email.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

              if (filteredUsers.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.role == UserRole.superAdmin
                            ? Colors.purple
                            : user.role == UserRole.admin
                            ? Colors.blue
                            : Colors.green,
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.isDisabled
                                  ? Colors.red.shade100
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isDisabled
                                  ? 'Disabled'
                                  : user.role.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: user.isDisabled
                                    ? Colors.red
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              user.isDisabled
                                  ? Icons.check_circle_outline
                                  : Icons.block,
                              color: user.isDisabled
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            onPressed: () => _toggleUserStatus(user),
                            tooltip: user.isDisabled
                                ? 'Enable User'
                                : 'Disable User',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditUserDialog(user),
                            tooltip: 'Edit User',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user),
                            tooltip: 'Delete User',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
