import 'package:expensetracker/features/ai_screen/services/ai_services.dart';
import 'package:expensetracker/common/hive_storages/hive_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SavingsGoal — pure display model (no Hive coupling in UI layer)
// ─────────────────────────────────────────────────────────────────────────────
class SavingsGoal {
  final String id, name, emoji;
  final double target, saved, dailySuggestion;
  final int daysLeft;
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.dailySuggestion,
    required this.daysLeft,
  });
  double get progress => target > 0 ? (saved / target).clamp(0, 1) : 0;
}

// Map GoalEntry → SavingsGoal
SavingsGoal _toGoal(GoalEntry g) {
  final remaining = (g.target - g.saved).clamp(0.0, g.target);
  final dailySuggest = g.daysLeft > 0 ? remaining / g.daysLeft : 0.0;
  return SavingsGoal(
    id: g.id,
    name: g.name,
    emoji: g.emoji,
    target: g.target,
    saved: g.saved,
    dailySuggestion: dailySuggest,
    daysLeft: g.daysLeft,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GOALS NOTIFIER
//  • build()      — reads from Hive via HiveStorage (instant, offline)
//  • add()        — writes Hive first, then background Supabase sync
//  • addAmount()  — updates Hive first, then background Supabase sync
//  • delete()     — removes from Hive first, then background Supabase delete
//  • pullRemote() — merges Supabase → Hive (called on login / app start)
// ─────────────────────────────────────────────────────────────────────────────
class GoalsNotifier extends Notifier<List<SavingsGoal>> {
  @override
  List<SavingsGoal> build() {
    // Listen to Hive box → rebuild whenever any goal changes
    HiveStorage.goals.listenable().addListener(_refresh);
    return _read();
  }

  List<SavingsGoal> _read() =>
      HiveStorage.allGoals().cast<GoalEntry>().map(_toGoal).toList();

  void _refresh() => state = _read();

  /// Step 1: save to Hive → UI updates instantly
  /// Step 2: if online, sync to Supabase in background
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
    // state auto-updates via _refresh() from listenable
  }

  Future<void> addAmount(String id, double amount) async {
    await HiveStorage.addToGoal(id, amount);
  }

  Future<void> delete(String id) async {
    await HiveStorage.deleteGoal(id);
  }

  /// Call on login or app start to pull cloud goals → Hive
  Future<void> pullRemote() async {
    await HiveStorage.pullGoalsFromSupabase();
  }
}

final goalsNotifierProvider =
    NotifierProvider<GoalsNotifier, List<SavingsGoal>>(GoalsNotifier.new);
