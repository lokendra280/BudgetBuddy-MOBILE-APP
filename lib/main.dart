import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/hive_storages/hive_storage.dart';
import 'package:expensetracker/common/navigation_service.dart';
import 'package:expensetracker/common/providers/theme_provider.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/expense/services/category_services.dart';
import 'package:expensetracker/expense/services/hive_migrate_service.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:expensetracker/splash/ui/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await Hive.initFlutter();
  await HiveStorage.init();

  await HiveMigrationService.initSafely();
  await CategoryService.init();
  await AdService.init();
  await NotificationService.init();
  AdService.preloadInterstitial();
  AdService.preloadRewarded();

  runApp(ProviderScope(child: SpendSenseApp()));
}

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
      home: const SplashScreen(),
    );
  }
}
