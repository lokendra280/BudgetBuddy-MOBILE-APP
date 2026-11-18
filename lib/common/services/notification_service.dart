import 'package:budgetbuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetbuddy/features/bill_reminder/models/emi_loan.dart';
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
  // Daily reminder      : 0
  // Bill reminders      : hashCode % 100_000            (0 – 99_999)
  // EMI reminders       : hashCode % 100_000 + 100_000  (100_000 – 199_999)
  // Goal achieved       : hashCode % 100_000 + 200_000  (200_000 – 299_999)
  // EMI overdue         : hashCode % 100_000 + 300_000  (300_000 – 399_999)
  // Subscription renew  : stableHash % 100_000 + 400_000 (400_000 – 499_999)  NEW
  // Tax season          : 500_000 – 500_001                                   NEW
  // Holiday budgets     : stableHash % 100_000 + 600_000 (600_000 – 699_999)  NEW
  //
  // iOS keeps at most 64 pending notifications per app. Repeating ones count
  // once each, but with many bills + EMIs + subscriptions you can hit the cap;
  // iOS silently drops the ones furthest in the future.

  static const _subscriptionBase = 400000;
  static const _taxBase = 500000;
  static const _holidayBase = 600000;

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

  // NEW
  static const _subscriptionChannel = AndroidNotificationDetails(
    'subscription_renewals',
    'Subscription Renewals',
    channelDescription:
        'Heads-up before Netflix, Spotify and other subscriptions renew',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF8B5CF6),
  );

  // NEW
  static const _taxChannel = AndroidNotificationDetails(
    'tax_season',
    'Tax Season',
    channelDescription:
        'Reminders to export your expenses before the tax deadline',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF0EA5E9),
  );

  // NEW
  static const _holidayChannel = AndroidNotificationDetails(
    'holiday_budgets',
    'Holiday Budgets',
    channelDescription:
        'Black Friday, Christmas and other holiday budget alerts',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFFEC4899),
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
  static const _subscriptionDetails = NotificationDetails(
    android: _subscriptionChannel,
    iOS: _ios,
  );
  static const _taxDetails = NotificationDetails(
    android: _taxChannel,
    iOS: _ios,
  );
  static const _holidayDetails = NotificationDetails(
    android: _holidayChannel,
    iOS: _ios,
  );

  // ── Payload constants ──────────────────────────────────────────────────────
  static const billPayload = 'screen:bills';
  static const emiPayload = 'screen:emi';
  static const goalPayload = 'screen:goals';
  static const homePayload = 'screen:home';
  static const subscriptionPayload = 'screen:subscriptions'; // NEW
  static const taxPayload = 'screen:tax'; // NEW
  static const holidayPayload = 'screen:holidays'; // NEW

  // ── Init ───────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

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

      // Permission is NOT requested here: init() runs before runApp(), and on
      // iOS (UIScene lifecycle) a system alert shown before the first frame
      // can be non-interactive and blocks startup. HomeScreen requests it
      // after the first frame instead.

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _routeByPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  /// Returns whether notifications are allowed (CHANGED: was `void`; existing
  /// `await requestPermission();` calls still work unchanged).
  static Future<bool> requestPermission() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      await android?.requestExactAlarmsPermission();
      return granted;
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
      return false;
    }
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
    if (payload.startsWith(billPayload)) {
      nav.pushNamed('/bills');
    } else if (payload.startsWith(emiPayload)) {
      nav.pushNamed('/emi');
    } else if (payload.startsWith(goalPayload)) {
      nav.pushNamed('/goals');
    } else if (payload.startsWith(subscriptionPayload)) {
      nav.pushNamed('/subscriptions'); // NEW
    } else if (payload.startsWith(taxPayload)) {
      nav.pushNamed('/tax'); // NEW
    } else if (payload.startsWith(holidayPayload)) {
      nav.pushNamed('/holidays'); // NEW
    } else if (payload.startsWith(homePayload)) {
      nav.pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  // ── Daily reminder ─────────────────────────────────────────────────────────
  static Future<void> scheduleDailyReminder() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20,
        0,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: 0,
        title: 'budgetbuddy',
        body: "Don't forget to log today's expenses!",
        scheduledDate: scheduled,
        notificationDetails: _dailyDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: homePayload,
      );
      debugPrint('[NotificationService] Daily reminder scheduled for 8 PM');
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
    for (final bill in reminders) {
      await scheduleBillReminder(bill);
    }
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
      final endOfDueDay = _toTZ(due, hour: 23);
      final amtFmt = NumberFormat('#,##0', 'en_US').format(loan.emiAmount);

      if (scheduled.isBefore(now)) {
        // Reminder hour already passed today, but the EMI isn't due yet —
        // fire a catch-up notification instead of skipping to next month.
        if (now.isBefore(endOfDueDay)) {
          await _plugin.show(
            id: _emiNotifId(loan.id),
            title: 'EMI Due Soon — ${loan.title}',
            // One-off, so the exact date is correct here.
            body:
                '${loan.lenderName} · ${loan.currency} $amtFmt due ${DateFormat('MMM d').format(due)}',
            notificationDetails: _emiDetails,
            payload: emiPayload,
          );
        }
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

      await _plugin.zonedSchedule(
        id: _emiNotifId(loan.id),
        title: 'EMI Due Soon — ${loan.title}',
        // FIXED: this notification repeats every month, so a fixed date like
        // "due Nov 12" would still say "Nov 12" in December. Use the day only.
        body:
            '${loan.lenderName} · ${loan.currency} $amtFmt due on the '
            '${_ordinal(loan.dayOfMonth)} (in ${loan.remindDaysBefore} days)',
        scheduledDate: scheduled,
        notificationDetails: _emiDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: emiPayload,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleEmiReminder error: $e');
    }
  }

  static const _emiOverdueChannel = AndroidNotificationDetails(
    'emi_overdue',
    'Overdue EMI Reminders',
    channelDescription: 'Daily reminders for unpaid, overdue EMIs',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFFEF4444),
  );

  static const _emiOverdueDetails = NotificationDetails(
    android: _emiOverdueChannel,
    iOS: _ios,
  );

  /// Stable int notification ID for overdue EMI daily nag (300_000 – 399_999).
  static int _emiOverdueNotifId(String id) =>
      id.hashCode.abs() % 100000 + 300000;

  /// Starts a daily repeating "EMI overdue" notification.
  /// Call this once the loan is confirmed overdue; safe to call repeatedly
  /// (it just re-registers the same periodic notification).
  static Future<void> startOverdueReminder(EmiLoan loan) async {
    try {
      final amtFmt = NumberFormat('#,##0', 'en_US').format(loan.emiAmount);

      await _plugin.periodicallyShow(
        id: _emiOverdueNotifId(loan.id),
        title: 'EMI Overdue — ${loan.title}',
        body:
            '${loan.lenderName} · ${loan.currency} $amtFmt is overdue. Pay now to avoid penalties.',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: _emiOverdueDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: emiPayload,
      );
      debugPrint(
        '[NotificationService] Overdue daily reminder started for "${loan.title}"',
      );
    } catch (e) {
      debugPrint('[NotificationService] startOverdueReminder error: $e');
    }
  }

  /// Stops the daily overdue nag — call this the moment a payment is recorded.
  static Future<void> stopOverdueReminder(String loanId) async {
    try {
      await _plugin.cancel(id: _emiOverdueNotifId(loanId));
    } catch (e) {
      debugPrint('[NotificationService] stopOverdueReminder error: $e');
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

  // ── Subscription renewals (NEW) ────────────────────────────────────────────
  /// One-off reminder before a detected subscription renews. [key] is the
  /// subscription's normalized merchant key (e.g. "netflix").
  /// The subscriptions feature calls [cancelAllSubscriptionReminders] and then
  /// this for each subscription whenever it re-detects, so dates stay current.
  static Future<void> scheduleSubscriptionReminder({
    required String key,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    try {
      final scheduled = tz.TZDateTime.from(remindAt, tz.local);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(
        id: _subscriptionNotifId(key),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _subscriptionDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$subscriptionPayload:$key',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] scheduleSubscriptionReminder error: $e',
      );
    }
  }

  static Future<void> cancelAllSubscriptionReminders() =>
      _cancelRange(_subscriptionBase, _subscriptionBase + 100000);

  // ── Tax season (NEW) ───────────────────────────────────────────────────────
  /// Two reminders: Feb 1 ("your report is ready") and two weeks before the
  /// filing deadline (April 15 US / April 30 Canada).
  static Future<void> scheduleTaxSeasonReminders({
    required int taxYear,
    required DateTime deadline,
    required String agency, // 'IRS' or 'CRA'
  }) async {
    try {
      await cancelTaxSeasonReminders();
      final now = tz.TZDateTime.now(tz.local);

      final ready = _toTZ(DateTime(deadline.year, 2, 1), hour: 10);
      if (ready.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: _taxBase,
          title: 'Your $taxYear expense report is ready',
          body: 'Export your categorized expenses in one tap for tax season.',
          scheduledDate: ready,
          notificationDetails: _taxDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: taxPayload,
        );
      }

      final twoWeeksBefore = _toTZ(
        DateTime(deadline.year, deadline.month, deadline.day - 14),
        hour: 10,
      );
      if (twoWeeksBefore.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: _taxBase + 1,
          title: 'Tax deadline in 2 weeks',
          body:
              '$agency returns are due ${DateFormat('MMMM d').format(deadline)}. '
              'Your expense export is ready.',
          scheduledDate: twoWeeksBefore,
          notificationDetails: _taxDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: taxPayload,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] scheduleTaxSeasonReminders error: $e');
    }
  }

  static Future<void> cancelTaxSeasonReminders() async {
    try {
      await _plugin.cancel(id: _taxBase);
      await _plugin.cancel(id: _taxBase + 1);
    } catch (e) {
      debugPrint('[NotificationService] cancelTaxSeasonReminders error: $e');
    }
  }

  // ── Holiday budgets (NEW) ──────────────────────────────────────────────────
  /// One-off alert when a holiday shopping window starts
  /// (e.g. "🛍️ Black Friday starts today — your budget is $300").
  static Future<void> scheduleHolidayBudgetReminder({
    required String budgetId, // e.g. "black_friday_2026"
    required String title,
    required String body,
    required DateTime day,
  }) async {
    try {
      final scheduled = _toTZ(day, hour: 9);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(
        id: _holidayNotifId(budgetId),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _holidayDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$holidayPayload:$budgetId',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] scheduleHolidayBudgetReminder error: $e',
      );
    }
  }

  static Future<void> cancelHolidayBudgetReminder(String budgetId) async {
    try {
      await _plugin.cancel(id: _holidayNotifId(budgetId));
    } catch (e) {
      debugPrint('[NotificationService] cancelHolidayBudgetReminder error: $e');
    }
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
    String title = 'budgetbuddy',
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

  static Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: 0);
      debugPrint('[NotificationService] Daily reminder cancelled');
    } catch (e) {
      debugPrint('[NotificationService] cancelDailyReminder error: $e');
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

  /// Stable int notification ID for bills (range 0 – 99_999).
  static int _billNotifId(String id) => id.hashCode.abs() % 100000;

  /// Stable int notification ID for EMIs (range 100_000 – 199_999).
  static int _emiNotifId(String id) => id.hashCode.abs() % 100000 + 100000;

  static int _subscriptionNotifId(String key) =>
      _stableHash(key) % 100000 + _subscriptionBase;

  static int _holidayNotifId(String budgetId) =>
      _stableHash(budgetId) % 100000 + _holidayBase;

  /// FNV-1a hash. Unlike String.hashCode, guaranteed identical across app
  /// launches and Dart versions, so a reminder can always be found to cancel.
  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  /// Cancels every pending notification whose ID is in [from, to).
  static Future<void> _cancelRange(int from, int to) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= from && p.id < to) await _plugin.cancel(id: p.id);
      }
    } catch (e) {
      debugPrint('[NotificationService] _cancelRange error: $e');
    }
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}
