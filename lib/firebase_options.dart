import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated from: android/app/google-services.json
/// Project: espati-5c079
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run FlutterFire CLI to generate web options.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Run FlutterFire CLI to generate iOS options.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpukwlU_jUHB-28p0kFIvInbgjqzDpJ3w',
    appId: '1:688505701744:android:fe6af5cd58554db3e7bbb5',
    messagingSenderId: '688505701744',
    projectId: 'espati-b722f',
    storageBucket: 'espati-b722f.firebasestorage.app',
  );
}
