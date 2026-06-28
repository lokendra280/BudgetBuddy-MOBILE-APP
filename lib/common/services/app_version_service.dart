import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionService {
  static const _keyOnboarded = 'onboarded';
  static const _keySchemaVersion = 'app_schema_version';

  // Only bump when new onboarding screens are added
  static const int _currentOnboardSchema = 2;

  static Future<void> checkAndResetIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final storedSchema = prefs.getInt(_keySchemaVersion) ?? 0;
    final isOnboarded = prefs.getBool(_keyOnboarded) ?? false;

    if (isOnboarded && storedSchema < _currentOnboardSchema) {
      debugPrint('[AppVersion] Schema changed, resetting onboarding');
      await prefs.setBool(_keyOnboarded, false);
    }

    await prefs.setInt(_keySchemaVersion, _currentOnboardSchema);
  }

  static Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    await prefs.setInt(_keySchemaVersion, _currentOnboardSchema);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }
}
