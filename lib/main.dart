import 'dart:async';
import 'dart:isolate';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/hive_storages/hive_storage.dart';
import 'package:expensetracker/common/navigation_service.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/features/expense/services/category_services.dart';
import 'package:expensetracker/features/expense/services/hive_migrate_service.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:expensetracker/features/splash/ui/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _lastRestartMs = 0;

Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadPrefsBeforeRunApp();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await HiveMigrationService.initSafely();
  await AdService.init();
  await HiveStorage.init();
  await NotificationService.init();
  AdService.preloadInterstitial();
  AdService.preloadRewarded();
  await CategoryService.init();
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
    // Read theme + locale from Riverpod providers
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: NavigationService.navigationKey,
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(false), // light
      darkTheme: buildTheme(true), // dark
      locale: locale,
      supportedLocales: LocaleNotifier.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return const Locale('en');
        for (final s in supported) {
          if (s.languageCode == deviceLocale.languageCode) return s;
        }
        return const Locale('en');
      },
      home: const SplashScreen(),
      builder: (ctx, child) {
        ErrorWidget.builder = (details) => _ErrorView(
          error: details.exceptionAsString(),
          onRestart: _scheduleRestart,
        );
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

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
