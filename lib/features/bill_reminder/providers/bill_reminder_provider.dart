import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

const _pageSize = 10;

class BillReminderState {
  final List<BillReminder> all;
  final int page; // current page (0-indexed)
  final bool isLoading;

  const BillReminderState({
    this.all = const [],
    this.page = 0,
    this.isLoading = false,
  });

  // Paginated view — items for current page
  List<BillReminder> get paged =>
      all.skip(page * _pageSize).take(_pageSize).toList();

  bool get hasNextPage => (page + 1) * _pageSize < all.length;
  bool get hasPrevPage => page > 0;
  int get totalPages => (all.length / _pageSize).ceil().clamp(1, 999);

  // Due-soon bills (shown as alert strip on home)
  List<BillReminder> get dueSoon =>
      all.where((b) => b.isActive && b.isDueSoon).toList()
        ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

  // Overdue bills
  List<BillReminder> get overdue =>
      all.where((b) => b.isActive && b.isOverdue).toList();

  // Monthly total commitment
  double get monthlyTotal => all
      .where((b) => b.isActive && b.isRecurring)
      .fold(0.0, (s, b) => s + b.amount);

  BillReminderState copyWith({
    List<BillReminder>? all,
    int? page,
    bool? isLoading,
  }) => BillReminderState(
    all: all ?? this.all,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
  );
}

class BillReminderNotifier extends Notifier<BillReminderState> {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _notifChannel = AndroidNotificationDetails(
    'bill_reminders',
    'Bill Reminders',
    channelDescription: 'Upcoming bill and EMI payment reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    color: AppColors.primaryColor,
  );

  @override
  BillReminderState build() {
    final items = HiveStorage.allBillReminders()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

    return BillReminderState(all: items, isLoading: false);
  }

  void _loadAll() {
    final items = HiveStorage.allBillReminders()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

    state = state.copyWith(all: items);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> add(BillReminder bill) async {
    await HiveStorage.saveBillReminder(bill);

    _loadAll();

    await _scheduleNotification(bill);
  }

  Future<void> update(BillReminder bill) async {
    await HiveStorage.saveBillReminder(bill);

    _loadAll();

    await _cancelNotification(bill.id);

    if (bill.isActive) {
      await _scheduleNotification(bill);
    }
  }

  Future<void> delete(String id) async {
    await HiveStorage.deleteBillReminder(id);

    await _cancelNotification(id);

    _loadAll();
  }

  Future<void> toggleActive(String id) async {
    final bill = HiveStorage.getBillReminder(id);

    if (bill == null) return;

    bill.isActive = !bill.isActive;

    await bill.save();

    if (bill.isActive) {
      await _scheduleNotification(bill);
    } else {
      await _cancelNotification(id);
    }

    _loadAll();
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  void nextPage() {
    if (state.hasNextPage) state = state.copyWith(page: state.page + 1);
  }

  void prevPage() {
    if (state.hasPrevPage) state = state.copyWith(page: state.page - 1);
  }

  void goToPage(int p) =>
      state = state.copyWith(page: p.clamp(0, state.totalPages - 1));

  // ── Notification scheduling ───────────────────────────────────────────────
  // Schedules a notification X days before each bill's due date
  Future<void> _scheduleNotification(BillReminder bill) async {
    try {
      final due = bill.computedDueDate;
      final notifAt = due.subtract(Duration(days: bill.remindDaysBefore));
      final scheduledDate = tz.TZDateTime.from(
        DateTime(notifAt.year, notifAt.month, notifAt.day, 9, 0), // 9:00 AM
        tz.local,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        // Already past — schedule for next occurrence if recurring
        if (!bill.isRecurring) return;
        final nextDue = DateTime(
          due.year,
          due.month + 1,
          bill.dayOfMonth.clamp(1, 28),
        );
        final nextNotif = nextDue.subtract(
          Duration(days: bill.remindDaysBefore),
        );
        final nextSched = tz.TZDateTime.from(
          DateTime(nextNotif.year, nextNotif.month, nextNotif.day, 9, 0),
          tz.local,
        );
        if (nextSched.isBefore(tz.TZDateTime.now(tz.local))) return;
        await _plugin.zonedSchedule(
          id: _notifId(bill.id), // stable int ID from bill ID string
          title:
              '${bill.emoji} ${bill.title} due in ${bill.remindDaysBefore} days',
          body:
              '${bill.category} · ${bill.currency} ${bill.amount.toStringAsFixed(0)}',
          scheduledDate: nextSched,
          notificationDetails: NotificationDetails(
            android: _notifChannel,
            iOS: const DarwinNotificationDetails(),
          ),
          // uiLocalNotificationDateInterpretation:
          //     UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: bill.isRecurring
              ? DateTimeComponents.dayOfMonthAndTime
              : null,
        );
        return;
      }

      await _plugin.zonedSchedule(
        id: _notifId(bill.id),
        title:
            '${bill.emoji} ${bill.title} due in ${bill.remindDaysBefore} days',
        body:
            '${bill.category} · ${bill.currency} ${bill.amount.toStringAsFixed(0)}',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: _notifChannel,
          iOS: const DarwinNotificationDetails(),
        ),
        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: bill.isRecurring
            ? DateTimeComponents.dayOfMonthAndTime
            : null,
      );
      debugPrint('[BillReminder] Scheduled "${bill.title}" at $scheduledDate');
    } catch (e) {
      debugPrint('[BillReminder] Schedule error: $e');
    }
  }

  Future<void> _cancelNotification(String id) async {
    try {
      await _plugin.cancel(id: _notifId(id));
    } catch (_) {}
  }

  // Stable int ID from string UUID (last 6 chars as hex → int)
  int _notifId(String id) => id.hashCode.abs() % 100000;

  // ── Re-schedule all on app start (in case of device restart) ─────────────
  Future<void> rescheduleAll() async {
    final reminders = HiveStorage.activeBillReminders();

    for (final bill in reminders) {
      await _scheduleNotification(bill);
    }

    debugPrint('[BillReminder] Rescheduled ${reminders.length} reminders');
  }
}

final billReminderProvider =
    NotifierProvider<BillReminderNotifier, BillReminderState>(
      BillReminderNotifier.new,
    );

// ── Convenience providers ────────────────────────────────────────────────────
final dueSoonBillsProvider = Provider<List<BillReminder>>(
  (ref) => ref.watch(billReminderProvider).dueSoon,
);

final overdueBillsProvider = Provider<List<BillReminder>>(
  (ref) => ref.watch(billReminderProvider).overdue,
);

final monthlyBillTotalProvider = Provider<double>(
  (ref) => ref.watch(billReminderProvider).monthlyTotal,
);
