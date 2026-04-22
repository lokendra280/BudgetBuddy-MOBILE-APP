import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseService {
  static Box<Expense> get box => Hive.box<Expense>('expenses');
  static Box<Budget> get budgetBox => Hive.box<Budget>('budget');

  static Budget get budget {
    if (budgetBox.isEmpty) budgetBox.add(Budget());
    return budgetBox.getAt(0)!;
  }

  static String get currency => budget.currency;
  static String get symbol => currencyOf(currency).symbol;

  static List<Expense> get all =>
      box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  static List<Expense> forMonth(DateTime m) => all
      .where((e) => e.date.month == m.month && e.date.year == m.year)
      .toList();

  static List<Expense> forWeek(DateTime start) {
    final end = start.add(const Duration(days: 7));
    return all
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  static double totalFor(List<Expense> list) =>
      list.fold(0.0, (s, e) => s + e.amount);

  static double incomeFor(List<Expense> list) =>
      totalFor(list.where((e) => e.isIncome).toList());
  static double expenseFor(List<Expense> list) =>
      totalFor(list.where((e) => !e.isIncome).toList());

  static Map<String, double> byCategory(List<Expense> list) {
    final m = <String, double>{};
    for (final e in list) m[e.category] = (m[e.category] ?? 0) + e.amount;
    return Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // Daily income & expense for past N days
  static List<({double income, double expense})> dailyTotals({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final dayItems = all.where(
        (e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day,
      );
      return (
        income: dayItems
            .where((e) => e.isIncome)
            .fold(0.0, (s, e) => s + e.amount),
        expense: dayItems
            .where((e) => !e.isIncome)
            .fold(0.0, (s, e) => s + e.amount),
      );
    });
  }

  // Daily expense only (for bar chart)
  static List<double> last7DayExpenses() =>
      dailyTotals(days: 7).map((d) => d.expense).toList();

  static String fmt(double amount) {
    final sym = symbol;
    if (amount >= 1000000)
      return '$sym${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '$sym${(amount / 1000).toStringAsFixed(1)}K';
    return '$sym${amount.toStringAsFixed(0)}';
  }

  static String wasteMessage(double thisWeek, double lastWeek) {
    if (thisWeek == 0) return "You haven't spent anything yet 🧘";
    if (lastWeek == 0) return "${fmt(thisWeek)} spent this week 💸";
    final diff = thisWeek - lastWeek;
    if (diff > 0) return "You spent ${fmt(diff)} MORE than last week 😳";
    if (diff < 0) return "You saved ${fmt(-diff)} vs last week 🎉";
    return "Spending about the same as last week 😌";
  }

  static String topWasteCategory(List<Expense> list) {
    final expenses = list.where((e) => !e.isIncome).toList();
    final cats = byCategory(expenses);
    if (cats.isEmpty) return '';
    final top = cats.entries.first;
    return 'Top spend: ${top.key} at ${fmt(top.value)} 🚨';
  }

  static void updateStreak() {
    final b = budget;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (b.lastActiveDate == today) return;
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    b.streakDays = (b.lastActiveDate == yesterday) ? b.streakDays + 1 : 1;
    b.lastActiveDate = today;
    b.save();
  }

  static double budgetUsedPercent() {
    final spent = expenseFor(forMonth(DateTime.now()));
    final limit = budget.monthlyLimit;
    if (limit <= 0) return 0;
    return (spent / limit).clamp(0.0, 1.0);
  }

  static (double, double) weekComparison() {
    final now = DateTime.now();
    final thisStart = now.subtract(Duration(days: now.weekday - 1));
    final lastStart = thisStart.subtract(const Duration(days: 7));
    return (expenseFor(forWeek(thisStart)), expenseFor(forWeek(lastStart)));
  }
}
