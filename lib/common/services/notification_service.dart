import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'daily_reminder',
    'Daily Reminder',
    channelDescription: 'Reminds you to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF6366F1),
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Init + request permission in one call ─────────────
  static Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true, // ← was false before
            requestBadgePermission: true, // ← was false before
            requestSoundPermission: true, // ← was false before
          ),
        ),
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[NotificationService] tapped: ${details.payload}');
        },
      );

      // Request Android 13+ permission
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();

      debugPrint('[NotificationService] init complete');
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  // ── Schedule daily reminder ───────────────────────────
  static Future<void> scheduleDailyReminder() async {
    try {
      // await _plugin.cancel(0);
      await _plugin.periodicallyShow(
        id: 0,
        title: 'BudgetBuddy',
        body: "Don't forget to log today's expenses!",
        repeatInterval: RepeatInterval.daily,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('[NotificationService] daily reminder scheduled');
    } catch (e) {
      debugPrint('[NotificationService] schedule error: $e');
    }
  }
/// over expenses
/// 
  // ── Show immediate (for testing) ──────────────────────
  static Future<void> showNow({
    String title = 'BudgetBuddy',
    String body = 'Your finances are waiting!',
  }) async {
    try {
      await _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: _notifDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNow error: $e');
    }
  }

  // ── Cancel all ────────────────────────────────────────
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
