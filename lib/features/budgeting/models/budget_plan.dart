/// How healthy a budget is. Drives colors, icons and messages in the UI.
enum BudgetHealth { notSet, onTrack, warning, over }

/// Which setup step the user is on. Drives the prompt card on Home.
enum BudgetSetupStep {
  /// No monthly limit yet → "Set your monthly budget".
  setLimit,

  /// Limit set, but no category budgets → "Plan your budget".
  planCategories,

  /// Everything set → show a compact status card.
  done,
}

/// Warning starts once 80% of a limit is used.
const kBudgetWarningRatio = 0.8;

BudgetHealth budgetHealthFor({required double spent, required double limit}) {
  if (limit <= 0) return BudgetHealth.notSet;
  final ratio = spent / limit;
  if (ratio > 1) return BudgetHealth.over;
  if (ratio >= kBudgetWarningRatio) return BudgetHealth.warning;
  return BudgetHealth.onTrack;
}

/// One category's budget compared with what was spent in it this month.
class CategoryBudgetStatus {
  final String category;
  final double limit;
  final double spent;

  const CategoryBudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get ratio => limit <= 0 ? 0 : spent / limit;
  double get remaining => limit - spent;
  bool get isOver => spent > limit;
  BudgetHealth get health => budgetHealthFor(spent: spent, limit: limit);
}

/// The whole month at a glance.
class BudgetOverview {
  final DateTime month;
  final double limit;
  final double spent;

  /// Sum of all category budgets.
  final double assigned;
  final int categoryCount;
  final int daysLeft;

  const BudgetOverview({
    required this.month,
    required this.limit,
    required this.spent,
    required this.assigned,
    required this.categoryCount,
    required this.daysLeft,
  });

  bool get hasLimit => limit > 0;
  double get remaining => limit - spent;
  double get ratio => hasLimit ? spent / limit : 0;
  double get unassigned => limit - assigned;
  bool get overPlanned => hasLimit && assigned > limit;

  /// How much can be spent per day for the rest of the month.
  double get perDayAllowance =>
      daysLeft > 0 && remaining > 0 ? remaining / daysLeft : 0;

  BudgetHealth get health => budgetHealthFor(spent: spent, limit: limit);
}
