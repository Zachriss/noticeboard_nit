import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/notice_model.dart';
import '../services/like_service.dart';
import '../services/image_cache_service.dart';

class NoticeCard extends StatefulWidget {
  final NoticeModel notice;
  final VoidCallback? onTap;
  final bool showActions;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
    this.showActions = true,
  });

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  final LikeService _likeService = LikeService();
  bool _isLiked = false;
  bool _isLoadingLike = false;

  Future<void> _loadLikeStatus() async {
    try {
      final liked = await _likeService.isLiked(widget.notice.id);
      if (!mounted) return;
      setState(() {
        _isLiked = liked;
      });
    } catch (_) {
      // No-op: if like state fails to load, keep default value.
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;

    setState(() {
      _isLoadingLike = true;
    });

    try {
      final liked = await _likeService.toggleLike(widget.notice.id);
      if (!mounted) return;
      setState(() {
        _isLiked = liked;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update like: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingLike = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.notice.hasFile)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: ImageCacheService().buildCachedImage(
                  imageUrl: widget.notice.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            widget.notice.category,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.notice.category,
                          style: TextStyle(
                            color: _getCategoryColor(widget.notice.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.notice.formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.notice.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.notice.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.showActions)
                        IconButton(
                          onPressed: _isLoadingLike ? null : _toggleLike,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey<bool>(_isLiked),
                              color: _isLiked ? Colors.red : Colors.grey[600],
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      StreamBuilder<int>(
                        stream: _likeService.likesCountStream(widget.notice.id),
                        initialData: widget.notice.likesCount,
                        builder: (context, snapshot) {
                          final likesCount =
                              snapshot.data ?? widget.notice.likesCount;
                          return Text(
                            '$likesCount',
                            style: TextStyle(color: Colors.grey[600]),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Posted by ${widget.notice.authorName}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Colors.blue;
      case 'exams':
        return AppTheme.secondaryColor;
      case 'events':
        return Colors.green;
      case 'scams/fraud':
        return Colors.deepOrange;
      default:
        return AppTheme.primaryColor;
    }
  }
}
