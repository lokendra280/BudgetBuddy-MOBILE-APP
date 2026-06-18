import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Pre-loaded prefs — populated in main() BEFORE runApp ─────────────────────
// This guarantees both ThemeNotifier and LocaleNotifier read the correct saved
// value on the very first frame, with no async gap and no flash of defaults.
late SharedPreferences _prefs;

Future<void> loadPrefsBeforeRunApp() async {
  _prefs = await SharedPreferences.getInstance();
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
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

  // ── Supported locales — keep in sync with kLanguages in app_catalogue.dart ─
  static const supported = [
    Locale('en'),
    Locale('ne'),
    Locale('hi'),
    Locale('pt'), // ← Portuguese (BR)
    Locale('zh'), // ← Chinese (Simplified)
  ];

  // (nativeName, englishName) pairs — used in settings language picker
  static const labels = {
    'en': ('English', 'English (US)'),
    'ne': ('नेपाली', 'Nepali'),
    'hi': ('हिन्दी', 'Hindi'),
    'pt': ('Português', 'Portuguese (BR)'),
    'zh': ('中文', 'Chinese (Simplified)'),
  };

  // Country flags — used next to language names in UI
  static const flags = {
    'en': '🇺🇸',
    'ne': '🇳🇵',
    'hi': '🇮🇳',
    'pt': '🇧🇷',
    'zh': '🇨🇳',
  };

  // Default currency suggestion per locale —
  // mirrors LangOption.defaultCurrency in app_catalogue.dart
  static const defaultCurrency = {
    'en': 'USD',
    'ne': 'NPR',
    'hi': 'INR',
    'pt': 'BRL',
    'zh': 'CNY',
  };

  @override
  Locale build() {
    // Reads directly from pre-loaded prefs → correct locale on frame 1.
    // Falls back to 'en' if nothing saved yet.
    final code = _prefs.getString(_key) ?? 'en';
    // Safety: if a stored code is no longer supported, fall back to 'en'
    final isSupported = supported.any((l) => l.languageCode == code);
    return Locale(isSupported ? code : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_key, locale.languageCode);
  }

  // Convenience getter used by LanguageScreen / settings
  String get currentCode => state.languageCode;

  // Returns the suggested currency code for the current locale
  String get suggestedCurrency => defaultCurrency[state.languageCode] ?? 'USD';
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
