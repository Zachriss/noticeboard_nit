import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/notice_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/bottom_navigation_provider.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/notice_card.dart';
import '../../shared_preferences/local_storage.dart';
import '../../services/notice_service.dart';
import '../../services/auth_service.dart';
import '../notifications/notification_screen.dart';
import 'notice_details_screen.dart';
import 'profile_setup_screen.dart';
import 'favourite_screen.dart';
import 'feedback_screen.dart';
import 'faq_screen.dart';
import '../auth/login_screen.dart';
import '../../services/student_auth_service.dart';
import '../about/about_screen.dart';
import '../help/help_center_screen.dart';
import '../settings/settings_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final NoticeService _noticeService = NoticeService();
  final AuthService _authService = AuthService();

  String _searchText = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // "All" plus every system category so all categories (including Scams/Fraud)
  // are available in the student filter.
  final List<String> _categories = ['All', ...AppStrings.categories];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Ensure student is signed in with anonymous Firebase Auth
    try {
      final studentAuth = StudentAuthService();
      await studentAuth.signInAnonymously();
    } catch (e) {
      debugPrint('Student anonymous auth failed: $e');
    }

    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      if (mounted) {
        context.read<NotificationProvider>().initialize(
          userId: firebaseUser.uid,
          role: 'student',
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BottomNavigationProvider(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<BottomNavigationProvider>(
          builder: (context, provider, _) => IndexedStack(
            index: provider.currentIndex,
            children: [
              _buildHomeTab(),
              const FavouriteScreen(),
              const FeedbackScreen(),
              const FaqScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Consumer<BottomNavigationProvider>(
          builder: (context, provider, _) => BottomNavigationBar(
            currentIndex: provider.currentIndex,
            onTap: (index) =>
                context.read<BottomNavigationProvider>().setIndex(index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favourite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feedback),
                label: 'Feedback',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.help), label: 'FAQs'),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
          const Text(
            'NIT Noticeboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          onTap: () => _showProfileMenu(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: LocalStorage.profileImage.isNotEmpty
                  ? MemoryImage(base64Decode(LocalStorage.profileImage))
                      as ImageProvider
                  : null,
              child: LocalStorage.profileImage.isEmpty
                  ? Text(
                      LocalStorage.userName.isNotEmpty
                          ? LocalStorage.userName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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

  Widget _buildHomeTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search notices...',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category Filter Dropdown
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text(
                'Filter by:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory ?? 'All',
                      hint: const Text('Select category'),
                      isExpanded: true,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value == 'All' ? null : value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notices List from Firebase
        Expanded(child: _buildNoticesList()),
      ],
    );
  }

  Widget _buildNoticesList() {
    return StreamBuilder<List<NoticeModel>>(
      // Always use the indexed "approved + createdAt" query, then filter
      // category/search client-side. This avoids needing a composite index
      // on (status, category, createdAt) which would fail when online.
      stream: _noticeService.getAllNotices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notices',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        var notices = snapshot.data ?? [];

        // Filter by selected category (client-side)
        if (_selectedCategory != null) {
          notices = notices
              .where((n) => n.category == _selectedCategory)
              .toList();
        }

        // Filter by search text
        if (_searchText.isNotEmpty) {
          notices = notices.where((n) {
            return n.title.toLowerCase().contains(_searchText.toLowerCase()) ||
                n.description.toLowerCase().contains(_searchText.toLowerCase());
          }).toList();
        }

        if (notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No notices found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return NoticeCard(
              notice: notice,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeDetailScreen(notice: notice),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
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
              backgroundImage: LocalStorage.profileImage.isNotEmpty
                  ? MemoryImage(base64Decode(LocalStorage.profileImage))
                      as ImageProvider
                  : null,
              child: LocalStorage.profileImage.isEmpty
                  ? Text(
                      LocalStorage.userName.isNotEmpty
                          ? LocalStorage.userName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSetupScreen(isEditMode: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
