import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore_lib;
import 'package:firebase_storage/firebase_storage.dart' as storage_lib;
import '../../config/firebase_options.dart';

class FirebaseService {
  static firebase_core.FirebaseApp? _app;
  static firebase_auth.FirebaseAuth? _auth;
  static firestore_lib.FirebaseFirestore? _firestore;
  static storage_lib.FirebaseStorage? _storage;

  // Firebase must be initialized before accessing this getter
  static firebase_core.FirebaseApp get app {
    assert(_app != null, 'Firebase has not been initialized. Call Firebase.initializeApp() first in main.dart');
    return _app!;
  }

  static Future<void> initialize() async {
    _app ??= await firebase_core.Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static firebase_auth.FirebaseAuth get auth {
    _auth ??= firebase_auth.FirebaseAuth.instance;
    return _auth!;
  }

  static firestore_lib.FirebaseFirestore get firestore {
    _firestore ??= firestore_lib.FirebaseFirestore.instance;
    return _firestore!;
  }

  static storage_lib.FirebaseStorage get storage {
    _storage ??= storage_lib.FirebaseStorage.instance;
    return _storage!;
  }

  // Collection names
  static const String usersCollection = 'users';
  static const String noticesCollection = 'notices';
  static const String likesCollection = 'likes';
  static const String feedbackCollection = 'feedback';
  static const String faqsCollection = 'faqs';
  static const String notificationsCollection = 'notifications';
}
