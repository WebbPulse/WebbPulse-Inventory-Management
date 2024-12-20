// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCfuCeuVvzNACjrdAcU9Du2alTChRPOwyE',
    appId: '1:1096617861007:web:5d45f0a0d485927b9a75fa',
    messagingSenderId: '1096617861007',
    projectId: 'webbpulse-inventory-management',
    authDomain: 'webbpulse-inventory-management.firebaseapp.com',
    storageBucket: 'webbpulse-inventory-management.appspot.com',
    measurementId: 'G-PXLKDFZPE6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_p2XpMAoJJqiTM3PVUFKPKbITun6-XCI',
    appId: '1:1096617861007:android:e2ec1a741fb648169a75fa',
    messagingSenderId: '1096617861007',
    projectId: 'webbpulse-inventory-management',
    storageBucket: 'webbpulse-inventory-management.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkI9tUc19_jKU2ldIyxrPocUNiq0meBIk',
    appId: '1:1096617861007:ios:50c7a1ceaf0158b69a75fa',
    messagingSenderId: '1096617861007',
    projectId: 'webbpulse-inventory-management',
    storageBucket: 'webbpulse-inventory-management.appspot.com',
    androidClientId: '1096617861007-1recvc2ffj1l9c2rnq46ficqjofl8oej.apps.googleusercontent.com',
    iosClientId: '1096617861007-ftj0jm8nd2qro77q0v9blc49bbel52en.apps.googleusercontent.com',
    iosBundleId: 'com.webbpulse.inventory.ios',
  );

}