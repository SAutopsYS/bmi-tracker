// File generated structure for FlutterFire.
//
// IMPORTANT: These are PLACEHOLDER values only.
// Run `flutterfire configure` to replace them with real Firebase project values.
// Until then, Firebase init is skipped gracefully in main.dart
// (demo / offline-local mode still works with Hive).
//
// After flutterfire configure regenerates this file:
// 1. Set [kFirebaseConfigured] to true (or keep the placeholder check below).
// 2. Apply the Google Services Gradle plugin (see android/ comments).
// 3. Deploy firestore.rules to your project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Manual override after `flutterfire configure`.
///
/// Keep **false** while options still contain `YOUR_*` placeholders.
/// After FlutterFire regenerates this file with real values, set to `true`
/// (or leave false and rely on [hasRealFirebaseOptions]).
///
/// main.dart skips [Firebase.initializeApp] when [isFirebaseReady] is false.
const bool kFirebaseConfigured = false;

/// True only when Android options no longer use placeholders.
bool get hasRealFirebaseOptions =>
    DefaultFirebaseOptions.android.apiKey != 'YOUR_API_KEY' &&
    DefaultFirebaseOptions.android.projectId != 'YOUR_PROJECT_ID' &&
    !DefaultFirebaseOptions.android.apiKey.startsWith('YOUR_');

/// Effective gate used by the app: both the manual flag and non-placeholder options.
/// Local Hive auth/demo mode runs when this is false. Never treat that as cloud Firebase.
bool get isFirebaseReady => kFirebaseConfigured && hasRealFirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux. '
          'Run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:YOUR_MESSAGING_SENDER_ID:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:YOUR_MESSAGING_SENDER_ID:ios:YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.ivinnovations.bmitracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:YOUR_MESSAGING_SENDER_ID:ios:YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.ivinnovations.bmitracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:YOUR_MESSAGING_SENDER_ID:web:YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
