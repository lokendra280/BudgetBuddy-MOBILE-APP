import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Shared accents (same in both modes) ──────────────────────────────────────
const kPrimary = Color(0xFF7B6EF6);
const kAccent = Color(0xFFFF6B81);
const kGreen = Color(0xFF34D399);
const kAmber = Color(0xFFFBBF24);

final kCatColors = [
  const Color(0xFF7B6EF6),
  const Color(0xFFFF6B81),
  const Color(0xFF34D399),
  const Color(0xFFFBBF24),
  const Color(0xFF60A5FA),
  const Color(0xFFFC8181),
  const Color(0xFF34D399),
  const Color(0xFFF472B6),
];

const kCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Health',
  'Bills',
  'Entertainment',
  'Other',
];
const kCatEmoji = {
  'Food': '🍜',
  'Transport': '🚗',
  'Shopping': '🛍',
  'Health': '💊',
  'Bills': '⚡',
  'Entertainment': '🎬',
  'Other': '📦',
};

// ── AppColors — resolved at runtime ──────────────────────────────────────────
class AppColors {
  final Color bg, surface, card, border, textMuted, textSub;
  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.textMuted,
    required this.textSub,
  });

  static const dark = AppColors(
    bg: Color(0xFF090912),
    surface: Color(0xFF111120),
    card: Color(0xFF16162A),
    border: Color(0xFF1E1E38),
    textMuted: Color(0xFF5A5A7A),
    textSub: Color(0xFF8A8AAA),
  );

  static const light = AppColors(
    bg: Color(0xFFF4F4FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4EF),
    textMuted: Color(0xFF9898B0),
    textSub: Color(0xFF6B6B85),
  );
}

// ── Convenience extension ─────────────────────────────────────────────────────
extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ── Theme builders ────────────────────────────────────────────────────────────
ThemeData buildTheme(bool dark) {
  final c = dark ? AppColors.dark : AppColors.light;
  final base = dark ? ThemeData.dark() : ThemeData.light();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ),
  );

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    colorScheme:
        (dark
                ? const ColorScheme.dark(primary: kPrimary, secondary: kAccent)
                : const ColorScheme.light(
                    primary: kPrimary,
                    secondary: kAccent,
                  ))
            .copyWith(surface: c.surface),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: dark ? Colors.white : const Color(0xFF1A1A2E),
      displayColor: dark ? Colors.white : const Color(0xFF1A1A2E),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      elevation: 0,
      foregroundColor: dark ? Colors.white : const Color(0xFF1A1A2E),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kPrimary
            : (dark ? const Color(0xFF3A3A5A) : Colors.white),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kPrimary.withOpacity(0.4)
            : (dark ? const Color(0xFF2A2A40) : const Color(0xFFDDDDEE)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
