import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Android notification details (reused) ──────────────────────────────────
  static const _androidDetails = AndroidNotificationDetails(
    'daily_reminder', // channel id
    'Daily Reminder', // channel name
    channelDescription: 'Reminds you to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
    // FIX: use '@drawable/ic_notification' — a flat monochrome drawable
    // in android/app/src/main/res/drawable/ic_notification.xml
    //
    // '@mipmap/ic_launcher' is an ADAPTIVE launcher icon (has foreground +
    // background layers). Android rejects it as a notification icon because:
    //   1. Adaptive icons cannot be used as notification icons
    //   2. Mipmap is for launcher icons; drawables are for notifications
    // This caused: PlatformException(invalid_icon, ...)
    icon: '@drawable/ic_notification',
    color: Color(0xFF6366F1), // indigo accent for the notification
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Initialise ─────────────────────────────────────────────────────────────
  static Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          // FIX: '@drawable/ic_notification' instead of '@mipmap/ic_launcher'
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false, // ask permission separately
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
    } catch (e) {
      // Don't crash the app if notifications fail to init
      debugPrint('[NotificationService] init error: $e');
    }
  }

  // ── Request permission (iOS 14+ / Android 13+) ─────────────────────────────
  static Future<bool> requestPermission() async {
    try {
      // Android 13+ (API 33) requires explicit permission
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  // ── Schedule daily reminder ────────────────────────────────────────────────
  static Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.periodicallyShow(
        id: 0,
        title: 'BudgetBuddy',
        body: "Don't forget to log today's expenses!",
        repeatInterval: RepeatInterval.daily,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[NotificationService] schedule error: $e');
    }
  }

  // ── Show immediate notification (for testing) ──────────────────────────────
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
      debugPrint('[NotificationService] show error: $e');
    }
  }

  // ── Cancel all ─────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
