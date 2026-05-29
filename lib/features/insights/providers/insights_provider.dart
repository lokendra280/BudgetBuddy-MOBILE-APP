import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/forecast/providers/forecast_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── 2. Spending patterns — detects behavior trends ────────────────────────────
class SpendingPattern {
  final String label, description, emoji;
  final double value;
  const SpendingPattern(this.label, this.description, this.emoji, this.value);
}

final spendingPatternsProvider = Provider<List<SpendingPattern>>((ref) {
  final all = ref.watch(expenseProvider).all;
  if (all.isEmpty) return [];

  final expenses = all.where((e) => !e.isIncome).toList();
  final now = DateTime.now();

  // Weekend vs weekday spending
  final weekendSpend = expenses
      .where((e) => e.date.weekday >= 6)
      .fold(0.0, (s, e) => s + e.amount);
  final weekdaySpend = expenses
      .where((e) => e.date.weekday < 6)
      .fold(0.0, (s, e) => s + e.amount);
  final weekendDays = expenses
      .where((e) => e.date.weekday >= 6)
      .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
      .toSet()
      .length
      .clamp(1, 999);
  final weekdayDays = expenses
      .where((e) => e.date.weekday < 6)
      .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
      .toSet()
      .length
      .clamp(1, 999);
  final weekendAvg = weekendSpend / weekendDays;
  final weekdayAvg = weekdaySpend / weekdayDays;

  // Month-over-month
  final thisMonth = expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .fold(0.0, (s, e) => s + e.amount);
  final lastMonth = expenses
      .where((e) => e.date.month == now.month - 1 && e.date.year == now.year)
      .fold(0.0, (s, e) => s + e.amount);
  final momChange = lastMonth > 0
      ? (thisMonth - lastMonth) / lastMonth * 100
      : 0.0;

  // Category concentration
  final catMap = <String, double>{};
  for (final e in expenses)
    catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
  final total = expenses.fold(0.0, (s, e) => s + e.amount);
  final topCat = catMap.entries.isEmpty
      ? null
      : catMap.entries.reduce((a, b) => a.value > b.value ? a : b);

  return [
    SpendingPattern(
      'Weekend vs Weekday',
      weekendAvg > weekdayAvg * 1.2
          ? 'You spend ${((weekendAvg / weekdayAvg - 1) * 100).toInt()}% more on weekends'
          : 'Spending is balanced across the week',
      weekendAvg > weekdayAvg * 1.2 ? '🎉' : '✅',
      weekendAvg,
    ),
    SpendingPattern(
      'Month-over-Month',
      momChange > 10
          ? 'Spending up ${momChange.abs().toInt()}% vs last month'
          : momChange < -10
          ? 'Great! Down ${momChange.abs().toInt()}% vs last month'
          : 'Spending stable vs last month',
      momChange > 10
          ? '📈'
          : momChange < -10
          ? '📉'
          : '➡️',
      momChange,
    ),
    if (topCat != null)
      SpendingPattern(
        'Top Category',
        '${topCat.key} is ${(topCat.value / total * 100).toInt()}% of total spend',
        '🏆',
        topCat.value,
      ),
  ];
});

// ── 4. Automatic salary detection from expense list ───────────────────────────
class DetectedIncome {
  final double amount;
  final String source;
  final DateTime date;
  const DetectedIncome(this.amount, this.source, this.date);
}

final salaryDetectionProvider = Provider<List<DetectedIncome>>((ref) {
  final all = ref.watch(expenseProvider).all;
  return all
      .where((e) => e.isIncome && e.amount > 5000) // filter noise
      .map((e) => DetectedIncome(e.amount, e.title, e.date))
      .take(6)
      .toList();
});

// ── 5. Personalized daily insights feed ──────────────────────────────────────
class InsightCard {
  final String title, body, emoji, type;
  final double? value;
  const InsightCard(this.title, this.body, this.emoji, this.type, [this.value]);
}

final insightsFeedProvider = Provider<List<InsightCard>>((ref) {
  final budget = ref.watch(budgetProvider);
  final monthly = ref.watch(monthExpensesProvider);
  final patterns = ref.watch(spendingPatternsProvider);
  final forecast = ref.watch(forecastProvider);
  final weekComp = ref.watch(weekComparisonProvider);

  final expenses = monthly.where((e) => !e.isIncome).toList();
  final total = expenses.fold(0.0, (s, e) => s + e.amount);
  final limit = budget.monthlyLimit;
  final catMap = <String, double>{};
  for (final e in expenses)
    catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
  final topCat = catMap.entries.isEmpty
      ? null
      : catMap.entries.reduce((a, b) => a.value > b.value ? a : b);

  final cards = <InsightCard>[];

  // Budget insight
  if (limit > 0) {
    final pct = total / limit;
    if (pct > 0.9)
      cards.add(
        InsightCard(
          'Budget Alert',
          '${(pct * 100).toInt()}% of budget used — slow down!',
          '🚨',
          'alert',
          pct,
        ),
      );
    else if (pct > 0.6)
      cards.add(
        InsightCard(
          'Budget Update',
          '${(pct * 100).toInt()}% used — on track',
          '📊',
          'info',
          pct,
        ),
      );
    else
      cards.add(
        InsightCard(
          'Budget Healthy',
          'Only ${(pct * 100).toInt()}% used. Keep it up!',
          '💚',
          'good',
          pct,
        ),
      );
  }

  // Forecast
  cards.add(
    InsightCard(
      'Next Month Forecast',
      forecast.message,
      '🔮',
      'forecast',
      forecast.predicted,
    ),
  );

  // Week-over-week
  final (thisW, lastW) = weekComp;
  if (lastW > 0) {
    final d = thisW - lastW;
    cards.add(
      InsightCard(
        d > 0 ? 'Spending Up' : 'Spending Down',
        d > 0
            ? 'Rs.${d.toStringAsFixed(0)} more than last week'
            : 'Rs.${(-d).toStringAsFixed(0)} less than last week 🎉',
        d > 0 ? '📈' : '📉',
        d > 0 ? 'warn' : 'good',
        d,
      ),
    );
  }

  // Top category tip
  if (topCat != null)
    cards.add(
      InsightCard(
        'Top Spend: ${topCat.key}',
        '${(topCat.value / total.clamp(1, double.infinity) * 100).toInt()}% of this month\'s spend',
        '🏆',
        'info',
        topCat.value,
      ),
    );

  // Pattern insights
  for (final p in patterns)
    cards.add(InsightCard(p.label, p.description, p.emoji, 'pattern', p.value));

  return cards;
});
