import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const kBg = Color(0xFF090912);
const kSurface = Color(0xFF111120);
const kCard = Color(0xFF16162A);
const kBorder = Color(0xFF1E1E38);
const kPrimary = Color(0xFF7B6EF6);
const kAccent = Color(0xFFFF6B81);
const kGreen = Color(0xFF34D399);
const kAmber = Color(0xFFFBBF24);
const kTextMuted = Color(0xFF5A5A7A);
const kTextSub = Color(0xFF8A8AAA);

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

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    colorScheme: const ColorScheme.dark(
      primary: kPrimary,
      secondary: kAccent,
      surface: kSurface,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
