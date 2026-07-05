import 'dart:async';
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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _init() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  FlutterNativeSplash.remove();

  await Future.delayed(const Duration(milliseconds: 500));
  await loadPrefsBeforeRunApp();

  await dotenv.load(fileName: '.env');

  // 1. Firebase first — required before any Firebase.* usage
  await Firebase.initializeApp();

  // 2. Crashlytics — only after Firebase is ready
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // 3. Everything else
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await HiveMigrationService.initSafely();
  await AdService.init();
  await HiveStorage.init();

  // Sync currency from SharedPreferences into Hive
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
  await NotificationService.requestPermission();
  await CategoryService.init();
}

void main() {
  runZonedGuarded(
    () async {
      await _init();

      // Wire error handlers after Firebase is ready
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      runApp(const ProviderScope(child: SpendSenseApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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
        ErrorWidget.builder = (details) {
          // Log to Crashlytics instead of crashing silently
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          return _ErrorView(
            error: details.exceptionAsString(),
            onRestart: () {
              NavigationService.navigationKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
              );
            },
          );
        };
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
                style: const TextStyle(fontSize: 10, color: Color(0xFF9090B0)),
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
