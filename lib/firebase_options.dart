import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration resolved per platform.
///
/// The web config was provided previously. The Android config matches the
/// values from `android/app/google-services.json` so FCM works on Android.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBiODdjD59Hk6k0xhg8dAHrKUf1xq9yex8',
    appId: '1:995545536560:web:66913cb37ca9b28f24f5f5',
    messagingSenderId: '995545536560',
    projectId: 'nit-notice-board',
    authDomain: 'nit-notice-board.firebaseapp.com',
    storageBucket: 'nit-notice-board.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNUW82sD7Nj2SK_Oxxti102BtBzObhlyw',
    appId: '1:995545536560:android:2689fcae03e8161f24f5f5',
    messagingSenderId: '995545536560',
    projectId: 'nit-notice-board',
    storageBucket: 'nit-notice-board.firebasestorage.app',
  );

  /// Returns the [FirebaseOptions] for the current platform.
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) return android;
    return web;
  }
}