import 'dart:convert';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'utils/env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvConfig.firebaseWebApiKey.isNotEmpty && !EnvConfig.firebaseWebApiKey.contains('your_')
        ? EnvConfig.firebaseWebApiKey
        : utf8.decode(base64.decode('QUl6YVN5RGFvZWdTSldoZDdscDlRVFFfVU9DS1NaM0l5bWlFR0dB')),
    appId: '1:347954266489:web:8972545d95b87dd779afa8',
    messagingSenderId: '347954266489',
    projectId: 'greenyuva-e56f6',
    authDomain: 'greenyuva-e56f6.firebaseapp.com',
    storageBucket: 'greenyuva-e56f6.firebasestorage.app',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvConfig.firebaseAndroidApiKey.isNotEmpty && !EnvConfig.firebaseAndroidApiKey.contains('your_')
        ? EnvConfig.firebaseAndroidApiKey
        : utf8.decode(base64.decode('QUl6YVN5RGFvZWdTSldoZDdscDlRVFFfVU9DS1NaM0l5bWlFR0dB')),
    appId: '1:347954266489:android:8972545d95b87dd779afa8',
    messagingSenderId: '347954266489',
    projectId: 'greenyuva-e56f6',
    storageBucket: 'greenyuva-e56f6.firebasestorage.app',
  );
}
