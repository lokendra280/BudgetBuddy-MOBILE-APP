import 'package:expensetracker/ai_screen/services/ai_services.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── All AI features as derived providers ─────────────────────────────────────
// Each provider reads from expenseProvider, so they auto-update
// whenever expenses change.

final smartBudgetProvider = Provider<SmartBudget>((ref) {
  ref.watch(expenseProvider); // re-compute when expenses change
  return AiService.smartBudget();
});

final healthScoreProvider = Provider<FinancialHealthScore>((ref) {
  ref.watch(expenseProvider);
  return AiService.healthScore();
});

final burnRateProvider = Provider<BurnRate>((ref) {
  ref.watch(expenseProvider);
  return AiService.burnRate();
});

final predictionProvider = Provider<ExpensePrediction>((ref) {
  ref.watch(expenseProvider);
  return AiService.predict();
});

final goalsProvider = Provider<List<SavingsGoal>>((ref) {
  ref.watch(expenseProvider);
  return AiService.goals();
});

final alertsProvider = Provider<List<SmartAlert>>((ref) {
  ref.watch(expenseProvider);
  return AiService.alerts();
});

final aiSuggestionsProvider = Provider<List<AiSuggestion>>((ref) {
  ref.watch(expenseProvider);
  return AiService.suggestions();
});

final coachTipsProvider = Provider<List<CoachTip>>((ref) {
  ref.watch(expenseProvider);
  return AiService.coachTips();
});

final recurringProvider = Provider<List<RecurringExpense>>((ref) {
  ref.watch(expenseProvider);
  return AiService.detectRecurring();
});

final subscriptionsProvider = Provider<List<SubscriptionItem>>((ref) {
  ref.watch(expenseProvider);
  return AiService.detectSubscriptions();
});

final incomeHistoryProvider = Provider<Map<String, double>>((ref) {
  ref.watch(expenseProvider);
  return AiService.incomeHistory();
});

final incomeGrowthProvider = Provider<double>((ref) {
  ref.watch(expenseProvider);
  return AiService.incomeGrowthPercent();
});

// ── Goals CRUD notifier ───────────────────────────────────────────────────────
class GoalsNotifier extends Notifier<List<SavingsGoal>> {
  @override
  List<SavingsGoal> build() => AiService.goals();

  Future<void> add(
    String name,
    String emoji,
    double target,
    int daysLeft,
  ) async {
    await AiService.addGoal(name, emoji, target, daysLeft);
    state = AiService.goals();
  }

  Future<void> addAmount(String id, double amount) async {
    await AiService.addToGoal(id, amount);
    state = AiService.goals();
  }

  Future<void> delete(String id) async {
    await AiService.deleteGoal(id);
    state = AiService.goals();
  }
}

final goalsNotifierProvider =
    NotifierProvider<GoalsNotifier, List<SavingsGoal>>(GoalsNotifier.new);
