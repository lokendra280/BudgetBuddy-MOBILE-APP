import 'package:expensetracker/auth/ui/lock_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard_screen.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/lang_provider.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/common/wrapper/update_wrapper.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budget');

  // Ads + notifications
  await AdService.init();
  await NotificationService.init();
  AdService.preloadInterstitial();
  AdService.preloadRewarded();

  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;

  runApp(SpendSenseApp(onboarded: onboarded));
}

class SpendSenseApp extends StatelessWidget {
  final bool onboarded;
  const SpendSenseApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeProvider.notifier,
    builder: (_, themeMode, __) => ValueListenableBuilder<Locale>(
      valueListenable: LangProvider.notifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'SpendSense',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: buildTheme(false),
        darkTheme: buildTheme(true),
        locale: locale,
        supportedLocales: LangProvider.supported,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: UpdateWrapper(
          child: LockScreen(
            child: onboarded ? const HomeScreen() : const OnboardScreen(),
          ),
        ),
      ),
    ),
  );
}
