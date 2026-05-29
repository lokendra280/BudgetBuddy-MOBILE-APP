import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Forecast {
  final double predicted, avg3Month, confidence;
  final String message;
  const Forecast(this.predicted, this.avg3Month, this.confidence, this.message);
}

final forecastProvider = Provider<Forecast>((ref) {
  final all = ref.watch(expenseProvider).all;
  final now = DateTime.now();

  double monthTotal(int m, int y) => all
      .where((e) => !e.isIncome && e.date.month == m && e.date.year == y)
      .fold(0.0, (s, e) => s + e.amount);

  // Last 3 full months average
  final months = List.generate(3, (i) {
    final mo = now.month - i - 1;
    return monthTotal(
      mo <= 0 ? mo + 12 : mo,
      mo <= 0 ? now.year - 1 : now.year,
    );
  });
  final avg = months.fold(0.0, (s, v) => s + v) / 3;

  // Project current month
  final daysIn = DateTime(now.year, now.month + 1, 0).day;
  final soFar = monthTotal(now.month, now.year);
  final project = now.day > 0 ? soFar / now.day * daysIn : avg;
  final pred = avg * 0.5 + project * 0.5;
  final conf = avg > 0
      ? (1 - (project - avg).abs() / avg).clamp(0.3, 0.95)
      : 0.5;

  final msg = pred > avg * 1.15
      ? 'Tracking above average — watch your spending 📈'
      : pred < avg * 0.85
      ? 'On track for a low-spend month 🎉'
      : 'Spending looks stable this month 😌';

  return Forecast(pred, avg, conf, msg);
});

// Month-by-month history for chart (last 6 months)
final monthlyHistoryProvider = Provider<List<({String label, double amount})>>((
  ref,
) {
  final all = ref.watch(expenseProvider).all;
  final now = DateTime.now();
  return List.generate(6, (i) {
    final mo = now.month - (5 - i);
    final y = mo <= 0 ? now.year - 1 : now.year;
    final m = mo <= 0 ? mo + 12 : mo;
    final total = all
        .where((e) => !e.isIncome && e.date.month == m && e.date.year == y)
        .fold(0.0, (s, e) => s + e.amount);
    final label = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][m - 1];
    return (label: label, amount: total);
  });
});
