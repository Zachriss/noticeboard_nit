import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notice_model.dart';
import '../../services/like_service.dart';
import '../../services/auth_service.dart';

class NoticeDetailScreen extends StatefulWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final LikeService _likeService = LikeService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      final liked = await _likeService.isLiked(widget.notice.id, user.uid);
      if (mounted) setState(() => _isLiked = liked);
    }
  }

  Future<void> _toggleLike() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to like')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _likeService.toggleLike(widget.notice.id, user.uid);
      setState(() => _isLiked = result);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: widget.notice.imageUrl != null ? 250 : 0,
            pinned: true,
            flexibleSpace: widget.notice.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      widget.notice.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : null,
            title: Text(
              widget.notice.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Date
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
                          widget.notice.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(widget.notice.createdAt),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.notice.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.notice.authorName,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    widget.notice.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Like Button
                  Center(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: _isLoading ? null : _toggleLike,
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey,
                            size: 40,
                          ),
                        ),
                        Text(
                          '${widget.notice.likesCount} likes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tags
                  if (widget.notice.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.notice.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
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
