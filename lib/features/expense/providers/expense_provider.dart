import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

// ── Currency persistence key ──────────────────────────────────────────────────
const _kCurrency = 'selected_currency';
const _kDefaultCurrency = 'NPR';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class ExpenseState {
  final List<Expense> all;
  final Budget budget;
  final int version;

  const ExpenseState({
    required this.all,
    required this.budget,
    this.version = 0,
  });

  ExpenseState copyWith({List<Expense>? all, Budget? budget}) => ExpenseState(
    all: all ?? this.all,
    budget: budget ?? this.budget,
    version: version + 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseState && other.version == version);

  @override
  int get hashCode => version.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class ExpenseNotifier extends Notifier<ExpenseState> {
  Box<Expense> get _box => Hive.box<Expense>('expenses');
  Box<Budget> get _budBox => Hive.box<Budget>('budget');

  // ── Currency — SharedPreferences as source of truth ───────────────────────
  // static: called from main.dart before ProviderScope exists
  static Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrency) ?? _kDefaultCurrency;
  }

  static Future<void> saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
  }

  // ── Budget ─────────────────────────────────────────────────────────────────
  Budget _ensureBudget() {
    if (_budBox.isEmpty) _budBox.add(Budget());
    return _budBox.getAt(0)!;
  }

  @override
  ExpenseState build() {
    final expListenable = _box.listenable();
    final budListenable = _budBox.listenable();

    expListenable.addListener(_onBoxChange);
    budListenable.addListener(_onBoxChange);

    ref.onDispose(() {
      expListenable.removeListener(_onBoxChange);
      budListenable.removeListener(_onBoxChange);
    });

    return ExpenseState(all: _sorted(), budget: _ensureBudget(), version: 0);
  }

  void _onBoxChange() => _refresh();

  void _refresh() {
    state = state.copyWith(
      all: _sorted(),
      budget: _budBox.getAt(0) ?? _ensureBudget(),
    );
  }

  List<Expense> _sorted() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required bool isIncome,
    DateTime? date,
  }) async {
    await _box.add(
      Expense(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: category,
        date: date ?? DateTime.now(),
        isIncome: isIncome,
        currency: state.budget.currency,
      ),
    );
  }

  Future<void> deleteExpense(Expense e) async {
    await e.delete();
  }

  Future<void> deleteById(String id) async {
    final idx = _box.values.toList().indexWhere((e) => e.id == id);
    if (idx >= 0) await _box.deleteAt(idx);
  }

  // ── Budget updates ─────────────────────────────────────────────────────────
  Future<void> updateBudget({double? limit, String? currency}) async {
    final old = _ensureBudget();

    // Always create a NEW Budget instance — never mutate the existing HiveObject.
    // Mutating the same object means budgetProvider gets the same reference
    // and Riverpod skips the rebuild even though the field value changed.
    final updated = Budget(
      monthlyLimit: limit ?? old.monthlyLimit,
      streakDays: old.streakDays,
      lastActiveDate: old.lastActiveDate,
      referralCode: old.referralCode,
      referralCount: old.referralCount,
      currency: currency ?? old.currency,
    );

    if (currency != null) {
      // Save to SharedPreferences FIRST — guaranteed to persist across restarts
      await ExpenseNotifier.saveCurrency(currency);
    }

    // clear() + add() guarantees a brand-new HiveObject reference in the box
    await _budBox.clear();
    await _budBox.add(updated);

    // _refresh() reads the new object from box → new reference → version++
    // → Riverpod sees different state → all watchers rebuild instantly
    _refresh();
  }

  Future<void> updateStreak() async {
    final old = _ensureBudget();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (old.lastActiveDate == today) return;
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    final updated = Budget(
      monthlyLimit: old.monthlyLimit,
      streakDays: old.lastActiveDate == yesterday ? old.streakDays + 1 : 1,
      lastActiveDate: today,
      referralCode: old.referralCode,
      referralCount: old.referralCount,
      currency: old.currency,
    );

    await _budBox.clear();
    await _budBox.add(updated);
    _refresh();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(
  ExpenseNotifier.new,
);

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
  return ref
      .watch(monthExpensesProvider)
      .where((e) => !e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);
});

final monthTotalIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(monthExpensesProvider)
      .where((e) => e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);
});

final monthNetProvider = Provider<double>(
  (ref) =>
      ref.watch(monthTotalIncomeProvider) -
      ref.watch(monthTotalExpenseProvider),
);

final byCategoryProvider = Provider<Map<String, double>>((ref) {
  final m = <String, double>{};
  for (final e in ref.watch(monthExpensesProvider).where((e) => !e.isIncome)) {
    m[e.category] = (m[e.category] ?? 0) + e.amount;
  }
  return Map.fromEntries(
    m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
});

final budgetProvider = Provider<Budget>(
  (ref) => ref.watch(expenseProvider).budget,
);

// currencyProvider watches expenseProvider directly for version changes
// AND budgetProvider for the actual value — dual watch guarantees rebuild
final currencyProvider = Provider<String>((ref) {
  ref.watch(expenseProvider); // version++ triggers this rebuild
  return ref.watch(budgetProvider).currency;
});

// Explicitly watches currencyProvider — no indirect chain dependency
final symbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  return currencyOf(currency).symbol;
});

// Explicitly watches currencyProvider — rebuilds whenever currency changes
final fmtProvider = Provider<String Function(double)>((ref) {
  final currency = ref.watch(currencyProvider);
  final sym = currencyOf(currency).symbol;
  return (double amount) => _fmt(sym, amount);
});

final budgetUsedPctProvider = Provider<double>((ref) {
  final spent = ref.watch(monthTotalExpenseProvider);
  final limit = ref.watch(budgetProvider).monthlyLimit;
  return limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.0);
});

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

// Per-expense formatter — uses currency stored ON the expense, not current setting
String fmtExpense(Expense e) => _fmt(currencyOf(e.currency).symbol, e.amount);

String _fmt(String sym, double amount) {
  if (amount >= 1_000_000)
    return '$sym${(amount / 1_000_000).toStringAsFixed(1)}M';
  if (amount >= 1_000) return '$sym${(amount / 1_000).toStringAsFixed(1)}K';
  return '$sym${amount.toStringAsFixed(0)}';
}
