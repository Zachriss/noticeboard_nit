import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import 'notification_service.dart';

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

  // Register admin without replacing the active super admin session.
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    firebase_core.FirebaseApp? secondaryApp;

    try {
      secondaryApp = await firebase_core.Firebase.initializeApp(
        name: 'adminCreation',
        options: firebase_core.Firebase.app().options,
      );
    } on firebase_core.FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        secondaryApp = firebase_core.Firebase.app('adminCreation');
      } else {
        rethrow;
      }
    }

    try {
      final secondaryAuth = firebase_auth.FirebaseAuth.instanceFor(
        app: secondaryApp,
      );
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;

      if (uid == null) {
        throw 'Failed to create admin account';
      }

      await _firestore.collection(FirebaseService.usersCollection).doc(uid).set({
        'name': name,
        'email': email,
        'department': department,
        'role': 'admin',
        'year': null,
        'profileImageUrl': null,
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      await secondaryApp.delete();
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

      // Persist the FCM token now that the admin/super admin is signed in.
      await _saveFcmToken(credential.user!.uid);

      return await getUserData(credential.user!.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Persists the current FCM token under users/{uid}/fcmToken when present.
  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await NotificationService().getFcmToken();
      if (token == null || token.isEmpty) return;
      await _firestore
          .collection(FirebaseService.usersCollection)
          .doc(uid)
          .set(<String, dynamic>{'fcmToken': token}, SetOptions(merge: true));
    } catch (_) {
      // Token persistence is best-effort.
    }
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

  // Approve user (alias for approveAdmin)
  Future<void> approveUser(String userId) async {
    await approveAdmin(userId);
  }

  // Register user (wrapper for registerWithEmail)
  Future<UserModel?> registerUser({
    required UserModel user,
    required String password,
  }) async {
    return await registerWithEmail(
      email: user.email,
      password: password,
      name: user.name,
      role: user.role,
      department: user.department,
      year: user.year,
    );
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestore
        .collection(FirebaseService.usersCollection)
        .where('role', isEqualTo: role.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<UserModel>> getAdmins() {
    return getUsersByRole(UserRole.admin);
  }

  Future<void> updateAdmin({
    required String userId,
    required String name,
    required String email,
    required String department,
  }) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .update({'name': name, 'email': email, 'department': department});
  }

  // Update user role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .update({'role': newRole.name});
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
