import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class EmiLoanState {
  final List<EmiLoan> loans;
  final bool isLoading;

  /// Extra-payment simulation slider value (persists across tab switches)
  final double simulationExtra;

  const EmiLoanState({
    this.loans = const [],
    this.isLoading = false,
    this.simulationExtra = 0,
  });

  // ── Derived ───────────────────────────────────────────────────────────────
  List<EmiLoan> get activeLoans => loans.where((l) => l.isActive).toList();
  List<EmiLoan> get overdueLoans =>
      loans.where((l) => l.isActive && l.isOverdue).toList();
  List<EmiLoan> get dueSoonLoans =>
      loans.where((l) => l.isActive && l.isDueSoon).toList();

  double get totalMonthlyEmi =>
      activeLoans.fold(0.0, (s, l) => s + l.emiAmount);

  double get totalOutstanding =>
      activeLoans.fold(0.0, (s, l) => s + l.remainingBalance);

  double get totalInterestRemaining =>
      activeLoans.fold(0.0, (s, l) => s + l.calcRemainingInterest());

  int get totalMissedPayments => loans.fold(0, (s, l) => s + l.missedPayments);

  EmiLoanState copyWith({
    List<EmiLoan>? loans,
    bool? isLoading,
    double? simulationExtra,
  }) => EmiLoanState(
    loans: loans ?? this.loans,
    isLoading: isLoading ?? this.isLoading,
    simulationExtra: simulationExtra ?? this.simulationExtra,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class EmiLoanNotifier extends Notifier<EmiLoanState> {
  @override
  EmiLoanState build() {
    final items = HiveStorage.allEmiLoans()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return EmiLoanState(loans: items);
  }

  void _reload() {
    final items = HiveStorage.allEmiLoans()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    state = state.copyWith(loans: items);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> addLoan(EmiLoan loan) async {
    await HiveStorage.saveEmiLoan(loan);
    _reload();
    if (loan.remindersEnabled) {
      await NotificationService.scheduleEmiReminder(loan);
    }
  }

  Future<void> updateLoan(EmiLoan loan) async {
    loan.updatedAt = DateTime.now();
    loan.synced = false;
    await HiveStorage.saveEmiLoan(loan);
    _reload();
    await NotificationService.cancelEmiReminder(loan.id);
    if (loan.remindersEnabled && loan.isActive) {
      await NotificationService.scheduleEmiReminder(loan);
    }
  }

  Future<void> deleteLoan(String id) async {
    await HiveStorage.deleteEmiLoan(id);
    await NotificationService.cancelEmiReminder(id);
    _reload();
  }

  Future<void> toggleActive(String id) async {
    final loan = HiveStorage.getEmiLoan(id);
    if (loan == null) return;
    loan.isActive = !loan.isActive;
    loan.updatedAt = DateTime.now();
    await loan.save();
    loan.isActive
        ? await NotificationService.scheduleEmiReminder(loan)
        : await NotificationService.cancelEmiReminder(id);
    _reload();
  }

  // ── Payments ──────────────────────────────────────────────────────────────
  Future<void> recordPayment(String loanId, EmiPayment payment) async {
    final loan = HiveStorage.getEmiLoan(loanId);
    if (loan == null) return;
    final updated = List<EmiPayment>.from(loan.payments)..add(payment);
    loan.payments = updated;
    loan.updatedAt = DateTime.now();
    loan.synced = false;
    await loan.save();
    _reload();
  }

  Future<void> recordExtraPayment(
    String loanId,
    double amount,
    String note,
  ) async {
    final loan = HiveStorage.getEmiLoan(loanId);
    if (loan == null) return;
    final payment = EmiPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      isExtraPayment: true,
      note: note,
    );
    final updated = List<EmiPayment>.from(loan.payments)..add(payment);
    loan.payments = updated;
    loan.totalExtraPayments += amount;
    loan.updatedAt = DateTime.now();
    loan.synced = false;
    await loan.save();
    _reload();
  }

  // ── Simulation ────────────────────────────────────────────────────────────
  void setSimulationExtra(double value) =>
      state = state.copyWith(simulationExtra: value);

  // ── Reschedule on app start ────────────────────────────────────────────────
  Future<void> rescheduleAll() async {
    for (final loan in state.activeLoans) {
      if (loan.remindersEnabled) {
        await NotificationService.scheduleEmiReminder(loan);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final emiLoanProvider = NotifierProvider<EmiLoanNotifier, EmiLoanState>(
  EmiLoanNotifier.new,
);

final overdueEmiProvider = Provider<List<EmiLoan>>(
  (ref) => ref.watch(emiLoanProvider).overdueLoans,
);

final dueSoonEmiProvider = Provider<List<EmiLoan>>(
  (ref) => ref.watch(emiLoanProvider).dueSoonLoans,
);

final totalMonthlyEmiProvider = Provider<double>(
  (ref) => ref.watch(emiLoanProvider).totalMonthlyEmi,
);
