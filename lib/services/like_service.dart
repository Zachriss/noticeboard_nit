import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toggle like on a notice
  Future<bool> toggleLike(String noticeId, String userId) async {
    final likeRef = _firestore
        .collection(FirebaseService.likesCollection)
        .doc('${noticeId}_$userId');

    final doc = await likeRef.get();

    if (doc.exists) {
      // Unlike
      await likeRef.delete();
      await _updateLikesCount(noticeId, false);
      return false;
    } else {
      // Like
      await likeRef.set({
        'noticeId': noticeId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      await _updateLikesCount(noticeId, true);
      return true;
    }
  }

  // Check if user liked a notice
  Future<bool> isLiked(String noticeId, String userId) async {
    final doc = await _firestore
        .collection(FirebaseService.likesCollection)
        .doc('${noticeId}_$userId')
        .get();
    return doc.exists;
  }

  // Get likes count for a notice
  Future<int> getLikesCount(String noticeId) async {
    final snapshot = await _firestore
        .collection(FirebaseService.likesCollection)
        .where('noticeId', isEqualTo: noticeId)
        .get();
    return snapshot.docs.length;
  }

  // Get users who liked a notice
  Stream<List<String>> getLikedUsers(String noticeId) {
    return _firestore
        .collection(FirebaseService.likesCollection)
        .where('noticeId', isEqualTo: noticeId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['userId'] as String).toList(),
        );
  }

  Future<void> _updateLikesCount(String noticeId, bool increment) async {
    final noticeRef = _firestore
        .collection(FirebaseService.noticesCollection)
        .doc(noticeId);

    await _firestore.runTransaction((transaction) async {
      final notice = await transaction.get(noticeRef);
      if (notice.exists) {
        final currentLikes = notice.data()?['likesCount'] ?? 0;
        transaction.update(noticeRef, {
          'likesCount': increment ? currentLikes + 1 : currentLikes - 1,
        });
      }
    });
  }
}
