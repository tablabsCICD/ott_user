import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:ott/app/flavor/app_flavor.dart';

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
        return _isTvFlavor ? androidTv : android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static bool get _isTvFlavor =>
      const String.fromEnvironment('FLAVOR').trim().toLowerCase() == 'tv' ||
      FlavorConfig.current.isTv;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoRIntuHNkS2CuYZsoCjWmEMN4lYcg_Ug',
    appId: '1:244052932353:android:ec31ccf2f925bac8f6cd00',
    messagingSenderId: '244052932353',
    projectId: 'fimlytell',
    storageBucket: 'fimlytell.firebasestorage.app',
  );

  // Replace with the Firebase console values for Android package
  // com.filmytell.ott.tv after registering the TV app. Until then this keeps
  // the TV flavor on the same Firebase project as the existing Android app.
  static const FirebaseOptions androidTv = FirebaseOptions(
    apiKey: 'AIzaSyCoRIntuHNkS2CuYZsoCjWmEMN4lYcg_Ug',
    appId: '1:244052932353:android:ec31ccf2f925bac8f6cd00',
    messagingSenderId: '244052932353',
    projectId: 'fimlytell',
    storageBucket: 'fimlytell.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXj3ySHGWSkyox8MEqVsGas_hEeOG4-38',
    appId: '1:573981988871:ios:6de664bc7f6355642072a2',
    messagingSenderId: '573981988871',
    projectId: 'fimlytell',
    storageBucket: 'netflix-ott-1198d.firebasestorage.app',
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
