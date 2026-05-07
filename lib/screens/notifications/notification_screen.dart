import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/notification_badge.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<NotificationProvider>().setSearchQuery(
        _searchController.text,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final user = await _authService.getUserData(currentUser.uid);
    if (!mounted || user == null) return;

    await context.read<NotificationProvider>().initialize(
          userId: user.id,
          role: user.role.name,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all as read',
            onPressed: () =>
                context.read<NotificationProvider>().markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<NotificationProvider>().refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchField(provider)),
                      const SizedBox(width: 12),
                      NotificationBadge(
                        count: provider.unreadCount,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(provider),
                  const SizedBox(height: 16),
                  Expanded(child: _buildNotificationList(provider)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(NotificationProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search notifications',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildFilterChips(NotificationProvider provider) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: NotificationStatusFilter.values.map((filter) {
        final label = filter == NotificationStatusFilter.all
            ? 'All'
            : filter == NotificationStatusFilter.unread
            ? 'Unread'
            : 'Read';
        return ChoiceChip(
          label: Text(label),
          selected: provider.filter == filter,
          selectedColor: AppTheme.primaryColor.withOpacity(0.12),
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            color: provider.filter == filter
                ? AppTheme.primaryColor
                : AppTheme.textSecondary,
          ),
          onSelected: (_) => provider.setFilter(filter),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationList(NotificationProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    final notifications = provider.filteredNotifications;
    if (notifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications yet',
        subtitle: 'Notifications will appear here as soon as you receive them.',
      );
    }

    final grouped = _groupNotifications(notifications);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...entry.value.map((notification) {
            return NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(context, notification),
              onToggleRead: () => provider.toggleReadStatus(notification.id),
              onDelete: () => provider.deleteNotification(notification.id),
            );
          }).toList(),
        ];
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 18, width: 180, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: double.infinity,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: double.infinity,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> notifications,
  ) {
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final older = <NotificationModel>[];
    final now = DateTime.now();

    for (final notification in notifications) {
      final created = notification.createdAt;
      final difference = now.difference(created);
      if (difference.inDays == 0 && created.day == now.day) {
        today.add(notification);
      } else if (difference.inDays == 1 || created.day == now.day - 1) {
        yesterday.add(notification);
      } else {
        older.add(notification);
      }
    }

    final groups = <String, List<NotificationModel>>{};
    if (today.isNotEmpty) groups['Today'] = today;
    if (yesterday.isNotEmpty) groups['Yesterday'] = yesterday;
    if (older.isNotEmpty) groups['Older'] = older;
    return groups;
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    final provider = context.read<NotificationProvider>();
    provider.markAsRead(notification.id);

    if (notification.relatedNoticeId != null &&
        notification.relatedNoticeId!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.noticeDetails,
        arguments: notification.relatedNoticeId,
      );
      return;
    }

    if (notification.type == NotificationType.feedback) {
      Navigator.pushNamed(context, AppRoutes.feedback);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opened: ${notification.title}')));
  }

  void _confirmClearAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications