import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF6366F1); // indigo
const kAccent = Color(0xFFF43F5E); // rose
const kGreen = Color(0xFF10B981); // emerald
const kAmber = Color(0xFFF59E0B); // amber
const kBlue = Color(0xFF3B82F6); // blue

final kCatColors = [
  const Color(0xFF6366F1),
  const Color(0xFFF43F5E),
  const Color(0xFF10B981),
  const Color(0xFFF59E0B),
  const Color(0xFF3B82F6),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
  const Color(0xFF14B8A6),
];

// ── AppColors ─────────────────────────────────────────────────────────────────
class AppColors {
  final Color bg,
      surface,
      card,
      cardElevated,
      border,
      borderStrong,
      textMuted,
      textSub;
  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.borderStrong,
    required this.textMuted,
    required this.textSub,
  });

  static const dark = AppColors(
    bg: Color(0xFF0A0A0F),
    surface: Color(0xFF101018),
    card: Color(0xFF14141E),
    cardElevated: Color(0xFF1C1C2A),
    border: Color(0xFF1E1E30),
    borderStrong: Color(0xFF2A2A40),
    textMuted: Color(0xFF52526E),
    textSub: Color(0xFF8080A0),
  );

  static const light = AppColors(
    bg: Color(0xFFF1F2F8),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF8F8FF),
    border: Color(0xFFE8E8F0),
    borderStrong: Color(0xFFD0D0E0),
    textMuted: Color(0xFF9090B0),
    textSub: Color(0xFF606080),
  );
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F0F1A);
}

// ── Theme builder ─────────────────────────────────────────────────────────────
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
      bodyColor: dark ? Colors.white : const Color(0xFF0F0F1A),
      displayColor: dark ? Colors.white : const Color(0xFF0F0F1A),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      elevation: 0,
      foregroundColor: dark ? Colors.white : const Color(0xFF0F0F1A),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kPrimary
            : (dark ? const Color(0xFF3A3A50) : Colors.white),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kPrimary.withOpacity(0.35)
            : (dark ? const Color(0xFF252538) : const Color(0xFFDDDDEE)),
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
