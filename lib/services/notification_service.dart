import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../core/services/firebase_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

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

    await _localNotificationsPlugin.initialize(settings: initSettings);

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
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
    } catch (_) {
      // Permissions may fail on unsupported platforms. Continue with Firestore streaming.
    }

    _isInitialized = true;
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
              .where((notification) =>
                  notification.userId.isEmpty || notification.userId == userId)
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
        .where('userId', whereIn: [userId, ''])
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> clearNotifications(String userId, String role) async {
    final normalizedRole = _normalizeRole(role);
    final snapshot = await _firestore
        .collection(FirebaseService.notificationsCollection)
        .where('targetRole', whereIn: [normalizedRole, 'all'])
        .where('userId', whereIn: [userId, ''])
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
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
        .where('userId', whereIn: [userId, ''])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<String?> getFcmToken() async {
    return _messaging.getToken();
  }

  String _normalizeRole(String role) {
    if 