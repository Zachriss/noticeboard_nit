import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../services/student_auth_service.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentAuthService _studentAuth = StudentAuthService();

  /// Returns the authenticated student UID.
  /// Attempts to sign in anonymously if no user is authenticated.
  /// Throws if authentication fails entirely.
  Future<String> _getStudentUid() async {
    try {
      final user = await _studentAuth.signInAnonymously();
      return user.uid;
    } catch (e) {
      throw Exception(
        'You must be signed in to like notices. Authentication failed: $e',
      );
    }
  }

  Future<String> _likeDocumentId(String noticeId) async {
    final uid = await _getStudentUid();
    return '${noticeId}_$uid';
  }

  Future<bool> isLiked(String noticeId) async {
    try {
      final docId = await _likeDocumentId(noticeId);
      final likeRef = _firestore
          .collection(FirebaseService.likesCollection)
          .doc(docId);

      final doc = await likeRef.get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check like status: $e');
    }
  }

  /// Streams the like count by counting documents in the likes collection
  /// where noticeId matches. This avoids needing to update the notices document.
  Stream<int> likesCountStream(String noticeId) {
    return _firestore
        .collection(FirebaseService.likesCollection)
        .where('noticeId', isEqualTo: noticeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<bool> likeNotice(String noticeId) async {
    try {
      final uid = await _getStudentUid();
      final docId = await _likeDocumentId(noticeId);
      final likeRef = _firestore
          .collection(FirebaseService.likesCollection)
          .doc(docId);

      final doc = await likeRef.get();
      if (doc.exists) {
        return false;
      }

      await likeRef.set({
        'noticeId': noticeId,
        'studentUid': uid,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to like notice: $e');
    }
  }

  Future<bool> unlikeNotice(String noticeId) async {
    try {
      final docId = await _likeDocumentId(noticeId);
      final likeRef = _firestore
          .collection(FirebaseService.likesCollection)
          .doc(docId);

      final doc = await likeRef.get();
      if (!doc.exists) {
        return false;
      }

      await likeRef.delete();
      return true;
    } catch (e) {
      throw Exception('Failed to unlike notice: $e');
    }
  }

  Future<bool> toggleLike(String noticeId) async {
    try {
      final uid = await _getStudentUid();
      final docId = await _likeDocumentId(noticeId);
      final likeRef = _firestore
          .collection(FirebaseService.likesCollection)
          .doc(docId);

      final doc = await likeRef.get();

      if (doc.exists) {
        await likeRef.delete();
        return false;
      } else {
        await likeRef.set({
          'noticeId': noticeId,
          'studentUid': uid,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }
}