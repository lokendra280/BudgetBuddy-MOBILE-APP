import 'package:hive_flutter/hive_flutter.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category;
  @HiveField(4)
  DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  double monthlyLimit;
  @HiveField(1)
  int streakDays;
  @HiveField(2)
  String lastActiveDate;

  Budget({
    this.monthlyLimit = 10000,
    this.streakDays = 0,
    this.lastActiveDate = '',
  });
}
