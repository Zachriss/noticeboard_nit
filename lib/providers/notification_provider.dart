import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../shared_preferences/local_storage.dart';

enum NotificationStatusFilter { all, unread, read }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  NotificationStatusFilter _filter = NotificationStatusFilter.all;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String? _userId;
  String? _role;

  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  NotificationStatusFilter get filter => _filter;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;

  List<NotificationModel> get filteredNotifications {
    final query = _searchQuery.trim().toLowerCase();
    return _notifications.where((notification) {
      if (_filter == NotificationStatusFilter.unread && notification.isRead) {
        return false;
      }
      if (_filter == NotificationStatusFilter.read && !notification.isRead) {
        return false;
      }
      if (query.isNotEmpty) {
        final combined = '${notification.title} ${notification.body}'
            .toLowerCase();
        if (!combined.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> initialize({
    required String userId,
    required String role,
    bool force = false,
  }) async {
    final normalizedRole = _normalizeRole(role);
    if (!force && _userId == userId && _role == normalizedRole) {
      return;
    }

    _userId = userId;
    _role = normalizedRole;
    _isLoading = true;
    _notifications = [];
    notifyListeners();

    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();

    _notificationsSubscription = _notificationService
        .getUserNotifications(userId: userId, role: normalizedRole)
        .listen(
          (list) {
            _notifications = list;
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );

    _unreadCountSubscription = _notificationService
        .unreadCountStream(userId: userId, role: normalizedRole)
        .listen((count) {
          _unreadCount = count;
          notifyListeners();
        });

    _notificationsEnabled = LocalStorage.notificationEnabled;
    _soundEnabled = LocalStorage.notificationSoundEnabled;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(NotificationStatusFilter value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_userId != null && _role != null) {
      _isLoading = true;
      notifyListeners();
      await initialize(userId: _userId!, role: _role!, force: true);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    _notifications = _notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
    notifyListeners();
  }

  Future<void> toggleReadStatus(String notificationId) async {
    final notification = _notifications.firstWhere(
      (item) => item.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    final nextReadState = !notification.isRead;
    await _notificationService.updateReadStatus(notificationId, nextReadState);
    _notifications = _notifications.map((item) {
      if (item.id == notificationId) {
        return item.copyWith(isRead: nextReadState);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (_userId == null || _role == null) return;
    await _notificationService.markAllAsRead(_userId!, _role!);
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    if (_userId == null || _role == null) return;
    await _notificationService.clearNotifications(_userId!, _role!);
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
    _notifications.removeWhere(
      (notification) => notification.id == notificationId,
    );
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await LocalStorage.setNotificationEnabled(value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await LocalStorage.setNotificationSoundEnabled(value);
    notifyListene