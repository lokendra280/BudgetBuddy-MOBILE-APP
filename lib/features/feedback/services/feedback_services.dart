import 'package:budgetBuddy/features/feedback/enum/feedback_enum.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Submits feedback to Supabase. Works without a logged-in user — feedback
/// is tied to a locally-generated anonymous device id instead of an auth
/// user id, so `auth.currentUser` being null is completely fine here.
///
/// Needs an extra dependency in pubspec.yaml if not already present:
///   package_info_plus: ^8.0.0
///
/// Needs a plain (non-typed) box opened once at startup:
///   await Hive.openBox('feedback_box');
///
/// Needs a Supabase table — see feedback_table.sql for the exact schema
/// and RLS policy that allows anonymous inserts.
class FeedbackService {
  static Box get _box => Hive.box('feedback_box');
  static const _table = 'app_feedback';

  /// Stable per-install id, generated once and reused forever — lets you
  /// see "this device gave feedback 3 times" without any login.
  static String get deviceId {
    var id = _box.get('deviceId') as String?;
    if (id == null) {
      id = const Uuid().v4();
      _box.put('deviceId', id);
    }
    return id;
  }

  static Future<void> submit({
    required String name,
    required String country,
    required String message,
    required FeedbackType type,
    int? mood, // 1-5, only meaningful for dailyCheckIn
  }) async {
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      appVersion = null;
    }

    await Supabase.instance.client.from(_table).insert({
      'name': name.trim(),
      'country': country.trim(),
      'message': message.trim(),
      'feedback_type': type.value,
      'mood': mood,
      'device_id': deviceId,
      'app_version': appVersion,
    });
  }
}
