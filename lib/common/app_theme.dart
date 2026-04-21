import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
// indigo
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

  static const primaryColor = Color(0xFF10B981);
  static const Color darkGrey = Color(0xff4D4D4D);
  static const Color white = Color(0xFFFFFFFF);
  static const secondaryColor = Color(0xFF38BDF8);
  static const yellow = Color(0xFFF59E0B);
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
                ? const ColorScheme.dark(
                    primary: AppColors.primaryColor,
                    secondary: kAccent,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryColor,
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
            ? AppColors.primaryColor
            : (dark ? const Color(0xFF3A3A50) : Colors.white),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primaryColor.withOpacity(0.35)
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






// class AppColors {
//   // 🌿 Primary (Main brand)
//   static const primary = Color(0xFF10B981); // Green
//   static const primaryDark = Color(0xFF059669);

//   // 💰 Money states
//   static const income = Color(0xFF22C55E);
//   static const expense = Color(0xFFEF4444);
//   static const warning = Color(0xFFF59E0B);

//   // 🎨 UI Backgrounds
//   static const backgroundLight = Color(0xFFF8FAF9);
//   static const cardLight = Color(0xFFFFFFFF);

//   static const backgroundDark = Color(0xFF0B1411);
//   static const cardDark = Color(0xFF111C1A);

//   // 📝 Text
//   static const textPrimary = Color(0xFF0F172A);
//   static const textSecondary = Color(0xFF64748B);
// }