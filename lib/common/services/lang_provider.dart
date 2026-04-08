import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangProvider {
  static final notifier = ValueNotifier<Locale>(const Locale('en'));
  static const _key = 'locale';

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_key) ?? 'en';
    notifier.value = Locale(code);
  }

  static Future<void> set(Locale locale) async {
    notifier.value = locale;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, locale.languageCode);
  }

  static bool get isFirstLaunch {
    // Checked synchronously after init — null means never set
    return notifier.value.languageCode == 'en'; // refined in onboarding
  }

  static const supported = [
    Locale('en'), // English
    Locale('ne'), // Nepali
    Locale('hi'), // Hindi
  ];

  static const labels = {
    'en': ('English', 'English'),
    'ne': ('नेपाली', 'Nepali'),
    'hi': ('हिन्दी', 'Hindi'),
  };

  static const flags = {'en': '🇬🇧', 'ne': '🇳🇵', 'hi': '🇮🇳'};
}
