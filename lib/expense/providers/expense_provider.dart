import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSE NOTIFIER — owns the Hive box, exposes CRUD + computed values
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseState {
  final List<Expense> all;
  final Budget budget;
  const ExpenseState({required this.all, required this.budget});

  ExpenseState copyWith({List<Expense>? all, Budget? budget}) =>
      ExpenseState(all: all ?? this.all, budget: budget ?? this.budget);
}

class ExpenseNotifier extends Notifier<ExpenseState> {
  Box<Expense> get _box => Hive.box<Expense>('expenses');
  Box<Budget> get _budBox => Hive.box<Budget>('budget');

  Budget _ensureBudget() {
    if (_budBox.isEmpty) _budBox.add(Budget());
    return _budBox.getAt(0)!;
  }

  @override
  ExpenseState build() {
    // Listen to Hive box changes — rebuild when box changes
    _box.listenable().addListener(_onBoxChange);
    return ExpenseState(all: _sorted(), budget: _ensureBudget());
  }

  void _onBoxChange() {
    state = state.copyWith(all: _sorted(), budget: _ensureBudget());
  }

  List<Expense> _sorted() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required bool isIncome,
    DateTime? date,
  }) async {
    final b = state.budget;
    await _box.add(
      Expense(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: category,
        date: date ?? DateTime.now(),
        isIncome: isIncome,
        currency: b.currency,
      ),
    );
    _refresh();
  }

  Future<void> deleteExpense(Expense e) async {
    await e.delete();
    _refresh();
  }

  Future<void> deleteById(String id) async {
    final idx = _box.values.toList().indexWhere((e) => e.id == id);
    if (idx >= 0) await _box.deleteAt(idx);
    _refresh();
  }

  // ── Budget updates ─────────────────────────────────────────────────────────
  Future<void> updateBudget({double? limit, String? currency}) async {
    final b = _ensureBudget();
    if (limit != null) b.monthlyLimit = limit;
    if (currency != null) b.currency = currency;
    await b.save();
    _refresh();
  }

  Future<void> updateStreak() async {
    final b = _ensureBudget();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (b.lastActiveDate == today) return;
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    b.streakDays = b.lastActiveDate == yesterday ? b.streakDays + 1 : 1;
    b.lastActiveDate = today;
    await b.save();
    _refresh();
  }

  void _refresh() {
    state = ExpenseState(all: _sorted(), budget: _ensureBudget());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(
  ExpenseNotifier.new,
);

// ── Derived: all expenses for selected month ─────────────────────────────────
final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

final monthExpensesProvider = Provider<List<Expense>>((ref) {
  final all = ref.watch(expenseProvider).all;
  final month = ref.watch(selectedMonthProvider);
  return all
      .where((e) => e.date.month == month.month && e.date.year == month.year)
      .toList();
});

final monthTotalExpenseProvider = Provider<double>((ref) {
  final list = ref.watch(monthExpensesProvider);
  return list.where((e) => !e.isIncome).fold(0.0, (s, e) => s + e.amount);
});

final monthTotalIncomeProvider = Provider<double>((ref) {
  final list = ref.watch(monthExpensesProvider);
  return list.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount);
});

final monthNetProvider = Provider<double>((ref) {
  return ref.watch(monthTotalIncomeProvider) -
      ref.watch(monthTotalExpenseProvider);
});

final byCategoryProvider = Provider<Map<String, double>>((ref) {
  final list = ref
      .watch(monthExpensesProvider)
      .where((e) => !e.isIncome)
      .toList();
  final m = <String, double>{};
  for (final e in list) m[e.category] = (m[e.category] ?? 0) + e.amount;
  return Map.fromEntries(
    m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
});

final budgetProvider = Provider<Budget>((ref) {
  return ref.watch(expenseProvider).budget;
});

final currencyProvider = Provider<String>((ref) {
  return ref.watch(budgetProvider).currency;
});

final symbolProvider = Provider<String>((ref) {
  return currencyOf(ref.watch(currencyProvider)).symbol;
});

final budgetUsedPctProvider = Provider<double>((ref) {
  final spent = ref.watch(monthTotalExpenseProvider);
  final limit = ref.watch(budgetProvider).monthlyLimit;
  if (limit <= 0) return 0;
  return (spent / limit).clamp(0.0, 1.0);
});

// ── Week comparison ───────────────────────────────────────────────────────────
final weekComparisonProvider = Provider<(double, double)>((ref) {
  final all = ref.watch(expenseProvider).all;
  final now = DateTime.now();
  final thisStart = now.subtract(Duration(days: now.weekday - 1));
  final lastStart = thisStart.subtract(const Duration(days: 7));
  final thisEnd = thisStart.add(const Duration(days: 7));
  final lastEnd = lastStart.add(const Duration(days: 7));
  double thisW = 0, lastW = 0;
  for (final e in all.where((e) => !e.isIncome)) {
    if (e.date.isAfter(thisStart) && e.date.isBefore(thisEnd))
      thisW += e.amount;
    if (e.date.isAfter(lastStart) && e.date.isBefore(lastEnd))
      lastW += e.amount;
  }
  return (thisW, lastW);
});

// ── Daily totals (last 7 days) ────────────────────────────────────────────────
final daily7Provider = Provider<List<({double income, double expense})>>((ref) {
  final all = ref.watch(expenseProvider).all;
  final now = DateTime.now();
  return List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final items = all.where(
      (e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day,
    );
    return (
      income: items.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount),
      expense: items
          .where((e) => !e.isIncome)
          .fold(0.0, (s, e) => s + e.amount),
    );
  });
});

// ── Global formatter (uses the user's CURRENT preferred currency) ─────────────
// Use this for summary totals (monthly total, net, budget bar) where we are
// aggregating many expenses and showing one combined number.
// Do NOT use this for individual expense amounts — use fmtExpense() instead.
final fmtProvider = Provider<String Function(double)>((ref) {
  final sym = ref.watch(symbolProvider);
  return (double amount) => _fmt(sym, amount);
});

// ── Per-expense formatter (uses the currency STORED ON EACH EXPENSE) ──────────
// Fixes the bug: adding an expense in AUD, then changing settings to GBP,
// previously showed the AUD amount with a £ symbol.
// Now each expense always displays with its own saved currency symbol.
String fmtExpense(Expense e) {
  final sym = currencyOf(e.currency).symbol;
  return _fmt(sym, e.amount);
}

// ── Shared format logic ────────────────────────────────────────────────────────
String _fmt(String sym, double amount) {
  if (amount >= 1_000_000)
    return '$sym${(amount / 1_000_000).toStringAsFixed(1)}M';
  if (amount >= 1_000) return '$sym${(amount / 1_000).toStringAsFixed(1)}K';
  return '$sym${amount.toStringAsFixed(0)}';
}
