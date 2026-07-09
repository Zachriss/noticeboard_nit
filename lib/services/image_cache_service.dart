import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for caching notice images locally for offline viewing.
/// Images are cached when first viewed online and served from cache when offline.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache directory name
  static const String _cacheDirName = 'notice_images';
  
  // Maximum cache size in bytes (100MB)
  static const int _maxCacheSize = 100 * 1024 * 1024;
  
  // Maximum age of cached files (7 days)
  static const Duration _maxCacheAge = Duration(days: 7);

  /// Get the cache directory path
  Future<Directory> get _cacheDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generate a safe filename from URL using a simple hash
  String _getFileNameFromUrl(String url) {
    // Create a simple hash from the URL by summing character codes
    int hash = 0;
    for (int i = 0; i < url.length; i++) {
      hash = ((hash << 5) - hash) + url.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    // Convert to positive and create filename
    final safeHash = hash.abs().toString();
    return 'notice_$safeHash.jpg';
  }

  /// Get the full path for a cached image
  Future<String> _getCachedImagePath(String imageUrl) async {
    final cacheDir = await _cacheDirectory;
    final fileName = _getFileNameFromUrl(imageUrl);
    return '${cacheDir.path}/$fileName';
  }

  /// Check if an image is cached
  Future<bool> isCached(String imageUrl) async {
    try {
      final cachedPath = await _getCachedImagePath(imageUrl);
      final file = File(cachedPath);
      if (!await file.exists()) return false;
      
      // Check if cache is too old
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age > _maxCacheAge) {
        await file.delete();
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get cached image file
  Future<File?> getCachedImage(String imageUrl) async {
    try {
      if (!await isCached(imageUrl)) return null;
      final cachedPath = await _getCachedImagePath(imageUrl);
      final file = File(cachedPath);
      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Download and cache an image
  Future<File?> cacheImage(String imageUrl) async {
    try {
      // Check if already cached
      if (await isCached(imageUrl)) {
        return await getCachedImage(imageUrl);
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        debugPrint('Failed to download image: $imageUrl');
        return null;
      }

      // Validate it's an image
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;

      // Save to cache
      final cachedPath = await _getCachedImagePath(imageUrl);
      final file = File(cachedPath);
      await file.writeAsBytes(bytes);

      // Enforce cache size limit
      await _enforceCacheSizeLimit();

      return file;
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }

  /// Enforce cache size limit by removing oldest files
  Future<void> _enforceCacheSizeLimit() async {
    try {
      final cacheDir = await _cacheDirectory;
      final files = cacheDir.listSync().whereType<File>().toList();
      
      if (files.isEmpty) return;

      // Get total size
      int totalSize = 0;
      for (final file in files) {
        try {
          totalSize += await file.length();
        } catch (_) {}
      }

      // If over limit, remove oldest files first
      if (totalSize > _maxCacheSize) {
        // Sort by modification time (oldest first)
        files.sort((a, b) {
          try {
            return a.statSync().modified.compareTo(b.statSync().modified);
          } catch (_) {
            return 0;
          }
        });

        // Delete oldest files until under limit
        for (final file in files) {
          if (totalSize <= _maxCacheSize) break;
          try {
            final size = await file.length();
            await file.delete();
            totalSize -= size;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error enforcing cache size limit: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDirectory;
      final files = cacheDir.listSync().whereType<File>();
      int totalSize = 0;
      for (final file in files) {
        try {
          totalSize += await file.length();
        } catch (_) {}
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Pre-cache multiple images (call when online to prepare for offline)
  Future<void> preCacheImages(List<String> imageUrls) async {
    // Cache images in parallel but limit concurrency
    const maxConcurrent = 3;
    for (int i = 0; i < imageUrls.length; i += maxConcurrent) {
      final end = (i + maxConcurrent < imageUrls.length) 
          ? i + maxConcurrent 
          : imageUrls.length;
      final batch = imageUrls.sublist(i, end);
      await Future.wait(batch.map((url) => cacheImage(url)));
    }
  }

  /// Get a widget that displays image from cache or network
  /// Automatically caches image when downloaded from network
  Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<File?>(
      future: getCachedImage(imageUrl),
      builder: (context, snapshot) {
        // If cached image exists, use it
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        }

        // If error getting cached image, show error widget
        if (snapshot.hasError) {
          return errorWidget ?? const Icon(Icons.broken_image);
        }

        // Otherwise, try to load from network and cache it
        return Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // Image loaded successfully - cache it in background
              cacheImage(imageUrl);
              return child;
            }
            return placeholder ??
                Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
          },
          errorBuilder: (context, error, stackTrace) {
            // If network fails, check cache one more time
            getCachedImage(imageUrl).then((file) {
              if (file != null) {
                // Found cached version, rebuild
                // This is a simple approach - in production you might want to use a state management solution
              }
            });
            return errorWidget ?? const Icon(Icons.broken_image);
          },
        );
      },
    );
  }
}