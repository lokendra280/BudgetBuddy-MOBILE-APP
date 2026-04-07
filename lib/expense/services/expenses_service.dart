import 'package:expensetracker/expense/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ExpenseService {
  static Box<Expense> get box => Hive.box<Expense>('expenses');
  static Box<Budget> get budgetBox => Hive.box<Budget>('budget');

  static Budget get budget {
    if (budgetBox.isEmpty) budgetBox.add(Budget());
    return budgetBox.getAt(0)!;
  }

  static List<Expense> get all =>
      box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  static List<Expense> forMonth(DateTime m) => all
      .where((e) => e.date.month == m.month && e.date.year == m.year)
      .toList();

  static List<Expense> forWeek(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return all
        .where((e) => e.date.isAfter(weekStart) && e.date.isBefore(end))
        .toList();
  }

  static double totalFor(List<Expense> list) =>
      list.fold(0, (s, e) => s + e.amount);

  static Map<String, double> byCategory(List<Expense> list) {
    final m = <String, double>{};
    for (final e in list) m[e.category] = (m[e.category] ?? 0) + e.amount;
    return Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // Returns daily totals for the past 7 days
  static List<double> last7DayTotals() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return totalFor(
        all
            .where(
              (e) =>
                  e.date.year == day.year &&
                  e.date.month == day.month &&
                  e.date.day == day.day,
            )
            .toList(),
      );
    });
  }

  static String wasteMessage(double thisWeek, double lastWeek) {
    if (thisWeek == 0) return "You haven't spent anything yet 🧘";
    if (lastWeek == 0)
      return "₹${thisWeek.toStringAsFixed(0)} spent this week 💸";
    final diff = thisWeek - lastWeek;
    if (diff > 500)
      return "You wasted ₹${diff.toStringAsFixed(0)} MORE than last week 😳";
    if (diff < -500)
      return "You saved ₹${(-diff).toStringAsFixed(0)} vs last week 🎉";
    return "Spending about the same as last week 😌";
  }

  static String topWasteCategory(List<Expense> list) {
    final cats = byCategory(list);
    if (cats.isEmpty) return '';
    final top = cats.entries.first;
    return 'You spent too much on ${top.key} (₹${top.value.toStringAsFixed(0)}) 🚨';
  }

  // Streak logic
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
    final spent = totalFor(forMonth(DateTime.now()));
    return (spent / budget.monthlyLimit).clamp(0, 1);
  }

  // Week-over-week comparison
  static (double, double) weekComparison() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    return (totalFor(forWeek(thisWeekStart)), totalFor(forWeek(lastWeekStart)));
  }
}
