import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to .env values.
/// Throws a clear error in debug; returns empty string in release to avoid crashes.
class Env {
  Env._();

  static String _get(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      if (kDebugMode) {
        throw Exception(
          '[Env] Missing required key "$key" in .env file. '
          'Make sure it is defined and flutter_dotenv has loaded the file.',
        );
      }
      // In release, return empty string — AdMob will fail to load the ad
      // but the app will not crash.
      return '';
    }
    return value;
  }

  // ── AdMob — Android ──────────────────────────────────────────────────────
  static String get bannerAndroid => _get('ADMOB_ANDROID_BANNER');
  static String get interstitialAndroid => _get('ADMOB_ANDROID_INTERSTITIAL');
  static String get rewardedAndroid => _get('ADMOB_ANDROID_REWARDED');

  // ── AdMob — iOS ──────────────────────────────────────────────────────────
  static String get bannerIos => _get('ADMOB_IOS_BANNER');
  static String get interstitialIos => _get('ADMOB_IOS_INTERSTITIAL');
  static String get rewardedIos => _get('ADMOB_IOS_REWARDED');
}
