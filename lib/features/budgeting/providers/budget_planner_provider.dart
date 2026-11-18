import 'package:budgetbuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetbuddy/features/budgeting/models/budget_plan.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
// kCategories — same import HomeScreen uses. Adjust if it lives elsewhere.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ⚠️ Adjust this path to wherever your HiveStorage class lives.

// ─────────────────────────────────────────────────────────────────────────────
// Category budgets (source of truth)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryBudgetsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    // Same pattern as ExpenseNotifier: react to any change in the box
    // (local edits, sync pulls, account wipe).
    final listenable = HiveStorage.categoryBudgets.listenable();
    void onChange() => state = HiveStorage.allCategoryBudgets();
    listenable.addListener(onChange);
    ref.onDispose(() => listenable.removeListener(onChange));

    // Box is opened in HiveStorage.init(), so this is synchronous —
    // no empty first frame.
    return HiveStorage.allCategoryBudgets();
  }

  Future<void> setBudget(String category, double limit) =>
      HiveStorage.saveCategoryBudget(category, limit);

  Future<void> remove(String category) =>
      HiveStorage.deleteCategoryBudget(category);
}

final categoryBudgetsProvider =
    NotifierProvider<CategoryBudgetsNotifier, Map<String, double>>(
      CategoryBudgetsNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Derived — all follow selectedMonthProvider, like the rest of the app
// ─────────────────────────────────────────────────────────────────────────────

final budgetOverviewProvider = Provider<BudgetOverview>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final budgets = ref.watch(categoryBudgetsProvider);

  return BudgetOverview(
    month: month,
    limit: ref.watch(budgetProvider).monthlyLimit,
    spent: ref.watch(monthTotalExpenseProvider),
    assigned: budgets.values.fold(0.0, (a, b) => a + b),
    categoryCount: budgets.length,
    daysLeft: _daysLeftIn(month),
  );
});

/// Category budgets with this month's spending, most at-risk first.
final categoryBudgetStatusesProvider = Provider<List<CategoryBudgetStatus>>((
  ref,
) {
  final budgets = ref.watch(categoryBudgetsProvider);
  final spent = ref.watch(byCategoryProvider);

  return budgets.entries
      .map(
        (e) => CategoryBudgetStatus(
          category: e.key,
          limit: e.value,
          spent: spent[e.key] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.ratio.compareTo(a.ratio));
});

/// Categories with spending this month but no budget yet.
final unbudgetedSpendProvider = Provider<Map<String, double>>((ref) {
  final budgets = ref.watch(categoryBudgetsProvider);
  final spent = ref.watch(byCategoryProvider);
  return Map.fromEntries(
    spent.entries.where((e) => !budgets.containsKey(e.key)),
  );
});

/// Categories the user can still add a budget for.
final availableBudgetCategoriesProvider = Provider<List<String>>((ref) {
  final budgets = ref.watch(categoryBudgetsProvider);
  final spent = ref.watch(byCategoryProvider);
  return {
    ...kCategories,
    ...spent.keys,
  }.where((c) => !budgets.containsKey(c)).toList();
});

final budgetSetupStepProvider = Provider<BudgetSetupStep>((ref) {
  final overview = ref.watch(budgetOverviewProvider);
  if (!overview.hasLimit) return BudgetSetupStep.setLimit;
  if (overview.categoryCount == 0) return BudgetSetupStep.planCategories;
  return BudgetSetupStep.done;
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Days left including today for the current month,
/// 0 for past months, and the full month for future ones.
int _daysLeftIn(DateTime month) {
  final now = DateTime.now();
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final selected = DateTime(month.year, month.month);
  final current = DateTime(now.year, now.month);

  if (selected.isBefore(current)) return 0;
  if (selected.isAfter(current)) return daysInMonth;
  return daysInMonth - now.day + 1;
}
