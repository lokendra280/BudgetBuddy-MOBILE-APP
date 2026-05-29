import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // AdMob
  static String get bannerAndroid => dotenv.env['ADMOB_ANDROID_BANNER']!;
  static String get interstitialAndroid =>
      dotenv.env['ADMOB_ANDROID_INTERSTITIAL']!;
  static String get rewardedAndroid => dotenv.env['ADMOB_ANDROID_REWARDED']!;
  static String get bannerIos => dotenv.env['ADMOB_IOS_BANNER']!;
  static String get interstitialIos => dotenv.env['ADMOB_IOS_INTERSTITIAL']!;
  static String get rewardedIos => dotenv.env['ADMOB_IOS_REWARDED']!;
}
