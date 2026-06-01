import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smartBudgetProvider = Provider<SmartBudget>((ref) {
  ref.watch(expenseProvider);
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
