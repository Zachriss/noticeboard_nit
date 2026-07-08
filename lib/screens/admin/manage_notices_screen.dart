import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notice_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';
import 'create_notice_screen.dart';
import '../student/notice_details_screen.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  final NoticeService _noticeService = NoticeService();
  final AuthService _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _authService.currentUser;
    if (mounted) setState(() => _userId = user?.uid);
  }

  Future<void> _approveNotice(NoticeModel notice) async {
    try {
      await _noticeService.approveNotice(notice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Notices'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNoticesList(null),
            _buildNoticesList(NoticeStatus.pending),
            _buildNoticesList(NoticeStatus.approved),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateNoticeScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNoticesList(NoticeStatus? statusFilter) {
    return StreamBuilder<List<NoticeModel>>(
      stream: _noticeService.getNoticesByAuthor(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var notices = snapshot.data ?? [];
        
        if (statusFilter != null) {
          notices = notices.where((n) => n.status == statusFilter).toList();
        }

        if (notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  statusFilter != null 
                      ? 'No ${statusFilter.name} notices'
                      : 'No notices yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateNoticeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Notice'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return _buildNoticeItem(notice);
          },
        );
      },
    );
  }

  Widget _buildNoticeItem(NoticeModel notice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _getStatusIcon(notice.status),
        title: Text(notice.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${notice.category} • ${_formatDate(notice.createdAt)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            if (notice.status == NoticeStatus.pending) {
              items.add(const PopupMenuItem(value: 'approve', child: Text('Approve')));
            }
            items.addAll([
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ]);
            return items;
          },
          onSelected: (value) {
            if (value == 'approve') {
              _approveNotice(notice);
            } else if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateNoticeScreen(notice: notice),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(notice);
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoticeDetailScreen(notice: notice),
            ),
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.approved:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 16,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        );
      case NoticeStatus.pending:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          radius: 16,
          child: Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
        );
      case NoticeStatus.rejected:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          radius: 16,
          child: Icon(Icons.close, color: Colors.white, size: 16),
        );
    }
  }

  void _showDeleteDialog(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _noticeService.deleteNotice(notice.id);
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Notice deleted')));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}