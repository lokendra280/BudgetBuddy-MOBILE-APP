import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard_screen.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/lang_provider.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budget');

  // Theme + Language (load before runApp so first frame is correct)
  await ThemeProvider.init();
  await LangProvider.init();

  // Services
  await AdService.init();
  await NotificationService.init();
  AdService.preloadInterstitial();
  AdService.preloadRewarded();

  // Check if user has completed onboarding
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;

  runApp(SpendSenseApp(onboarded: onboarded));
}

class SpendSenseApp extends StatelessWidget {
  final bool onboarded;
  const SpendSenseApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.notifier,
      builder: (_, themeMode, __) => ValueListenableBuilder<Locale>(
        valueListenable: LangProvider.notifier,
        builder: (_, locale, __) => MaterialApp(
          title: 'SpendSense',
          debugShowCheckedModeBanner: false,

          // ── Theme ──────────────────────────────────────────────────────────
          themeMode: themeMode,
          theme: buildTheme(false),
          darkTheme: buildTheme(true),

          // ── Localization ───────────────────────────────────────────────────
          locale: locale,
          supportedLocales: LangProvider.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Routing ────────────────────────────────────────────────────────
          home: onboarded ? const HomeScreen() : const OnboardScreen(),
        ),
      ),
    );
  }
}
