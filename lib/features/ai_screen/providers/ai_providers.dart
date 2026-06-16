import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── AI providers ──────────────────────────────────────────────────────────────
// fmtProvider and symbolProvider are intentionally NOT defined here.
// Import them from expense_provider.dart — they watch currencyProvider
// and rebuild reactively whenever the user changes currency in Settings.

final smartBudgetProvider = Provider((ref) => AiService.smartBudget());
final healthScoreProvider = Provider((ref) => AiService.healthScore());
final burnRateProvider = Provider((ref) => AiService.burnRate());
final predictionProvider = Provider((ref) => AiService.predict());
final alertsProvider = Provider((ref) => AiService.alerts());
final aiSuggestionsProvider = Provider((ref) => AiService.suggestions());
final subscriptionsProvider = Provider(
  (ref) => AiService.detectSubscriptions(),
);
final recurringProvider = Provider((ref) => AiService.detectRecurring());
final coachTipsProvider = Provider((ref) => AiService.coachTips());
final incomeHistoryProvider = Provider((ref) => AiService.incomeHistory());
final incomeGrowthProvider = Provider((ref) => AiService.incomeGrowthPercent());
final billHealthProvider = Provider((ref) => AiService.billHealthSummary());
final goalInsightsProvider = Provider((ref) => AiService.goalInsights());
final cashFlowProvider = Provider((ref) => AiService.cashFlowForecast());
