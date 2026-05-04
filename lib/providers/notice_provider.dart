import 'package:flutter/foundation.dart';
import '../models/notice_model.dart';
import '../services/notice_service.dart';
import '../services/like_service.dart';

class NoticeProvider extends ChangeNotifier {
  final NoticeService _noticeService = NoticeService();
  final LikeService _likeService = LikeService();

  List<NoticeModel> _notices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NoticeModel> get notices => List.unmodifiable(_notices);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<NoticeModel>> get noticesStream => _noticeService.getNoticesStream();

  Future<void> loadNotices() async {
    _setLoading(true);
    try {
      _notices = _noticeService.getAllNotices();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> createNotice(NoticeModel notice) async {
    _setLoading(true);
    try {
      await _noticeService.createNotice(notice);
      await loadNotices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNotice(NoticeModel notice) async {
    _setLoading(true);
    try {
      await _noticeService.updateNotice(notice);
      await loadNotices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    _setLoading(true);
    try {
      await _noticeService.deleteNotice(noticeId);
      _notices.removeWhere((notice) => notice.id == noticeId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleLike(String noticeId) async {
    try {
      // Allow liking without login - anonymous likes
      await _noticeService.incrementLikeCount(noticeId);
      
      // Refresh notices list
      await loadNotices();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}