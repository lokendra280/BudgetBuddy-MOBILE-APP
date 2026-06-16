import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── Channel definitions ───────────────────────────────────────────────────
  static const _dailyDetails = AndroidNotificationDetails(
    'daily_reminder',
    'Daily Reminder',
    channelDescription: 'Reminds you to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF6366F1),
  );

  static const _billDetails = AndroidNotificationDetails(
    'bill_reminders',
    'Bill Reminders',
    channelDescription: 'Upcoming bill and EMI payment reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFFF59E0B),
  );

  static const _goalDetails = AndroidNotificationDetails(
    'goal_achievements',
    'Goal Achievements',
    channelDescription: 'Notifications when savings goals are completed',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF10B981),
  );

  // ── iOS details (shared) ──────────────────────────────────────────────────
  static const _iosDefault = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // ── Notification details bundles ──────────────────────────────────────────
  static const _dailyNotifDetails = NotificationDetails(
    android: _dailyDetails,
    iOS: _iosDefault,
  );

  static const _billNotifDetails = NotificationDetails(
    android: _billDetails,
    iOS: _iosDefault,
  );

  static const _goalNotifDetails = NotificationDetails(
    android: _goalDetails,
    iOS: _iosDefault,
  );

  // ── Payloads ──────────────────────────────────────────────────────────────
  static const billPayload = 'screen:bills';
  static const goalPayload = 'screen:goals';
  static const homePayload = 'screen:home';

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String localTimezone = timezoneInfo.localizedName!.name;
      tz.setLocalLocation(tz.getLocation(localTimezone));

      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: const DarwinInitializationSettings(
            // Request permissions explicitly via requestPermission()
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotifTap,
        onDidReceiveBackgroundNotificationResponse: _onBgNotifTap,
      );

      await requestPermission();

      // Handle app launched from terminated state via notification
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _routeByPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  static Future<void> requestPermission() async {
    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Android — exact alarm permission (required for bill reminders)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  // ── Tap routing ───────────────────────────────────────────────────────────
  static void _onNotifTap(NotificationResponse response) =>
      _routeByPayload(response.payload);

  @pragma('vm:entry-point')
  static void _onBgNotifTap(NotificationResponse response) =>
      _routeByPayload(response.payload);

  static void _routeByPayload(String? payload) {
    if (payload == null) return;
    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    if (payload.startsWith('screen:bills')) {
      nav.pushNamed('/bills');
    } else if (payload.startsWith('screen:goals')) {
      nav.pushNamed('/goals');
    } else if (payload.startsWith('screen:home')) {
      nav.pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  // ── Daily reminder ────────────────────────────────────────────────────────
  static Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.periodicallyShow(
        id: 0,
        title: 'BudgetBuddy',
        body: "Don't forget to log today's expenses!",
        repeatInterval: RepeatInterval.daily,
        notificationDetails: _dailyNotifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: homePayload,
      );
      debugPrint('[NotificationService] Daily reminder scheduled');
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyReminder error: $e');
    }
  }

  // ── Bill reminder ─────────────────────────────────────────────────────────
  /// Schedules a notification [bill.remindDaysBefore] days before the due date.
  /// Handles past-due dates by rolling to the next occurrence for recurring bills.
  static Future<void> scheduleBillReminder(BillReminder bill) async {
    try {
      final due = bill.computedDueDate;
      final notifAt = due.subtract(Duration(days: bill.remindDaysBefore));
      var scheduledDate = tz.TZDateTime.from(
        DateTime(notifAt.year, notifAt.month, notifAt.day, 9, 0),
        tz.local,
      );

      final now = tz.TZDateTime.now(tz.local);

      // If the scheduled time is already past, roll to next month for recurring
      if (scheduledDate.isBefore(now)) {
        if (!bill.isRecurring) return;

        final nextDue = DateTime(
          due.year,
          due.month + 1,
          bill.dayOfMonth.clamp(1, 28),
        );
        final nextNotif = nextDue.subtract(
          Duration(days: bill.remindDaysBefore),
        );
        scheduledDate = tz.TZDateTime.from(
          DateTime(nextNotif.year, nextNotif.month, nextNotif.day, 9, 0),
          tz.local,
        );

        if (scheduledDate.isBefore(now)) return; // still in the past — skip
      }

      await _plugin.zonedSchedule(
        id: _billNotifId(bill.id),
        title:
            '${bill.emoji} ${bill.title} due in ${bill.remindDaysBefore} days',
        body:
            '${bill.category} · ${bill.currency} ${bill.amount.toStringAsFixed(0)}',
        scheduledDate: scheduledDate,
        notificationDetails: _billNotifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: bill.isRecurring
            ? DateTimeComponents.dayOfMonthAndTime
            : null,
        payload: billPayload,
      );

      debugPrint(
        '[NotificationService] Bill "${bill.title}" scheduled at $scheduledDate',
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleBillReminder error: $e');
    }
  }

  static Future<void> cancelBillReminder(String billId) async {
    try {
      await _plugin.cancel(id: _billNotifId(billId));
    } catch (e) {
      debugPrint('[NotificationService] cancelBillReminder error: $e');
    }
  }

  /// Re-schedules all active bill reminders (call on app start / device restart).
  static Future<void> rescheduleAllBillReminders(
    List<BillReminder> reminders,
  ) async {
    for (final bill in reminders) {
      await scheduleBillReminder(bill);
    }
    debugPrint(
      '[NotificationService] Rescheduled ${reminders.length} bill reminders',
    );
  }

  // Stable int ID derived from string UUID
  static int _billNotifId(String id) => id.hashCode.abs() % 100000;

  // ── Goal achievement ──────────────────────────────────────────────────────
  static Future<void> showGoalCompletedNotification({
    required String goalName,
  }) async {
    try {
      await _plugin.show(
        id: goalName.hashCode.abs() % 100000,
        title: '🎉 Goal Achieved!',
        body:
            'Congratulations! You have reached your "$goalName" savings goal.',
        notificationDetails: _goalNotifDetails,
        payload: goalPayload,
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] showGoalCompletedNotification error: $e',
      );
    }
  }

  // ── Debug / testing ───────────────────────────────────────────────────────
  static Future<void> showNow({
    String title = 'BudgetBuddy',
    String body = 'Your finances are waiting!',
  }) async {
    try {
      await _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: _dailyNotifDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNow error: $e');
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
