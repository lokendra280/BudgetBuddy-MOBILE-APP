import 'package:expensetracker/features/expense/services/category_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = FutureProvider<List<AppCategory>>((ref) async {
  await CategoryService.init();
  return [
    ...CategoryService.expenseCategories,
    ...CategoryService.incomeCategories,
  ];
});

final expenseCatsProvider = Provider<List<AppCategory>>((ref) {
  return CategoryService.expenseCategories;
});

final incomeCatsProvider = Provider<List<AppCategory>>((ref) {
  return CategoryService.incomeCategories;
});

// ── Invalidate when switching income/expense toggle ───────────────────────────
final isIncomeModeProvider = StateProvider<bool>((ref) => false);

final activeCatsProvider = Provider<List<AppCategory>>((ref) {
  final isIncome = ref.watch(isIncomeModeProvider);
  return isIncome
      ? CategoryService.incomeCategories
      : CategoryService.expenseCategories;
});
