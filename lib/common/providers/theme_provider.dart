import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() => ThemeMode.light; // default light

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_key);
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'light') state = ThemeMode.light;
    if (saved == 'system') state = ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, mode.name);
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
  Locale build() => const Locale('en');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_key) ?? 'en';
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
