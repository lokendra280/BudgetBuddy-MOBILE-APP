import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── ID ranges (no collisions) ──────────────────────────────────────────────
  // Daily reminder  : 0
  // Bill reminders  : hashCode % 100_000          (1 – 99_999)
  // EMI reminders   : hashCode % 100_000 + 100_000 (100_000 – 199_999)
  // Goal achieved   : hashCode % 100_000 + 200_000 (200_000 – 299_999)

  // ── Android channel definitions ────────────────────────────────────────────
  static const _dailyChannel = AndroidNotificationDetails(
    'daily_reminder',
    'Daily Reminder',
    channelDescription: 'Reminds you to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF6366F1),
  );

  static const _billChannel = AndroidNotificationDetails(
    'bill_reminders',
    'Bill Reminders',
    channelDescription: 'Upcoming bill and EMI payment reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFFF59E0B),
  );

  static const _emiChannel = AndroidNotificationDetails(
    'emi_reminders',
    'EMI & Loan Reminders',
    channelDescription: 'Monthly EMI and loan due date reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF10B981),
  );

  static const _goalChannel = AndroidNotificationDetails(
    'goal_achievements',
    'Goal Achievements',
    channelDescription: 'Notifications when savings goals are completed',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF10B981),
  );

  // ── iOS details (shared) ───────────────────────────────────────────────────
  static const _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // ── Notification details bundles ───────────────────────────────────────────
  static const _dailyDetails = NotificationDetails(
    android: _dailyChannel,
    iOS: _ios,
  );
  static const _billDetails = NotificationDetails(
    android: _billChannel,
    iOS: _ios,
  );
  static const _emiDetails = NotificationDetails(
    android: _emiChannel,
    iOS: _ios,
  );
  static const _goalDetails = NotificationDetails(
    android: _goalChannel,
    iOS: _ios,
  );

  // ── Payload constants ──────────────────────────────────────────────────────
  static const billPayload = 'screen:bills';
  static const emiPayload = 'screen:emi';
  static const goalPayload = 'screen:goals';
  static const homePayload = 'screen:home';

  // ── Init ───────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.localizedName!.name));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotifTap,
        onDidReceiveBackgroundNotificationResponse: _onBgNotifTap,
      );

      await requestPermission();

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _routeByPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  // ── Tap routing ────────────────────────────────────────────────────────────
  static void _onNotifTap(NotificationResponse r) => _routeByPayload(r.payload);

  @pragma('vm:entry-point')
  static void _onBgNotifTap(NotificationResponse r) =>
      _routeByPayload(r.payload);

  static void _routeByPayload(String? payload) {
    if (payload == null) return;
    final nav = navigatorKey?.currentState;
    if (nav == null) return;
    if (payload.startsWith('screen:bills'))
      nav.pushNamed('/bills');
    else if (payload.startsWith('screen:emi'))
      nav.pushNamed('/emi');
    else if (payload.startsWith('screen:goals'))
      nav.pushNamed('/goals');
    else if (payload.startsWith('screen:home'))
      nav.pushNamedAndRemoveUntil('/home', (_) => false);
  }

  // ── Daily reminder ─────────────────────────────────────────────────────────
  static Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.periodicallyShow(
        id: 0,
        title: 'BudgetBuddy',
        body: "Don't forget to log today's expenses!",
        repeatInterval: RepeatInterval.daily,
        notificationDetails: _dailyDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: homePayload,
      );
      debugPrint('[NotificationService] Daily reminder scheduled');
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyReminder error: $e');
    }
  }

  // ── Bill reminder ──────────────────────────────────────────────────────────
  /// Schedules a notification [bill.remindDaysBefore] days before due date.
  /// For recurring bills, rolls to next month if this month is already past.
  static Future<void> scheduleBillReminder(BillReminder bill) async {
    try {
      final due = bill.computedDueDate;
      final notifAt = due.subtract(Duration(days: bill.remindDaysBefore));
      var scheduled = _toTZ(notifAt, hour: 9);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduled.isBefore(now)) {
        if (!bill.isRecurring) return;
        final nextDue = DateTime(
          due.year,
          due.month + 1,
          bill.dayOfMonth.clamp(1, 28),
        );
        final nextNotif = nextDue.subtract(
          Duration(days: bill.remindDaysBefore),
        );
        scheduled = _toTZ(nextNotif, hour: 9);
        if (scheduled.isBefore(now)) return;
      }

      await _plugin.zonedSchedule(
        id: _billNotifId(bill.id),
        title:
            '${bill.emoji} ${bill.title} due in ${bill.remindDaysBefore} days',
        body:
            '${bill.category} · ${bill.currency} ${bill.amount.toStringAsFixed(0)}',
        scheduledDate: scheduled,
        notificationDetails: _billDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: bill.isRecurring
            ? DateTimeComponents.dayOfMonthAndTime
            : null,
        payload: billPayload,
      );
      debugPrint('[NotificationService] Bill "${bill.title}" → $scheduled');
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

  static Future<void> rescheduleAllBillReminders(
    List<BillReminder> reminders,
  ) async {
    for (final bill in reminders) await scheduleBillReminder(bill);
    debugPrint(
      '[NotificationService] Rescheduled ${reminders.length} bill reminders',
    );
  }

  // ── EMI / Loan reminder ────────────────────────────────────────────────────
  /// Schedules a notification [loan.remindDaysBefore] days before the EMI due date.
  /// Recurring monthly: uses [DateTimeComponents.dayOfMonthAndTime] so it
  /// fires automatically every month without re-scheduling.
  static Future<void> scheduleEmiReminder(EmiLoan loan) async {
    try {
      final due = loan.nextDueDate;
      final notifAt = due.subtract(Duration(days: loan.remindDaysBefore));
      var scheduled = _toTZ(notifAt, hour: 9);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduled.isBefore(now)) {
        // Roll to next month
        final nextDue = DateTime(
          due.year,
          due.month + 1,
          loan.dayOfMonth.clamp(1, 28),
        );
        final nextNotif = nextDue.subtract(
          Duration(days: loan.remindDaysBefore),
        );
        scheduled = _toTZ(nextNotif, hour: 9);
        if (scheduled.isBefore(now)) return;
      }

      final amtFmt = NumberFormat('#,##0', 'en_US').format(loan.emiAmount);

      await _plugin.zonedSchedule(
        id: _emiNotifId(loan.id),
        title: '${loan.emoji} EMI Due Soon — ${loan.title}',
        body:
            '${loan.lenderName} · ${loan.currency} $amtFmt due ${DateFormat('MMM d').format(due)}',
        scheduledDate: scheduled,
        notificationDetails: _emiDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Recurring monthly — fires on the same day each month automatically
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: emiPayload,
      );
      debugPrint('[NotificationService] EMI "${loan.title}" → $scheduled');
    } catch (e) {
      debugPrint('[NotificationService] scheduleEmiReminder error: $e');
    }
  }

  static Future<void> cancelEmiReminder(String loanId) async {
    try {
      await _plugin.cancel(id: _emiNotifId(loanId));
    } catch (e) {
      debugPrint('[NotificationService] cancelEmiReminder error: $e');
    }
  }

  static Future<void> rescheduleAllEmiReminders(List<EmiLoan> loans) async {
    for (final loan in loans) {
      if (loan.remindersEnabled && loan.isActive)
        await scheduleEmiReminder(loan);
    }
    debugPrint(
      '[NotificationService] Rescheduled ${loans.length} EMI reminders',
    );
  }

  // ── Goal achievement ───────────────────────────────────────────────────────
  static Future<void> showGoalCompletedNotification({
    required String goalName,
  }) async {
    try {
      await _plugin.show(
        id: goalName.hashCode.abs() % 100000 + 200000,
        title: '🎉 Goal Achieved!',
        body: 'Congratulations! You reached your "$goalName" savings goal.',
        notificationDetails: _goalDetails,
        payload: goalPayload,
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] showGoalCompletedNotification error: $e',
      );
    }
  }

  // ── Debug ──────────────────────────────────────────────────────────────────
  static Future<void> showNow({
    String title = 'BudgetBuddy',
    String body = 'Your finances are waiting!',
  }) async {
    try {
      await _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: _dailyDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNow error: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  /// Convert a [DateTime] to a [tz.TZDateTime] at the given [hour]:00 local.
  static tz.TZDateTime _toTZ(DateTime d, {int hour = 9}) =>
      tz.TZDateTime(tz.local, d.year, d.month, d.day, hour);

  /// Stable int notification ID for bills (range 1 – 99_999).
  static int _billNotifId(String id) => id.hashCode.abs() % 100000;

  /// Stable int notification ID for EMIs (range 100_000 – 199_999).
  /// Offset by 100_000 guarantees zero collision with bill IDs.
  static int _emiNotifId(String id) => id.hashCode.abs() % 100000 + 100000;
}
