import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Generated-style Firebase options.
///
/// Regenerate with `flutterfire configure` when your Firebase project changes.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoRIntuHNkS2CuYZsoCjWmEMN4lYcg_Ug',
    appId: '1:244052932353:android:ec31ccf2f925bac8f6cd00',
    messagingSenderId: '244052932353',
    projectId: 'fimlytell',
    storageBucket: 'fimlytell.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD7KqwMowOdGg8qaU7VmBN8Rxgh6TceLgk',
    appId: '1:244052932353:ios:61fc3e0efa66d5a9f6cd00',
    messagingSenderId: '244052932353',
    projectId: 'fimlytell',
    storageBucket: 'fimlytell.firebasestorage.app',
    iosBundleId: 'com.filmytell.ott',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXj3ySHGWSkyox8MEqVsGas_hEeOG4-38',
    appId: '1:573981988871:web:6de664bc7f6355642072a2',
    messagingSenderId: '573981988871',
    projectId: 'fimlytell',
    storageBucket: 'netflix-ott-1198d.firebasestorage.app',
    authDomain: 'fimlytell.firebaseapp.com',
  );
}
