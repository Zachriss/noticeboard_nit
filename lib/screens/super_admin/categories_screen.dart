import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../models/user_model.dart';
import 'system_reports_screen.dart';
import 'users_management_screen.dart';
import 'system_settings_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final bool useScaffold;
  const CategoriesScreen({super.key, this.useScaffold = true});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _categories = [
    'Academic',
    'Exams',
    'Events',
    'Library',
    'Placement',
    'Sports',
    'General',
  ];
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

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _categories.add(controller.text.trim()));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added successfully')),
                );
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCategoryDialog(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _categories[index],
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _categories[index] = controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${_categories[index]}" category?',
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
      setState(() => _categories.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
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
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        heroTag: 'categories_fab',
      ),
    );
  }

  Widget _buildContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(_categories[index]),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.category, color: Colors.white, size: 18),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(index);
                } else if (value == 'delete') {
                  _deleteCategory(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
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
