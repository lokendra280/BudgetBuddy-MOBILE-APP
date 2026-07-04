import 'package:hive/hive.dart';

/// Decides whether the "How was your day?" prompt should show. Backed by
/// the same plain box as FeedbackService.
class FeedbackPromptService {
  static Box get _box => Hive.box('feedback_box');

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static bool get _skippedForever =>
      _box.get('skippedForever', defaultValue: false) as bool;

  static bool get shouldShowToday {
    if (_skippedForever) return false;
    final lastShown = _box.get('lastShownDate') as String?;
    return lastShown != _todayKey;
  }

  /// Call this the moment the prompt is actually shown (not just eligible),
  /// so it doesn't pop up again later the same day even if skipped.
  static void markShownToday() => _box.put('lastShownDate', _todayKey);

  static void skipForever() => _box.put('skippedForever', true);

  /// Lets a settings screen re-enable it if the user changes their mind.
  static void resetSkip() => _box.put('skippedForever', false);
}
