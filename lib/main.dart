import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/services/premium_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
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

  await ThemeProvider.init();
  await PremiumService.init();
  await AdService.init();
  await NotificationService.init();

  if (!PremiumService.isPremium) {
    AdService.preloadInterstitial();
    AdService.preloadRewarded();
  }

  runApp(const SpendSenseApp());
}

class SpendSenseApp extends StatelessWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeProvider.notifier,
    builder: (_, mode, __) => MaterialApp(
      title: 'SpendSense',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildTheme(false), // light
      darkTheme: buildTheme(true), // dark
      home: const HomeScreen(),
    ),
  );
}
