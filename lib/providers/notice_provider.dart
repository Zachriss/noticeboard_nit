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

  Stream<List<NoticeModel>> get noticesStream => _noticeService.getAllNotices();

  Future<void> loadNotices() async {
    _setLoading(true);
    try {
      final stream = _noticeService.getAllNotices();
      _notices = await stream.first;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> createNotice({
    required NoticeModel notice,
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    _setLoading(true);
    try {
      await _noticeService.createNotice(
        notice: notice,
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      await loadNotices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNotice({
    required NoticeModel notice,
    String? imagePath,
    List<int>? imageBytes,
    bool removeImage = false,
  }) async {
    _setLoading(true);
    try {
      await _noticeService.updateNotice(
        notice: notice,
        imagePath: imagePath,
        imageBytes: imageBytes,
        removeImage: removeImage,
      );
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

  Future<bool> toggleLike(String noticeId) async {
    try {
      final result = await _likeService.toggleLike(noticeId);
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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
