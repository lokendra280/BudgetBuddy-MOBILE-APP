import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;
  static const _dailyDetails = AndroidNotificationDetails(
    'daily_reminder',
    'Daily Reminder',
    channelDescription: 'Reminds you to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    color: Color(0xFF6366F1),
  );
  static const _billDetails = AndroidNotificationDetails(
    'bill_reminders',
    'Bill Reminders',
    channelDescription: 'Upcoming bill and EMI payment reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    color: Color(0xFFF59E0B),
    // Payload key used for deep-link routing on tap
  );

  static const _dailyNotifDetails = NotificationDetails(
    android: _dailyDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  static const _billNotifDetails = NotificationDetails(
    android: _billDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
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
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        // ── POINT 4: Notification tap handler ─────────────────────────────
        // Called when user taps a notification while app is in foreground OR
        // when app is launched from background via notification tap.
        onDidReceiveNotificationResponse: _onNotifTap,
        // Called when app is completely terminated and started via notification
        onDidReceiveBackgroundNotificationResponse: _onBgNotifTap,
      );

      // ── Also handle app launched from terminated state via notification ───
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        _routeByPayload(payload);
      }
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  // ── Tap routing ───────────────────────────────────────────────────────────
  static void _onNotifTap(NotificationResponse response) {
    _routeByPayload(response.payload);
  }

  // Must be top-level or static for background handler
  @pragma('vm:entry-point')
  static void _onBgNotifTap(NotificationResponse response) {
    _routeByPayload(response.payload);
  }

  static void _routeByPayload(String? payload) {
    if (payload == null) return;
    final nav = navigatorKey?.currentState;
    if (nav == null) {
      // App not ready yet — store and handle after navigation is ready
      debugPrint('[NotificationService] Nav not ready, payload: $payload');
      return;
    }
    if (payload.startsWith('screen:bills')) {
      // POINT 4: Tapping a bill reminder notification navigates to BillReminderScreen
      // Import added dynamically to avoid circular imports
      nav.pushNamed('/bills');
    } else if (payload.startsWith('screen:home')) {
      nav.pushNamedAndRemoveUntil('/home', (_) => false);
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

  static NotificationDetails get billNotifDetails => _billNotifDetails;
  static String get billPayload => 'screen:bills';

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
