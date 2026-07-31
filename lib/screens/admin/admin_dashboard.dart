import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notice_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';
import '../../providers/notification_provider.dart';
import '../../shared_preferences/local_storage.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/notice_card.dart';
import '../notifications/notification_screen.dart';
import '../student/student_home.dart';
import '../super_admin/profile_screen.dart';
import 'create_notice_screen.dart';
import 'manage_notices_screen.dart';
import 'feedback_list_screen.dart';
import 'faq_manage_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final NoticeService _noticeService = NoticeService();
  final AuthService _authService = AuthService();
  UserModel? _user;
  int _currentIndex = 0;

  int _totalNotices = 0;
  int _pendingNotices = 0;
  int _totalLikes = 0;
  int _totalUsers = 0;
  int _totalFeedback = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    final user = await _authService.getUserData(currentUser.uid);
    if (!mounted) return;

    setState(() => _user = user);

    if (user != null) {
      context.read<NotificationProvider>().initialize(
        userId: user.id,
        role: user.role.name,
      );
      await _loadStatistics(user.id);
    } else {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadStatistics(String userId) async {
    if (!mounted) return;

    // Load each stat independently so one failure doesn't break all counts
    int totalNotices = 0;
    int pendingNotices = 0;
    int totalLikes = 0;
    int totalUsers = 0;
    int totalFeedback = 0;

    try {
      totalNotices = await _noticeService.getAllNoticesCount();
    } catch (_) {}

    try {
      pendingNotices = await _noticeService.getAllPendingNoticesCount();
    } catch (_) {}

    try {
      totalLikes = await _noticeService.getAllLikesCount();
    } catch (_) {}

    try {
      totalUsers = await _noticeService.getAllUsersCount();
    } catch (_) {}

    try {
      totalFeedback = await _noticeService.getTotalFeedbackCount();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _totalNotices = totalNotices;
      _pendingNotices = pendingNotices;
      _totalLikes = totalLikes;
      _totalUsers = totalUsers;
      _totalFeedback = totalFeedback;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return NotificationBadge(
                count: provider.unreadCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SuperAdminProfileScreen(),
                ),
              );
            },
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
                        _user?.name.isNotEmpty == true
                            ? _user!.name[0].toUpperCase()
                            : 'A',
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
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
          
              const PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.secondaryColor),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                setState(() => _currentIndex = 3);
              } else if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const ManageNoticesScreen(),
          const AdminFeedbackScreen(),
          const FaqManageScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateNoticeScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Notice'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Notices'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'FAQs'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: LocalStorage.profileImage.isNotEmpty
                        ? MemoryImage(base64Decode(LocalStorage.profileImage))
                            as ImageProvider
                        : null,
                    child: LocalStorage.profileImage.isEmpty
                        ? Text(
                            _user?.name.isNotEmpty == true
                                ? _user!.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_user?.name ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          const Text(
            'Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _isLoadingStats ? '-' : '$_totalNotices',
                  'My Notices',
                  Icons.article,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  _isLoadingStats ? '-' : '$_pendingNotices',
                  'Pending',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _isLoadingStats ? '-' : '$_totalLikes',
                  'Total Likes',
                  Icons.thumb_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  _isLoadingStats ? '-' : '$_totalUsers',
                  'Users',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  _isLoadingStats ? '-' : '$_totalFeedback',
                  'Feedback',
                  Icons.feedback,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Notices
          const Text(
            'Recent Notices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<NoticeModel>>(
            stream: _noticeService.getNoticesByAuthor(_user?.id ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notices = snapshot.data ?? [];
              if (notices.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notices yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notices.length > 5 ? 5 : notices.length,
                itemBuilder: (context, index) {
                  return NoticeCard(notice: notices[index], showActions: false);
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Manage FAQs shortcut
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FaqManageScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Manage FAQs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    // Preserve student profile data; restore student role so splash routes to student home
    await LocalStorage.setUserRole('student');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
      (route) => false,
    );
  }
}
