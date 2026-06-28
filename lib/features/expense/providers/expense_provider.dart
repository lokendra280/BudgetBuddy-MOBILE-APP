import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kCurrency = 'selected_currency';
const _kDefaultCurrency = 'NPR';
const kPageSize = 20;

// ─────────────────────────────────────────────────────────────────────────────
// ExpenseState
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
      (other is ExpenseState &&
          other.version == version &&
          other.all.length == all.length);

  @override
  int get hashCode => version.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// PaginatedExpenseState
// ─────────────────────────────────────────────────────────────────────────────
class PaginatedExpenseState {
  final List<Expense> items;
  final bool hasMore;
  final bool isLoading;
  final int page;

  const PaginatedExpenseState({
    this.items = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.page = 0,
  });

  PaginatedExpenseState copyWith({
    List<Expense>? items,
    bool? hasMore,
    bool? isLoading,
    int? page,
  }) => PaginatedExpenseState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    page: page ?? this.page,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ExpenseNotifier
// ─────────────────────────────────────────────────────────────────────────────
class ExpenseNotifier extends Notifier<ExpenseState> {
  Box<Expense> get _box => Hive.box<Expense>('expenses');
  Box<Budget> get _budBox => Hive.box<Budget>('budget');

  // ── Currency ──────────────────────────────────────────────────────────────
  static Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrency) ?? _kDefaultCurrency;
  }

  static Future<void> saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
  }

  // ── Budget ────────────────────────────────────────────────────────────────
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

  Future<void> deleteExpense(Expense e) async => await e.delete();

  Future<void> deleteById(String id) async {
    final idx = _box.values.toList().indexWhere((e) => e.id == id);
    if (idx >= 0) await _box.deleteAt(idx);
  }

  // ── Budget ────────────────────────────────────────────────────────────────
  Future<void> updateBudget({double? limit, String? currency}) async {
    final old = _ensureBudget();
    final updated = Budget(
      monthlyLimit: limit ?? old.monthlyLimit,
      streakDays: old.streakDays,
      lastActiveDate: old.lastActiveDate,
      referralCode: old.referralCode,
      referralCount: old.referralCount,
      currency: currency ?? old.currency,
    );

    if (currency != null) await ExpenseNotifier.saveCurrency(currency);

    await _budBox.clear();
    await _budBox.add(updated);
    _refresh();
  }

  Future<void> updateStreak() async {
    final old = _ensureBudget();
    final today = _dateStr(DateTime.now());
    if (old.lastActiveDate == today) return;

    final yesterday = _dateStr(
      DateTime.now().subtract(const Duration(days: 1)),
    );
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

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// PaginatedExpenseNotifier
// ─────────────────────────────────────────────────────────────────────────────
class PaginatedExpenseNotifier
    extends FamilyNotifier<PaginatedExpenseState, DateTime> {
  DateTime get _month => arg;

  @override
  PaginatedExpenseState build(DateTime arg) {
    // Listen to expense changes and reset pagination
    ref.watch(expenseProvider);
    return const PaginatedExpenseState();
  }

  List<Expense> get _monthExpenses {
    final all = ref.read(expenseProvider).all;
    return all
        .where(
          (e) => e.date.month == _month.month && e.date.year == _month.year,
        )
        .toList();
  }

  /// Load initial page — call once on screen init
  void loadInitial() {
    final all = _monthExpenses;
    final items = all.take(kPageSize).toList();
    state = PaginatedExpenseState(
      items: items,
      hasMore: all.length > kPageSize,
      isLoading: false,
      page: 1,
    );
  }

  /// Load next page — call when user scrolls to bottom
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    // Simulate async fetch delay (replace with real Supabase paginated fetch)
    await Future.delayed(const Duration(milliseconds: 200));

    final all = _monthExpenses;
    final nextPage = state.page + 1;
    final end = nextPage * kPageSize;
    final newItems = all.take(end).toList();

    state = state.copyWith(
      items: newItems,
      hasMore: end < all.length,
      isLoading: false,
      page: nextPage,
    );
  }

  void reset() {
    state = const PaginatedExpenseState();
    loadInitial();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Core Providers
// ─────────────────────────────────────────────────────────────────────────────

final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(
  ExpenseNotifier.new,
);

final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

// ── Paginated provider — family keyed by month ────────────────────────────
final paginatedExpenseProvider =
    NotifierProviderFamily<
      PaginatedExpenseNotifier,
      PaginatedExpenseState,
      DateTime
    >(PaginatedExpenseNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Derived Providers — all scoped to selected month
// ─────────────────────────────────────────────────────────────────────────────

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

final currencyProvider = Provider<String>((ref) {
  ref.watch(expenseProvider);
  return ref.watch(budgetProvider).currency;
});

final symbolProvider = Provider<String>((ref) {
  return currencyOf(ref.watch(currencyProvider)).symbol;
});

final fmtProvider = Provider<String Function(double)>((ref) {
  final sym = currencyOf(ref.watch(currencyProvider)).symbol;
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

// ── Helpers ───────────────────────────────────────────────────────────────────
String fmtExpense(Expense e) => _fmt(currencyOf(e.currency).symbol, e.amount);

String _fmt(String sym, double amount) {
  if (amount >= 1_000_000)
    return '$sym${(amount / 1_000_000).toStringAsFixed(1)}M';
  if (amount >= 1_000) return '$sym${(amount / 1_000).toStringAsFixed(1)}K';
  return '$sym${amount.toStringAsFixed(0)}';
}
