import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _pageSize = 10;

// ── State ─────────────────────────────────────────────────────────────────────
class BillReminderState {
  final List<BillReminder> all;
  final int page;
  final bool isLoading;

  const BillReminderState({
    this.all = const [],
    this.page = 0,
    this.isLoading = false,
  });

  List<BillReminder> get paged =>
      all.skip(page * _pageSize).take(_pageSize).toList();

  bool get hasNextPage => (page + 1) * _pageSize < all.length;
  bool get hasPrevPage => page > 0;
  int get totalPages => (all.length / _pageSize).ceil().clamp(1, 999);

  List<BillReminder> get dueSoon =>
      all.where((b) => b.isActive && b.isDueSoon).toList()
        ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

  List<BillReminder> get overdue =>
      all.where((b) => b.isActive && b.isOverdue).toList();

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

// ── Notifier ──────────────────────────────────────────────────────────────────
class BillReminderNotifier extends Notifier<BillReminderState> {
  @override
  BillReminderState build() {
    final items = HiveStorage.allBillReminders()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return BillReminderState(all: items);
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
    await NotificationService.scheduleBillReminder(bill);
  }

  Future<void> update(BillReminder bill) async {
    await HiveStorage.saveBillReminder(bill);
    _loadAll();
    await NotificationService.cancelBillReminder(bill.id);
    if (bill.isActive) {
      await NotificationService.scheduleBillReminder(bill);
    }
  }

  Future<void> delete(String id) async {
    await HiveStorage.deleteBillReminder(id);
    await NotificationService.cancelBillReminder(id);
    _loadAll();
  }

  Future<void> toggleActive(String id) async {
    final bill = HiveStorage.getBillReminder(id);
    if (bill == null) return;

    bill.isActive = !bill.isActive;
    await bill.save();

    if (bill.isActive) {
      await NotificationService.scheduleBillReminder(bill);
    } else {
      await NotificationService.cancelBillReminder(id);
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

  // ── Re-schedule all (call on app start / device restart) ──────────────────
  Future<void> rescheduleAll() async {
    final reminders = HiveStorage.activeBillReminders();
    await NotificationService.rescheduleAllBillReminders(reminders);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final billReminderProvider =
    NotifierProvider<BillReminderNotifier, BillReminderState>(
      BillReminderNotifier.new,
    );

// ── Convenience providers ─────────────────────────────────────────────────────
final dueSoonBillsProvider = Provider<List<BillReminder>>(
  (ref) => ref.watch(billReminderProvider).dueSoon,
);

final overdueBillsProvider = Provider<List<BillReminder>>(
  (ref) => ref.watch(billReminderProvider).overdue,
);

final monthlyBillTotalProvider = Provider<double>(
  (ref) => ref.watch(billReminderProvider).monthlyTotal,
);
