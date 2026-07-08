import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notice_model.dart';
import '../services/like_service.dart';
import '../services/notice_service.dart';
import '../services/student_auth_service.dart';
import '../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for managing user's favourite/liked notices.
/// Features:
/// - Real-time Firestore stream updates
/// - Automatic sorting (newest first)
/// - Duplicate prevention handled by LikeService
/// - Pull-to-refresh support
class FavouriteProvider extends ChangeNotifier {
  final LikeService _likeService = LikeService();
  final NoticeService _noticeService = NoticeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NoticeModel> _likedNotices = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _likesSubscription;

  List<NoticeModel> get likedNotices => List.unmodifiable(_likedNotices);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get favouriteCount => _likedNotices.length;

  /// Initialize provider and set up real-time listener for favourites.
  /// Call this once when provider is created.
  void initialize() {
    _setupRealtimeListener();
  }

  /// Set up Firestore stream to listen for real-time favourite updates.
  /// Automatically updates the list when likes collection changes.
  Future<void> _setupRealtimeListener() async {
    // Set loading state immediately
    _isLoading = true;
    notifyListeners();

    try {
      final studentAuth = StudentAuthService();
      // Sign in anonymously first to get a real authenticated UID
      final user = await studentAuth.signInAnonymously();
      final studentUid = user.uid;

      // Cancel any existing subscription to avoid duplicates
      _likesSubscription?.cancel();

      // Listen to likes collection filtered by studentUid
      _likesSubscription = _firestore
          .collection(FirebaseService.likesCollection)
          .where('studentUid', isEqualTo: studentUid)
          .snapshots()
          .listen(
            (snapshot) async {
              final likedNotices = <NoticeModel>[];

              for (final doc in snapshot.docs) {
                final noticeId = doc.data()['noticeId'] as String?;
                if (noticeId != null) {
                  final notice = await _noticeService.getNotice(noticeId);
                  if (notice != null) {
                    likedNotices.add(notice);
                  }
                }
              }

              // Sort by createdAt descending (newest first)
              likedNotices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              _likedNotices = likedNotices;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually refresh favourites (useful for pull-to-refresh).
  Future<void> loadLikedNotices() async {
    _setLoading(true);
    try {
      // Force a one-time fetch to get current state
      final studentAuth = StudentAuthService();
      final studentUid = studentAuth.currentUid;
      final snapshot = await _firestore
          .collection(FirebaseService.likesCollection)
          .where('studentUid', isEqualTo: studentUid)
          .get();

      final likedNotices = <NoticeModel>[];

      for (final doc in snapshot.docs) {
        final noticeId = doc.data()['noticeId'] as String?;
        if (noticeId != null) {
          final notice = await _noticeService.getNotice(noticeId);
          if (notice != null) {
            likedNotices.add(notice);
          }
        }
      }

      // Sort by createdAt descending (newest first)
      likedNotices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _likedNotices = likedNotices;
      _errorMessage = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Toggle like status for a notice.
  /// Returns true if liked, false if unliked.
  Future<bool> toggleLike(String noticeId) async {
    try {
      final isLiked = await _likeService.isLiked(noticeId);

      if (isLiked) {
        await _likeService.unlikeNotice(noticeId);
        _likedNotices.removeWhere((notice) => notice.id == noticeId);
      } else {
        final notice = await _noticeService.getNotice(noticeId);
        if (notice != null) {
          await _likeService.likeNotice(noticeId);
          // Insert at the beginning (newest first)
          _likedNotices.insert(0, notice);
        }
      }

      notifyListeners();
      return !isLiked;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove a notice from favourites directly.
  Future<bool> removeFromFavourites(String noticeId) async {
    try {
      await _likeService.unlikeNotice(noticeId);
      _likedNotices.removeWhere((notice) => notice.id == noticeId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if a notice is already liked.
  Future<bool> isNoticeLiked(String noticeId) async {
    return _likeService.isLiked(noticeId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _likedNotices = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clean up resources when provider is disposed.
  @override
  void dispose() {
    _likesSubscription?.cancel();
    super.dispose();
  }
}