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
    apiKey: 'AIzaSyD2wLSbRRwV8poEHz2yf7m1p7SdK_uM1tY',
    appId: '1:590289305150:android:75d72b871b5bcaf2d99b6f',
    messagingSenderId: '590289305150',
    projectId: 'espati-5c079',
    storageBucket: 'espati-5c079.firebasestorage.app',
  );
}
