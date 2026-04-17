import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionService {
  static const _keyOnboarded = 'onboarded';
  static const _keyOnboardVersion = 'onboard_build_number';
  static const _keySchemaVersion = 'app_schema_version';

  // Bump this when you want ALL existing users to re-see onboarding
  // (e.g. when you add a new onboarding screen like currency picker)
  static const int _currentOnboardSchema = 2;

  /// Call this BEFORE reading the 'onboarded' flag.
  /// Resets onboarding if the app version or schema changed.
  static Future<void> checkAndResetIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current app build number
    String buildNumber = '1';
    try {
      final info = await PackageInfo.fromPlatform();
      buildNumber = info.buildNumber;
      debugPrint('[AppVersion] current build=$buildNumber');
    } catch (e) {
      debugPrint('[AppVersion] could not get package info: $e');
    }

    final storedBuild = prefs.getString(_keyOnboardVersion) ?? '';
    final storedSchema = prefs.getInt(_keySchemaVersion) ?? 0;
    final isOnboarded = prefs.getBool(_keyOnboarded) ?? false;

    debugPrint(
      '[AppVersion] stored build=$storedBuild schema=$storedSchema onboarded=$isOnboarded',
    );

    bool needsReset = false;

    // Reset if: build number changed (new install or update)
    if (isOnboarded && storedBuild != buildNumber) {
      debugPrint(
        '[AppVersion] Build changed $storedBuild → $buildNumber, resetting onboarding',
      );
      needsReset = true;
    }

    // Reset if: onboard schema version changed (new screens added)
    if (isOnboarded && storedSchema < _currentOnboardSchema) {
      debugPrint(
        '[AppVersion] Onboard schema changed $storedSchema → $_currentOnboardSchema, resetting',
      );
      needsReset = true;
    }

    if (needsReset) {
      await prefs.setBool(_keyOnboarded, false);
      // Keep language + currency prefs so returning users don't lose them
      // They just re-confirm on the onboarding screens
    }

    // Always update stored version
    await prefs.setString(_keyOnboardVersion, buildNumber);
    await prefs.setInt(_keySchemaVersion, _currentOnboardSchema);
  }

  /// Mark onboarding as complete for this build.
  static Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    String buildNumber = '1';
    try {
      final info = await PackageInfo.fromPlatform();
      buildNumber = info.buildNumber;
    } catch (_) {}

    await prefs.setBool(_keyOnboarded, true);
    await prefs.setString(_keyOnboardVersion, buildNumber);
    await prefs.setInt(_keySchemaVersion, _currentOnboardSchema);
  }

  /// Check if user has completed onboarding for this build.
  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }
}
