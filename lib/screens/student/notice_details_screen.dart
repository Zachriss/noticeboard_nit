import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notice_model.dart';
import '../../services/like_service.dart';
import '../../services/image_cache_service.dart';

class NoticeDetailScreen extends StatefulWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final LikeService _likeService = LikeService();
  bool _isLiked = false;
  bool _isLoading = false;
  final List<TapGestureRecognizer> _linkRecognizers = [];
  static final _urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
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

  Widget _buildLinkableDescription(String text) {
    final matches = _urlPattern.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
      );
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
        ));
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(url);
      _linkRecognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          fontSize: 16,
          height: 1.6,
        ),
        recognizer: recognizer,
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final liked = await _likeService.isLiked(widget.notice.id);
      if (!mounted) return;
      setState(() => _isLiked = liked);
    } catch (_) {
      // Ignore like state load errors.
    }
  }

  Future<void> _toggleLike() async {
    setState(() => _isLoading = true);
    try {
      final result = await _likeService.toggleLike(widget.notice.id);
      if (!mounted) return;
      setState(() => _isLiked = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update like: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showFullScreenImage() {
    if (widget.notice.imageUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(imageUrl: widget.notice.imageUrl!),
      ),
    );
  }

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.notice.hasFile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
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
                  _buildLinkableDescription(widget.notice.description),
                  const SizedBox(height: 32),

                  // Full-width image below description
                  if (hasImage)
                    GestureDetector(
                      onTap: _showFullScreenImage,
                      child: ImageCacheService().buildCachedImage(
                        imageUrl: widget.notice.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        placeholder: const SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: SizedBox(
                          height: 180,
                          child: Center(
                            child: Icon(Icons.broken_image,
                                size: 64, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),

                  // Like Button
                  Center(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: _isLoading ? null : _toggleLike,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey<bool>(_isLiked),
                              color: _isLiked ? Colors.red : Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                        StreamBuilder<int>(
                          stream: _likeService.likesCountStream(
                            widget.notice.id,
                          ),
                          initialData: widget.notice.likesCount,
                          builder: (context, snapshot) {
                            final likesCount =
                                snapshot.data ?? widget.notice.likesCount;
                            return Text(
                              '$likesCount likes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
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

// Fullscreen image viewer
class _FullScreenImage extends StatefulWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  State<_FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<_FullScreenImage> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final dir = await getExternalStorageDirectory();
      final fileName = 'notice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${dir?.path ?? '/tmp'}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _downloadImage,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download image',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: ImageCacheService().buildCachedImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              placeholder: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white70),
                ),
              ),
              errorWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
