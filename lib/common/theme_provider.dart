import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

Future<void> loadPrefsBeforeRunApp() async {
  _prefs = await SharedPreferences.getInstance();
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Reads directly from pre-loaded prefs → correct value on frame 1
    final saved = _prefs.getString(_key);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'system') return ThemeMode.system;
    return ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }

  void toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

// ── Locale ────────────────────────────────────────────────────────────────────
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';
  static const supported = [Locale('en'), Locale('ne'), Locale('hi')];
  static const labels = {
    'en': ('English', 'English'),
    'ne': ('नेपाली', 'Nepali'),
    'hi': ('हिन्दी', 'Hindi'),
  };
  static const flags = {'en': '🇬🇧', 'ne': '🇳🇵', 'hi': '🇮🇳'};

  @override
  Locale build() {
    // Reads directly from pre-loaded prefs → correct locale on frame 1
    // FIX: Previously build() always returned Locale('en') and relied on
    // init() being called later from SplashScreen. That caused:
    //   1. A flash of English on every cold start
    //   2. App defaulting to English on hot restart (init() not re-called)
    //   3. Language reverting after app kill if init() hadn't run yet
    final code = _prefs.getString(_key) ?? 'en';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    // Save immediately — next cold start build() will read this value
    await _prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
