import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider {
  static final notifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static const _key = 'theme_mode';

  static bool get isDark => notifier.value == ThemeMode.dark;

  // Call once at app start
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_key);
    if (saved == 'light')
      notifier.value = ThemeMode.light;
    else if (saved == 'system')
      notifier.value = ThemeMode.system;
    else
      notifier.value = ThemeMode.dark; // default
  }

  static Future<void> setMode(ThemeMode mode) async {
    notifier.value = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, mode.name); // 'dark' | 'light' | 'system'
  }

  static void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
