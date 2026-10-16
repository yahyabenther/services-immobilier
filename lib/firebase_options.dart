// Firebase options, read from `.env` (see .env.example) instead of being
// hard-coded. Regenerating with `flutterfire configure` overwrites this file:
// copy the new values into `.env` and restore this version.
//
// Note: Firebase client keys are identifiers, not secrets. Access is protected
// by Firestore / Storage security rules and (optionally) App Check.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/env.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: Env.firebaseWebApiKey,
        appId: Env.firebaseWebAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        authDomain: Env.firebaseAuthDomain,
        storageBucket: Env.firebaseStorageBucket,
        measurementId: Env.firebaseWebMeasurementId,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: Env.firebaseAndroidApiKey,
        appId: Env.firebaseAndroidAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        storageBucket: Env.firebaseStorageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: Env.firebaseIosApiKey,
        appId: Env.firebaseIosAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        storageBucket: Env.firebaseStorageBucket,
        iosClientId: Env.firebaseIosClientId,
        iosBundleId: Env.firebaseIosBundleId,
      );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: Env.firebaseWebApiKey,
        appId: Env.firebaseWindowsAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        authDomain: Env.firebaseAuthDomain,
        storageBucket: Env.firebaseStorageBucket,
        measurementId: Env.firebaseWindowsMeasurementId,
      );
}
