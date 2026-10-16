import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Every per-environment value lives in the `.env` file (git-ignored), never in
/// source code. Load it once in `main()` before anything reads [Env].
///
/// Copy `.env.example` to `.env` and fill it in.
class Env {
  const Env._();

  static String _get(String key) => (dotenv.maybeGet(key) ?? '').trim();

  /// A key is "set" when it is present and not a `YOUR_...` placeholder.
  static bool _isSet(String v) => v.isNotEmpty && !v.startsWith('YOUR_');

  // ---- Cloudinary (unsigned preset: NEVER put the API secret here) ----------
  static String get cloudinaryCloudName => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryUploadPreset => _get('CLOUDINARY_UPLOAD_PRESET');
  static bool get cloudinaryConfigured => _isSet(cloudinaryCloudName) && _isSet(cloudinaryUploadPreset);

  // ---- Map tiles (Module 06) --------------------------------------------------
  /// Empty -> the public OpenStreetMap server (fine for dev / demos). For a real
  /// launch point this at a commercial tile provider (MapTiler, Mapbox, Stadia...).
  static String get mapTileUrl {
    final v = _get('MAP_TILE_URL');
    return v.isEmpty ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png' : v;
  }

  /// Identifies the app to the tile server (OSM policy): use your applicationId.
  static String get mapUserAgentPackage {
    final v = _get('MAP_USER_AGENT_PACKAGE');
    return _isSet(v) ? v : 'com.example.teamApp';
  }

  // ---- Firebase (public client identifiers, see firebase_options.dart) ------
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID');
  static String get firebaseMessagingSenderId => _get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseStorageBucket => _get('FIREBASE_STORAGE_BUCKET');
  static String get firebaseAuthDomain => _get('FIREBASE_AUTH_DOMAIN');

  static String get firebaseWebApiKey => _get('FIREBASE_WEB_API_KEY');
  static String get firebaseWebAppId => _get('FIREBASE_WEB_APP_ID');
  static String get firebaseWebMeasurementId => _get('FIREBASE_WEB_MEASUREMENT_ID');

  static String get firebaseAndroidApiKey => _get('FIREBASE_ANDROID_API_KEY');
  static String get firebaseAndroidAppId => _get('FIREBASE_ANDROID_APP_ID');

  static String get firebaseIosApiKey => _get('FIREBASE_IOS_API_KEY');
  static String get firebaseIosAppId => _get('FIREBASE_IOS_APP_ID');
  static String get firebaseIosClientId => _get('FIREBASE_IOS_CLIENT_ID');
  static String get firebaseIosBundleId => _get('FIREBASE_IOS_BUNDLE_ID');

  static String get firebaseWindowsAppId => _get('FIREBASE_WINDOWS_APP_ID');
  static String get firebaseWindowsMeasurementId => _get('FIREBASE_WINDOWS_MEASUREMENT_ID');
}
