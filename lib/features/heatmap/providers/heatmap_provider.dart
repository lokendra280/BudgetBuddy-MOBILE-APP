import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Daily spend map — key is Date(y,m,d), value is total spend
final heatmapProvider = Provider<Map<DateTime, double>>((ref) {
  final map = <DateTime, double>{};
  for (final e in ref.watch(expenseProvider).all) {
    if (e.isIncome) continue;
    final k = DateTime(e.date.year, e.date.month, e.date.day);
    map[k] = (map[k] ?? 0) + e.amount;
  }
  return map;
});

// Top 5 spend days this month
final topSpendDaysProvider = Provider<List<MapEntry<DateTime, double>>>((ref) {
  final now = DateTime.now();
  final entries =
      ref
          .watch(heatmapProvider)
          .entries
          .where((e) => e.key.month == now.month && e.key.year == now.year)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(5).toList();
});
