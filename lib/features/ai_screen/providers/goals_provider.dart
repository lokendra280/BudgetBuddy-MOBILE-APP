// import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
// import 'package:budgetBuddy/common/services/notification_service.dart';
// import 'package:budgetBuddy/features/ai_screen/services/goal_service.dart';
// import 'package:budgetBuddy/features/home/services/sync_services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class GoalsNotifier extends Notifier<List<SavingsGoal>> {
//   @override
//   List<SavingsGoal> build() => _read();

//   List<SavingsGoal> _read() => HiveStorage.allGoals().map(_toGoal).toList();

//   Future<void> add(
//     String name,
//     String emoji,
//     double target,
//     int daysLeft,
//   ) async {
//     await HiveStorage.addGoal(
//       name: name,
//       emoji: emoji,
//       target: target,
//       daysLeft: daysLeft,
//     );
//     state = _read();
//   }

//   Future<void> addAmount(String id, double amount) async {
//     await HiveStorage.addToGoal(id, amount);

//     state = _read();

//     final goal = state.firstWhere((g) => g.id == id);

//     if (goal.progress >= 1.0) {
//       await NotificationService.showGoalCompletedNotification(
//         goalName: goal.name,
//       );
//     }
//   }

//   Future<void> delete(String id) async {
//     await HiveStorage.deleteGoal(id);
//     state = _read();
//   }

//   Future<void> pullRemote() async {
//     await SyncService.pullGoals();
//     state = _read();
//   }
// }

// final goalsNotifierProvider =
//     NotifierProvider<GoalsNotifier, List<SavingsGoal>>(GoalsNotifier.new);
