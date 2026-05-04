import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Register new user
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? department,
    String? year,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        department: department,
        year: year,
        createdAt: DateTime.now(),
        isApproved: role == UserRole.student,
      );

      await _firestore
          .collection(FirebaseService.usersCollection)
          .doc(user.id)
          .set(user.toMap());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      return await getUserData(credential.user!.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseService.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(user.id)
        .update(user.toMap());
  }

  // Get all users (for super admin)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(FirebaseService.usersCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Approve admin
  Future<void> approveAdmin(String userId) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .update({'isApproved': true});
  }

  // Update user disabled status
  Future<void> updateUserStatus(String userId, bool isDisabled) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .update({'isDisabled': isDisabled});
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .delete();
  }

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
