import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../models/notification_model.dart';
import '../core/services/firebase_service.dart';
import 'notification_service.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get all approved notices - public for all authenticated users
  Stream<List<NoticeModel>> getAllNotices() {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get all notices for admin (all statuses)
  Stream<List<NoticeModel>> getAllNoticesForAdmin() {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get notices by category
  Stream<List<NoticeModel>> getNoticesByCategory(String category) {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .where('status', isEqualTo: 'approved')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get pending notices (for admin/super admin)
  Stream<List<NoticeModel>> getPendingNotices() {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get notices by author
  Stream<List<NoticeModel>> getNoticesByAuthor(String authorId) {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get single notice
  Future<NoticeModel?> getNotice(String noticeId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseService.noticesCollection)
          .doc(noticeId)
          .get();

      if (!doc.exists) return null;
      return NoticeModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Create notice
  Future<String> createNotice(NoticeModel notice) async {
    final docRef = _firestore
        .collection(FirebaseService.noticesCollection)
        .doc();

    final noticeWithId = notice.copyWith(id: docRef.id);
    await docRef.set(noticeWithId.toMap());

    await _notificationService.sendToRole(
      targetRole: 'superAdmin',
      title: 'New notice submitted',
      body: '${notice.title} is waiting for approval.',
      type: NotificationType.systemActivity,
      senderId: notice.authorId,
      senderRole: 'admin',
      relatedNoticeId: docRef.id,
      category: notice.category,
    );

    return docRef.id;
  }

  // Update notice
  Future<void> updateNotice(NoticeModel notice) async {
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(notice.id)
        .update(notice.toMap());

    if (notice.status == NoticeStatus.approved) {
      await _notificationService.sendToRole(
        targetRole: 'student',
        title: 'Notice updated',
        body: '${notice.title} has been updated.',
        type: NotificationType.noticeUpdated,
        senderId: notice.authorId,
        senderRole: 'admin',
        relatedNoticeId: notice.id,
        category: notice.category,
      );
    }
  }

  // Delete notice
  Future<void> deleteNotice(String noticeId) async {
    final notice = await getNotice(noticeId);
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .delete();

    if (notice != null && notice.status == NoticeStatus.approved) {
      await _notificationService.sendToRole(
        targetRole: 'student',
        title: 'Notice removed',
        body: '${notice.title} has been deleted.',
        type: NotificationType.noticeDeleted,
        senderId: notice.authorId,
        senderRole: 'admin',
        relatedNoticeId: notice.id,
        category: notice.category,
      );
    }
  }

  // Approve notice
  Future<void> approveNotice(String noticeId) async {
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .update({'status': 'approved'});

    final notice = await getNotice(noticeId);
    if (notice != null) {
      await _notificationService.sendToRole(
        targetRole: 'admin',
        userId: notice.authorId,
        title: 'Your notice has been approved',
        body: '${notice.title} is now live for students.',
        type: NotificationType.approval,
        senderId: 'system',
        senderRole: 'superAdmin',
        relatedNoticeId: notice.id,
        category: notice.category,
      );
    }
  }

  // Unapprove notice (change from approved back to pending)
  Future<void> unapproveNotice(String noticeId) async {
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .update({'status': 'pending'});
  }

  // Reject notice
  Future<void> rejectNotice(String noticeId, [String? reason]) async {
    final updateData = {'status': 'rejected'};
    if (reason != null && reason.isNotEmpty) {
      updateData['rejectionReason'] = reason;
    }
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .update(updateData);

    final notice = await getNotice(noticeId);
    if (notice != null) {
      await _notificationService.sendToRole(
        targetRole: 'admin',
        userId: notice.authorId,
        title: 'Your notice was rejected',
        body: reason != null && reason.isNotEmpty
            ? 'Reason: $reason'
            : '${notice.title} was rejected by Super Admin.',
        type: NotificationType.rejection,
        senderId: 'system',
        senderRole: 'superAdmin',
        relatedNoticeId: notice.id,
        category: notice.category,
      );
    }
  }

  // Search notices
  Stream<List<NoticeModel>> searchNotices(String query) {
    return _firestore
        .collection(FirebaseService.noticesCollection)
        .where('status', isEqualTo: 'approved')
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get total notices count by author
  Future<int> getTotalNoticesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .where('authorId', isEqualTo: authorId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Get pending notices count by author
  Future<int> getPendingNoticesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Get total likes count for author notices
  Future<int> getTotalLikesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .where('authorId', isEqualTo: authorId)
        .get();

    int totalLikes = 0;
    for (var doc in snapshot.docs) {
      totalLikes += (doc.data()['likesCount'] ?? 0) as int;
    }
    return totalLikes;
  }

  // Get total feedback count
  Future<int> getTotalFeedbackCount() async {
    final snapshot = await _firestore.collection('feedback').count().get();
    return snapshot.count ?? 0;
  }

  // Get total students count
  Future<int> getTotalStudentsCount() async {
    final snapshot = await _firestore
        .collection(FirebaseService.usersCollection)
        .where('role', isEqualTo: 'student')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Simple increment like count (for backwards compatibility)
  Future<void> incrementLikeCount(String noticeId) async {
    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .update({'likesCount': FieldValue.increment(1)});
  }

  // Toggle like with unique device check (1 like per device)
  Future<void> toggleLikeWithDeviceCheck(
    String noticeId,
    String deviceId,
  ) async {
    final noticeRef = _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(noticeRef);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikes = data['likesCount'] ?? 0;

      if (likedBy.contains(deviceId)) {
        // User already liked - unlike
        likedBy.remove(deviceId);
        transaction.update(noticeRef, {
          'likedBy': likedBy,
          'likesCount': currentLikes - 1,
        });
      } else {
        // User hasn't liked yet - add like
        likedBy.add(deviceId);
        transaction.update(noticeRef, {
          'likedBy': likedBy,
          'likesCount': currentLikes + 1,
        });
      }
    });
  }

  // Check if device already liked this notice
  Future<bool> hasDeviceLiked(String noticeId, String deviceId) async {
    final doc = await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId)
        .get();

    if (!doc.exists) return false;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    return likedBy.contains(deviceId);
  }
}
