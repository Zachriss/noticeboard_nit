import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
  final List<TapGestureRecognizer> _linkRecognizers = [];

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

  Future<void> _shareNotice() async {
    final notice = widget.notice;
    final buffer = StringBuffer();
    buffer.writeln('${notice.title}\n');
    buffer.writeln('${notice.description}\n');
    buffer.writeln('Category: ${notice.category}');
    buffer.writeln('Date: ${notice.formattedDate}');
    if (notice.authorName.isNotEmpty) {
      buffer.writeln('Posted by: ${notice.authorName}');
    }
    if (notice.hasFile && notice.imageUrl != null) {
      buffer.writeln('\nAttachment: ${notice.imageUrl}');
    }
    buffer.writeln('\nShared from NIT NoticeBoard');

    try {
      await Share.share(buffer.toString(), subject: notice.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share notice: $e')),
        );
      }
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  static final _urlPattern = RegExp(
    r'(https?://[^\s]+)',
    caseSensitive: false,
  );

  Widget _buildLinkableDescription() {
    final text = widget.notice.description;
    final matches = _urlPattern.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: Colors.grey[700], fontSize: 14),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        );
      }

      final url = match.group(0);
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(url);
      _linkRecognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
            fontSize: 14,
          ),
          recognizer: recognizer,
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
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
                  _buildLinkableDescription(),
                  const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Row(
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
                                if (widget.showActions)
                                  IconButton(
                                    onPressed: _shareNotice,
                                    icon: Icon(
                                      Icons.share,
                                      color: Colors.grey[600],
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Share notice',
                                  ),
                              ],
                            ),
                          ),
                        ),
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

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }
}
