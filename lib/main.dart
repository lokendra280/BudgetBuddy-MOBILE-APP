import 'dart:async';
import 'dart:isolate';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/common/theme_provider.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/pages/bill_reminder_screen.dart';
import 'package:budgetBuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetBuddy/features/expense/services/category_services.dart';
import 'package:budgetBuddy/features/expense/services/hive_migrate_service.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:budgetBuddy/features/splash/ui/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _lastRestartMs = 0;

// ── HomeWidget interactivity callback (must be top-level) ──────────────────
@pragma('vm:entry-point')
Future<void> _homeWidgetInteractivityCallback(Uri? uri) async {
  // This runs in a background isolate — must initialize dependencies manually
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init(); // reinitialize Hive in this isolate

  // Navigate to app via NavigationService
  NavigationService.navigationKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DashboardPage()),
    (_) => false,
  );
}

Future<void> _init() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  FlutterNativeSplash.remove();

  await Future.delayed(const Duration(milliseconds: 500));
  await loadPrefsBeforeRunApp();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await HiveMigrationService.initSafely();
  await AdService.init();
  await HiveStorage.init();

  // Sync currency from SharedPreferences into Hive BEFORE runApp
  final savedCurrency = await ExpenseNotifier.loadCurrency();
  final budgetBox = Hive.box<Budget>('budget');
  if (budgetBox.isNotEmpty) {
    final old = budgetBox.getAt(0)!;
    if (old.currency != savedCurrency) {
      final updated = Budget(
        monthlyLimit: old.monthlyLimit,
        streakDays: old.streakDays,
        lastActiveDate: old.lastActiveDate,
        referralCode: old.referralCode,
        referralCount: old.referralCount,
        currency: savedCurrency,
      );
      await budgetBox.clear();
      await budgetBox.add(updated);
    }
  }

  await NotificationService.init();
  await NotificationService.scheduleDailyReminder();
  await CategoryService.init();

  // ── HomeWidget setup ────────────────────────────────────────────────────
  // registerInteractivityCallback replaces the deprecated registerBackgroundCallback
  await HomeWidget.registerInteractivityCallback(
    _homeWidgetInteractivityCallback,
  );

  // Push current budget data to widget on every app launch
  await _syncWidgetData();
}

/// Reads current month's expenses + budget from Hive and pushes to widget
Future<void> _syncWidgetData() async {
  try {
    final budgetBox = Hive.box<Budget>('budget');
    if (budgetBox.isEmpty) return;

    final budget = budgetBox.getAt(0)!;
    final expenseBox = Hive.box<Expense>('expenses');
    final now = DateTime.now();

    final monthlySpent = expenseBox.values
        .where(
          (e) =>
              e.date.month == now.month &&
              e.date.year == now.year &&
              e.isIncome, // adjust to your Expense model
        )
        .fold(0.0, (sum, e) => sum + e.amount);

    final remaining = budget.monthlyLimit - monthlySpent;

    await HomeWidget.saveWidgetData<String>('currency', budget.currency);
    await HomeWidget.saveWidgetData<double>('total_spent', monthlySpent);
    await HomeWidget.saveWidgetData<double>(
      'monthly_limit',
      budget.monthlyLimit,
    );
    await HomeWidget.saveWidgetData<double>('remaining', remaining);
    await HomeWidget.saveWidgetData<String>(
      'last_updated',
      '${now.day}/${now.month}/${now.year}',
    );
    await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
  } catch (e) {
    debugPrint('[Widget] Failed to sync widget data: $e');
  }
}

void _scheduleRestart() {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - _lastRestartMs < 5000) return;
  _lastRestartMs = now;
  Future.delayed(const Duration(seconds: 3), () {
    NavigationService.navigationKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  });
}

void main() {
  runZonedGuarded(
    () async {
      await _init();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
        _scheduleRestart();
      };

      Isolate.current.addErrorListener(
        RawReceivePort((pair) {
          debugPrint('[IsolateError] ${(pair as List)[0]}');
          _scheduleRestart();
        }).sendPort,
      );

      runApp(const ProviderScope(child: SpendSenseApp()));
    },
    (error, stack) {
      debugPrint('[ZonedError] $error\n$stack');
      _scheduleRestart();
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class SpendSenseApp extends ConsumerWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: NavigationService.navigationKey,
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      locale: locale,
      supportedLocales: LocaleNotifier.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/home': (_) => const DashboardPage(),
        '/bills': (_) => const BillReminderScreen(),
      },
      home: const SplashScreen(),
      builder: (ctx, child) {
        ErrorWidget.builder = (details) =>
            _ErrorView(error: details.exceptionAsString(), onRestart: () {});
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRestart;
  const _ErrorView({required this.error, required this.onRestart});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F2F8),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kAccent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: kAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops, something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F0F1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your data is safe — tap below to restart.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF606080),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Restart App',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (!kReleaseMode) ...[
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9090B0),
                  fontFamily: 'monospace',
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// flutter build apk --split-per-abi
