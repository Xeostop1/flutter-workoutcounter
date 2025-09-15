// lib/firebase_options.dart
// 수동 생성 템플릿: 각 플랫폼의 값을 채워 넣으세요.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return macos; // 필요 없으면 ios와 동일하게 둬도 됨
      case TargetPlatform.windows:
        return windows; // 필요 없으면 web과 동일하게 둬도 됨
      case TargetPlatform.linux:
        return web; // 리눅스 안 쓰면 대충 web 값으로
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6lD4QQ8eoW1swhQSlBWQ9k9Z6J1MNJ4w',
    appId: '1:295108102036:android:0212ab5ecee67a12fc7181',
    messagingSenderId: '295108102036',
    projectId: 'sparkle-fe639',
    storageBucket: 'sparkle-fe639.firebasestorage.app',
  );

  // ANDROID (패키지: com.example.counter_01)

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvJRKySusF1M1CZtAICZ1krLy3ursVF7E',
    appId: '1:295108102036:ios:ba16b0a74258bdfbfc7181',
    messagingSenderId: '295108102036',
    projectId: 'sparkle-fe639',
    storageBucket: 'sparkle-fe639.firebasestorage.app',
    iosBundleId: 'com.sparkleteamhns.counter01',
  );

  // iOS (Bundle ID: com.example.counter01)

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCvJRKySusF1M1CZtAICZ1krLy3ursVF7E',
    appId: '1:295108102036:ios:164826f83d8fdcd2fc7181',
    messagingSenderId: '295108102036',
    projectId: 'sparkle-fe639',
    storageBucket: 'sparkle-fe639.firebasestorage.app',
    iosBundleId: 'com.example.counter01',
  );

  // macOS (보통 iOS와 동일하게 써도 동작)

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1onUFsPVwdrRTudPuHvLTaue-7NtCGnk',
    appId: '1:295108102036:web:344baa678c506bc2fc7181',
    messagingSenderId: '295108102036',
    projectId: 'sparkle-fe639',
    authDomain: 'sparkle-fe639.firebaseapp.com',
    storageBucket: 'sparkle-fe639.firebasestorage.app',
    measurementId: 'G-JKDETCCNMP',
  );

  // WEB

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC1onUFsPVwdrRTudPuHvLTaue-7NtCGnk',
    appId: '1:295108102036:web:0afdaaafba75f91bfc7181',
    messagingSenderId: '295108102036',
    projectId: 'sparkle-fe639',
    authDomain: 'sparkle-fe639.firebaseapp.com',
    storageBucket: 'sparkle-fe639.firebasestorage.app',
    measurementId: 'G-N3GCQV66ZL',
  );

  // WINDOWS (콘솔에서 만든 Web/Windows 앱 설정 값 사용)
}