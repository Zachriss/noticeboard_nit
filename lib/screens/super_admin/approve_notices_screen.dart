import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notice_service.dart';
import '../../models/notice_model.dart';

enum NoticeFilter { all, pending, approved, rejected }

class ApproveNoticesScreen extends StatefulWidget {
  final bool useScaffold;
  const ApproveNoticesScreen({super.key, this.useScaffold = true});

  @override
  State<ApproveNoticesScreen> createState() => _ApproveNoticesScreenState();
}

class _ApproveNoticesScreenState extends State<ApproveNoticesScreen> {
  final NoticeService _noticeService = NoticeService();
  NoticeFilter _currentFilter = NoticeFilter.all;

  @override
  Widget build(BuildContext context) {
    if (!widget.useScaffold) return _buildContent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notices'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip(NoticeFilter.all, 'All'),
              const SizedBox(width: 8),
              _buildFilterChip(NoticeFilter.pending, 'Pending'),
              const SizedBox(width: 8),
              _buildFilterChip(NoticeFilter.approved, 'Approved'),
              const SizedBox(width: 8),
              _buildFilterChip(NoticeFilter.rejected, 'Rejected'),
            ],
          ),
        ),

        // Notices List
        Expanded(
          child: StreamBuilder<List<NoticeModel>>(
            stream: _noticeService.getAllNoticesForAdmin(),
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
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final allNotices = snapshot.data ?? [];
              final filteredNotices = _filterNotices(allNotices);

              if (filteredNotices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentFilter == NoticeFilter.all
                            ? Icons.announcement
                            : Icons.filter_list,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentFilter == NoticeFilter.all
                            ? 'No notices found'
                            : 'No ${_currentFilter.name} notices',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentFilter == NoticeFilter.all
                            ? 'Notices will appear here when created'
                            : 'Try changing the filter to see other notices',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Force refresh by rebuilding the stream
                  setState(() {});
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredNotices.length,
                  itemBuilder: (context, index) {
                    final notice = filteredNotices[index];
                    return _buildNoticeCard(notice);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(NoticeFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _currentFilter = filter);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<NoticeModel> _filterNotices(List<NoticeModel> notices) {
    switch (_currentFilter) {
      case NoticeFilter.pending:
        return notices
            .where((notice) => notice.status == NoticeStatus.pending)
            .toList();
      case NoticeFilter.approved:
        return notices
            .where((notice) => notice.status == NoticeStatus.approved)
            .toList();
      case NoticeFilter.rejected:
        return notices
            .where((notice) => notice.status == NoticeStatus.rejected)
            .toList();
      case NoticeFilter.all:
      default:
        return notices;
    }
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    return Dismissible(
      key: Key(notice.id),
      direction: notice.status == NoticeStatus.pending
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd &&
            notice.status == NoticeStatus.pending) {
          // Swipe right - Approve
          await _approveNotice(notice);
          return false; // Don't dismiss the card
        } else {
          // Swipe left - Delete
          return await _confirmDelete(notice);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category chip and Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notice.category,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusBadge(notice.status),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                notice.description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Author and Date
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.authorName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.formattedDate,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),

              // Status-specific content
              if (notice.status == NoticeStatus.approved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Published successfully',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (notice.status == NoticeStatus.rejected &&
                  notice.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rejection Reason',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notice.rejectionReason!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(notice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isStartToEnd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isStartToEnd ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isStartToEnd ? Icons.check : Icons.delete,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            isStartToEnd ? 'Approve' : 'Delete',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(NoticeStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case NoticeStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Approved';
        break;
      case NoticeStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      case NoticeStatus.pending:
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(NoticeModel notice) {
    switch (notice.status) {
      case NoticeStatus.pending:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveNotice(notice),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectNotice(notice),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteNotice(notice),
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );

      case NoticeStatus.approved:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _unapproveNotice(notice),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Unapprove'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteNotice(notice),
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );

      case NoticeStatus.rejected:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editNotice(notice),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _reapproveNotice(notice),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Re-approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteNotice(notice),
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Future<void> _approveNotice(NoticeModel notice) async {
    try {
      await _noticeService.approveNotice(notice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Notice approved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to approve notice'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _unapproveNotice(NoticeModel notice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.undo, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Unapprove Notice'),
          ],
        ),
        content: const Text(
          'Are you sure you want to unapprove this notice? It will be moved back to pending status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unapprove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _noticeService.unapproveNotice(notice.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.undo, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Notice unapproved successfully'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to unapprove notice'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _rejectNotice(NoticeModel notice) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Reject Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (result == true) {
      try {
        await _noticeService.rejectNotice(
          notice.id,
          reasonController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Notice rejected'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to reject notice'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _reapproveNotice(NoticeModel notice) async {
    try {
      await _noticeService.approveNotice(notice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Notice re-approved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to re-approve notice'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _editNotice(NoticeModel notice) async {
    final titleController = TextEditingController(text: notice.title);
    final descriptionController = TextEditingController(
      text: notice.description,
    );
    String selectedCategory = notice.category;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Edit Notice'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                  DropdownMenuItem(value: 'Exams', child: Text('Exams')),
                  DropdownMenuItem(value: 'Events', child: Text('Events')),
                  DropdownMenuItem(value: 'Library', child: Text('Library')),
                  DropdownMenuItem(
                    value: 'Placement',
                    child: Text('Placement'),
                  ),
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (value) => selectedCategory = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  descriptionController.text.trim().isNotEmpty &&
                  selectedCategory.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (result == true) {
      try {
        final updatedNotice = notice.copyWith(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
        );
        await _noticeService.updateNotice(updatedNotice);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.save, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Notice updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to update notice'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete(NoticeModel notice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Notice'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this notice? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return result ?? false;
  }

  Future<void> _deleteNotice(NoticeModel notice) async {
    final confirmed = await _confirmDelete(notice);
    if (!confirmed) return;

    try {
      await _noticeService.deleteNotice(notice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Notice deleted successfully'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to delete notice'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
