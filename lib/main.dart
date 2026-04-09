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
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Replace with your actual Supabase project values ─────────────────────────
// Dashboard → Settings → API → Project URL & anon key
const _supabaseUrl = 'https://rafrmkwgmogdeklthzds.supabase.co';
const _supabaseAnonKey = 'sb_publishable_-y06lzlmNsthl0DCtHBT4Q_35WGwIn1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase (must be first) ──────────────────────────────────────────────
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    // Deep-link redirect for email magic link fallback (optional)
    // authFlowType: AuthFlowType.pkce,
  );

  // ── Local storage ─────────────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budget');

  // ── Preferences ───────────────────────────────────────────────────────────
  await ThemeProvider.init();
  await LangProvider.init();

  // ── Ads + Notifications ───────────────────────────────────────────────────
  await AdService.init();
  await NotificationService.init();
  AdService.preloadInterstitial();
  AdService.preloadRewarded();

  // ── Onboarding flag ───────────────────────────────────────────────────────
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

        // Theme
        themeMode: themeMode,
        theme: buildTheme(false),
        darkTheme: buildTheme(true),

        // Localization
        locale: locale,
        supportedLocales: LangProvider.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,

          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: onboarded ? const HomeScreen() : const OnboardScreen(),
      ),
    ),
  );
}
