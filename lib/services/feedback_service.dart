import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';
import '../core/services/firebase_service.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all feedback
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _firestore
        .collection(FirebaseService.feedbackCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get feedback by notice
  Stream<List<FeedbackModel>> getFeedbackByNotice(String noticeId) {
    return _firestore
        .collection(FirebaseService.feedbackCollection)
        .where('noticeId', isEqualTo: noticeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get feedback by user
  Stream<List<FeedbackModel>> getFeedbackByUser(String userId) {
    return _firestore
        .collection(FirebaseService.feedbackCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Create feedback
  Future<String> createFeedback(FeedbackModel feedback) async {
    final docRef = _firestore
        .collection(FirebaseService.feedbackCollection)
        .doc();

    await docRef.set(feedback.copyWith(id: docRef.id).toMap());
    return docRef.id;
  }

  // Resolve feedback
  Future<void> resolveFeedback(String feedbackId) async {
    await _firestore
        .collection(FirebaseService.feedbackCollection)
        .doc(feedbackId)
        .update({'isResolved': true});
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    await _firestore
        .collection(FirebaseService.feedbackCollection)
        .doc(feedbackId)
        .delete();
  }
}
