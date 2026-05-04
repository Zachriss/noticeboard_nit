import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/notice_model.dart';

class NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback? onLikePressed;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool showActions;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onLikePressed,
    this.onTap,
    this.onLike,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  notice.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(notice.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          notice.category,
                          style: TextStyle(
                            color: _getCategoryColor(notice.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        notice.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onLikePressed,
                        icon: Icon(
                          notice.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: notice.isLiked ? AppTheme.secondaryColor : Colors.grey[600],
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '${notice.likesCount}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        'Posted by ${notice.authorName}',
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
      default:
        return AppTheme.primaryColor;
    }
  }
}