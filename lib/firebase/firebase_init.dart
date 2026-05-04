import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/firebase_options.dart';

class FirebaseInit {
  static FirebaseApp? _app;
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseAuth get auth => _auth!;
  static FirebaseStorage get storage => _storage!;
  static bool get isInitialized => _app != null;

  static Future<void> initialize() async {
    if (_app != null) return;
    
    _app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _storage = FirebaseStorage.instance;

    // Firestore settings for production
    _firestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static Future<void> dispose() async {
    await _app?.delete();
    _app = null;
    _firestore = null;
    _auth = null;
    _storage = null;
  }
}