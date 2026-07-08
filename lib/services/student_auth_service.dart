import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles Firebase Anonymous Authentication for students only.
/// Admin/Super Admin authentication remains unchanged.
class StudentAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current Firebase user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Returns the current student's UID.
  /// Throws if no user is signed in.
  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Student not authenticated. Call signInAnonymously() first.');
    }
    return user.uid;
  }

  /// Signs the student in anonymously if not already signed in.
  /// Returns the authenticated User.
  Future<User> signInAnonymously() async {
    // If already signed in with anonymous, return existing user
    if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
      return _auth.currentUser!;
    }
    final credential = await _auth.signInAnonymously();
    final user = credential.user!;

    // Record anonymous session for admin dashboard counting
    try {
      await _firestore
          .collection('student_sessions')
          .doc(user.uid)
          .set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {
      // Ignore session tracking errors
    }

    return user;
  }

  /// Signs out the current student.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}