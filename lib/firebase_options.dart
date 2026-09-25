// firebase_options.dart
// IMPORTANT: Fill in your apiKey from:
// Firebase Console → Project Settings → General → Your apps → Web app → SDK setup
// Do NOT commit this file to public GitHub with real keys.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ← Paste your apiKey value here (the long AIzaSy... string)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB31WCELrFD0jy9jHqRcLKKjnK8D4SwIkA',
    appId: '1:1070542599755:web:9d871d2b6f3befb6ea7fce',
    messagingSenderId: '1070542599755',
    projectId: 'greentrack-4bcab',
    authDomain: 'greentrack-4bcab.firebaseapp.com',
    storageBucket: 'greentrack-4bcab.firebasestorage.app',
    measurementId: 'G-WCDHCFHJGZ',
  );

  // For Android — pulled from android/app/google-services.json (the file
  // the google-services Gradle plugin already reads at build time; these
  // values must match it exactly). This previously had the *web* app's
  // appId/apiKey pasted in here by mistake — a mismatched appId is a
  // classic cause of Firebase silently failing to initialize on Android,
  // which shows up as exactly a blank/black screen with no error (release
  // builds don't show Flutter's red error screen).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiGybFAV4lUozMmFSj3BCo1WDLyKuuoUc',
    appId: '1:1070542599755:android:2a3ad399f72d847bea7fce',
    messagingSenderId: '1070542599755',
    projectId: 'greentrack-4bcab',
    storageBucket: 'greentrack-4bcab.firebasestorage.app',
  );

  // For iOS — get from GoogleService-Info.plist in Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB31WCELrFD0jy9jHqRcLKKjnK8D4SwIkA',
    appId: '1:1070542599755:web:9d871d2b6f3befb6ea7fce',
    messagingSenderId: '1070542599755',
    projectId: 'greentrack-4bcab',
    storageBucket: 'greentrack-4bcab.firebasestorage.app',
    iosBundleId: 'com.example.greentrack',
  );
}
