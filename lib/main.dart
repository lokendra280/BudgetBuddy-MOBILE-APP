import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budget');
  await NotificationService.init();
  runApp(const SpendSenseApp());
}

class SpendSenseApp extends StatelessWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SpendSense',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const HomeScreen(),
  );
}
