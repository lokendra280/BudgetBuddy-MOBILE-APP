import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_transaction.dart';
import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:budgetBuddy/features/home/services/sync_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Display model ─────────────────────────────────────────────────
class SavingsGoal {
  final String id, name, emoji;
  final double target, saved, dailySuggestion;
  final int daysLeft;
  final List<GoalTransaction> transactions;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.dailySuggestion,
    required this.daysLeft,
    required this.transactions,
  });

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0;
}

SavingsGoal _toGoal(GoalEntry g) {
  final b = AiService.smartBudget();
  final available = b.income > 0
      ? (b.income - b.currentSpend).clamp(0.0, b.income) / 30
      : 0.0;
  return SavingsGoal(
    id: g.id,
    name: g.name,
    emoji: g.emoji,
    target: g.target,
    saved: g.saved,
    daysLeft: g.daysLeft,
    dailySuggestion: available,
    transactions: g.transactions,
  );
}

// ── Notifier ──────────────────────────────────────────────────────
class GoalsNotifier extends Notifier<List<SavingsGoal>> {
  @override
  List<SavingsGoal> build() => _read();

  List<SavingsGoal> _read() => HiveStorage.allGoals().map(_toGoal).toList();

  Future<void> add(
    String name,
    String emoji,
    double target,
    int daysLeft,
  ) async {
    await HiveStorage.addGoal(
      name: name,
      emoji: emoji,
      target: target,
      daysLeft: daysLeft,
    );
    state = _read();
  }

  Future<void> addAmount(String id, double amount) async {
    await HiveStorage.addToGoal(id, amount);

    state = _read();

    final goal = state.firstWhere((g) => g.id == id);

    if (goal.progress >= 1.0) {
      await NotificationService.showGoalCompletedNotification(
        goalName: goal.name,
      );
    }
  }

  Future<void> delete(String id) async {
    await HiveStorage.deleteGoal(id);
    state = _read();
  }

  Future<void> pullRemote() async {
    await SyncService.pullGoals();
    state = _read();
  }
}

final goalsNotifierProvider =
    NotifierProvider<GoalsNotifier, List<SavingsGoal>>(GoalsNotifier.new);
