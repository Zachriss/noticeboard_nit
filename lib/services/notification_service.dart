import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/notice_model.dart';
import '../core/services/firebase_service.dart';

/// Top-level background message handler.
/// Must be a top-level function (not a closure) and annotated so it can be
/// invoked from the native background isolate when the app is terminated
/// or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The notification has already been delivered to the system tray by FCM
  // when the app is in the background/terminated. We just keep the handler
  // alive so messages are acknowledged and any data processing can occur.
  debugPrint('Handling a background message: ${message.messageId}');
}

/// Top-level handler for local notification taps that occur while the app is
/// in the background isolate. Must be a top-level function per the
/// flutter_local_notifications plugin requirements.
@pragma('vm:entry-point')
void onLocalNotificationBackgroundResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final context = NotificationService.navigatorKey?.currentContext;
  if (context == null) return;
  NotificationService.navigateToNotice(payload);
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Global navigator key used to navigate to a notice when the user taps
  /// a notification while the app is in the background or terminated.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Static entry point used by top-level notification tap handlers to
  /// navigate to a notice using the global [navigatorKey].
  static Future<void> navigateToNotice(String noticeId) async {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseService.noticesCollection)
          .doc(noticeId)
          .get();
      if (!context.mounted) return;
      if (!snapshot.exists) return;
      final notice = NoticeModel.fromMap(snapshot.data()!, snapshot.id);
      if (!context.mounted) return;
      Navigator.of(context).pushNamed('/notice/details', arguments: notice);
    } catch (e) {
      debugPrint('navigateToNotice failed: $e');
    }
  }

  bool _isInitialized = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  Future<void> initializeNotificationSystem() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // onDidReceiveNotificationResponse handles local notification taps
    // (foreground taps) and taps on notifications that launched the app
    // from a terminated state.
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationResponse,
    );

    // Register the background message handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permission (handles denial gracefully).
    await _requestPermission();

    // Foreground messages -> show via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: notification.title ?? 'NIT Noticeboard',
          body: notification.body ?? '',
          payload: message.data['relatedNoticeId'] ?? '',
        );
      }
    });

    // When the app is opened from a background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data['relatedNoticeId']);
    });

    // When the app is opened from a terminated state via a notification tap.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data['relatedNoticeId']);
    }

    // Retrieve and persist the token, then keep it refreshed.
    await _saveTokenIfAvailable();
    _messaging.onTokenRefresh.listen((_) => _saveTokenIfAvailable());

    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      // Permission request failed or unsupported platform.
      _permissionGranted = false;
      debugPrint('FCM permission request failed: $e');
    }
  }

  /// Saves the FCM token to the current user's document.
  /// No-ops gracefully when there is no signed-in user, no token, or
  /// permission has not been granted.
  Future<void> _saveTokenIfAvailable() async {
    try {
      if (!_permissionGranted) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is missing.');
        return;
      }
      await saveTokenForCurrentUser(token);
    } catch (e) {
      // Missing/invalid token or write failure - log and continue.
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Persists the given FCM token under users/{uid}/fcmToken.
  /// Does not modify any existing fields.
  /// For anonymous students (whose identity lives in `student_sessions`),
  /// the token is also stored there best-effort so they still receive
  /// push notifications.
  Future<void> saveTokenForCurrentUser(String token) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      if (token.isEmpty) return;

      // Requirement: store under users/{uid}.
      await _firestore
          .collection(FirebaseService.usersCollection)
          .doc(uid)
          .set(<String, dynamic>{'fcmToken': token}, SetOptions(merge: true));

      // Best-effort: also store for anonymous students tracked in
      // student_sessions so the Cloud Function can reach them.
      try {
        await _firestore
            .collection('student_sessions')
            .doc(uid)
            .set(<String, dynamic>{'fcmToken': token},
                SetOptions(merge: true));
      } catch (_) {
        // student_sessions may be write-restricted; ignore.
      }
    } catch (e) {
      debugPrint('saveTokenForCurrentUser failed: $e');
    }
  }

  /// Navigate to the notice detail screen for the given notice id.
  /// Falls back to simply opening the app if navigation is not possible.
  void _handleNotificationNavigation(String? relatedNoticeId) {
    if (relatedNoticeId == null || relatedNoticeId.isEmpty) return;
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    _navigateToNotice(context, relatedNoticeId);
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    NotificationService.navigateToNotice(payload);
  }

  /// Instance helper that navigates to a notice. Delegates to the static
  /// [navigateToNotice] which uses the global [navigatorKey].
  Future<void> _navigateToNotice(
    BuildContext context,
    String noticeId,
  ) async {
    await NotificationService.navigateToNotice(noticeId);
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'noticeboard_channel',
      'Noticeboard Notifications',
      channelDescription: 'Notifications for noticeboard updates and alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  Future<String> sendNotification(NotificationModel notification) async {
    final docRef = _firestore
        .collection(FirebaseService.notificationsCollection)
        .doc();
    final notificationToSend = notification.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await docRef.set(notificationToSend.toMap());
    return docRef.id;
  }

  Future<String> sendToRole({
    required String targetRole,
    required String title,
    required String body,
    NotificationType type = NotificationType.systemActivity,
    String userId = '',
    String senderId = '',
    String senderRole = '',
    String? relatedNoticeId,
    String? category,
  }) async {
    final normalizedRole = _normalizeRole(targetRole);
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      senderId: senderId,
      senderRole: senderRole,
      relatedNoticeId: relatedNoticeId,
      targetRole: normalizedRole,
      category: category,
    );
    return sendNotification(notification);
  }

  Stream<List<NotificationModel>> getUserNotifications({
    required String userId,
    required String role,
  }) {
    final normalizedRole = _normalizeRole(role);
    return _firestore
        .collection(FirebaseService.notificationsCollection)
        .where('targetRole', whereIn: [normalizedRole, 'all'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .where(
                (notification) =>
                    notification.userId.isEmpty ||
                    notification.userId == userId,
              )
              .toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(FirebaseService.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> updateReadStatus(String notificationId, bool isRead) async {
    await _firestore
        .collection(FirebaseService.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': isRead});
  }

  Future<void> markAllAsRead(String userId, String role) async {
    final normalizedRole = _normalizeRole(role);
    final snapshot = await _firestore
        .collection(FirebaseService.notificationsCollection)
        .where('targetRole', whereIn: [normalizedRole, 'all'])
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final notification = NotificationModel.fromMap(doc.data(), doc.id);
      if (notification.userId.isEmpty || notification.userId == userId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> clearNotifications(String userId, String role) async {
    final normalizedRole = _normalizeRole(role);
    final snapshot = await _firestore
        .collection(FirebaseService.notificationsCollection)
        .where('targetRole', whereIn: [normalizedRole, 'all'])
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final notification = NotificationModel.fromMap(doc.data(), doc.id);
      if (notification.userId.isEmpty || notification.userId == userId) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(FirebaseService.notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  Stream<int> unreadCountStream({
    required String userId,
    required String role,
  }) {
    final normalizedRole = _normalizeRole(role);
    return _firestore
        .collection(FirebaseService.notificationsCollection)
        .where('targetRole', whereIn: [normalizedRole, 'all'])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .where(
                (notification) =>
                    notification.userId.isEmpty ||
                    notification.userId == userId,
              )
              .length,
        );
  }

  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('getFcmToken failed: $e');
      return null;
    }
  }

  String _normalizeRole(String role) {
    if (role == 'super_admin') return 'superAdmin';
    return role;
  }
}