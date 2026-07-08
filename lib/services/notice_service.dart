import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../models/notification_model.dart';
import '../core/services/firebase_service.dart';
import 'notification_service.dart';
import 'cloudinary_service.dart';

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

  // Create notice with optional image upload
  Future<String> createNotice({
    required NoticeModel notice,
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    String? imageUrl;

    // Upload image to ImgBB if provided (optional - can be null)
    if ((imagePath != null && imagePath.isNotEmpty) || (imageBytes != null && imageBytes.isNotEmpty)) {
      try {
        final uploadedUrl = await ImgBBService.safeUpload(
          file: imagePath != null ? File(imagePath) : null,
          bytes: imageBytes,
          fileName: imagePath?.split('/').last,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      } catch (e) {
        // Gracefully handle upload failure - continue without image
        imageUrl = null;
      }
    }

    final finalNotice = notice.copyWith(
      imageUrl: imageUrl,
    );

    final docRef = _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(notice.id);

    await docRef.set(finalNotice.toMap());

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

  // Update notice with optional image upload
  Future<void> updateNotice({
    required NoticeModel notice,
    String? imagePath,
    List<int>? imageBytes,
    bool removeImage = false,
  }) async {
    String? currentImageUrl = notice.imageUrl;

    // Remove image if requested
    if (removeImage && currentImageUrl != null) {
      currentImageUrl = null;
    }

    // Upload new image to ImgBB if provided (optional)
    if ((imagePath != null && imagePath.isNotEmpty) || (imageBytes != null && imageBytes.isNotEmpty)) {
      try {
        final uploadedUrl = await ImgBBService.safeUpload(
          file: imagePath != null ? File(imagePath) : null,
          bytes: imageBytes,
          fileName: imagePath?.split('/').last,
        );
        if (uploadedUrl != null) {
          currentImageUrl = uploadedUrl;
        } else {
          currentImageUrl = null;
        }
      } catch (e) {
        // Gracefully handle upload failure - keep old image or remove if explicitly requested
        if (currentImageUrl == null && (imagePath != null || imageBytes != null)) {
          currentImageUrl = null;
        }
      }
    }

    final updatedNotice = notice.copyWith(
      imageUrl: currentImageUrl,
    );

    await _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(notice.id)
        .update(updatedNotice.toMap());

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

    // Files are hosted on ImgBB - no local storage to clean up
    if (notice != null && notice.hasFile) {
      // Consider implementing ImgBB deletion if needed
    }

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

  // Get total notices count across system (admin/super admin view)
  Future<int> getAllNoticesCount() async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Get total pending notices count across system (admin/super admin view)
  Future<int> getAllPendingNoticesCount() async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Get total likes count across all notices (admin/super admin view)
  Future<int> getAllLikesCount() async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .get();

    int totalLikes = 0;
    for (var doc in snapshot.docs) {
      final likesCount = doc.data()['likesCount'];
      totalLikes += likesCount is int
          ? likesCount
          : int.tryParse(likesCount?.toString() ?? '0') ?? 0;
    }
    return totalLikes;
  }

  // Get total likes count for author notices
  Future<int> getTotalLikesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(FirebaseService.noticesCollection)
        .where('authorId', isEqualTo: authorId)
        .get();

    int totalLikes = 0;
    for (var doc in snapshot.docs) {
      final likesCount = doc.data()['likesCount'];
      totalLikes += likesCount is int
          ? likesCount
          : int.tryParse(likesCount?.toString() ?? '0') ?? 0;
    }
    return totalLikes;
  }

  // Get total feedback count
  Future<int> getTotalFeedbackCount() async {
    final snapshot = await _firestore.collection('feedback').count().get();
    return snapshot.count ?? 0;
  }

  // Get total students count (registered + anonymous sessions)
  Future<int> getTotalStudentsCount() async {
    final studentsSnapshot = await _firestore
        .collection(FirebaseService.usersCollection)
        .where('role', isEqualTo: 'student')
        .count()
        .get();

    final sessionsSnapshot = await _firestore
        .collection('student_sessions')
        .count()
        .get();

    return (studentsSnapshot.count ?? 0) + (sessionsSnapshot.count ?? 0);
  }

  // Get total users count from users collection
  Future<int> getAllUsersCount() async {
    final snapshot = await _firestore
        .collection(FirebaseService.usersCollection)
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
      final currentLikesRaw = data['likesCount'];
      final currentLikes = currentLikesRaw is int
          ? currentLikesRaw
          : int.tryParse(currentLikesRaw?.toString() ?? '0') ?? 0;

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
