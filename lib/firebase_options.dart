import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBfWgNrvs5u10D1dRxTyuTuev5NmsUZOPo',
    appId: '1:396686053235:web:8beff5219cdf2cc93d3f06',
    messagingSenderId: '396686053235',
    projectId: 'nutripath-app',
    authDomain: 'nutripath-app.firebaseapp.com',
    storageBucket: 'nutripath-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfWgNrvs5u10D1dRxTyuTuev5NmsUZOPo',
    appId: '1:396686053235:android:8beff5219cdf2cc93d3f06',
    messagingSenderId: '396686053235',
    projectId: 'nutripath-app',
    storageBucket: 'nutripath-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfWgNrvs5u10D1dRxTyuTuev5NmsUZOPo',
    appId: '1:396686053235:ios:8beff5219cdf2cc93d3f06',
    messagingSenderId: '396686053235',
    projectId: 'nutripath-app',
    storageBucket: 'nutripath-app.firebasestorage.app',
  );
}
