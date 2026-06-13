import 'package:hive_flutter/hive_flutter.dart';

part 'goals_transaction.g.dart';

@HiveType(typeId: 4)
class GoalTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  GoalTransaction({required this.id, required this.amount, required this.date});
}
