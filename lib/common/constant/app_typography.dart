import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // ── Display ──────────────────────────────────────────────────────────────
  /// 32 px · w800 · Poppins · tight leading — hero numbers, splash titles
  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );
  static TextStyle get captionMuted => caption; // 10px Inter, no colour
  static TextStyle get labelMuted => labelSmall; // 11px Inter, no colour
  static TextStyle get bodySub => bodySmall; // 13px Inter, no colour
  // ── Headings ─────────────────────────────────────────────────────────────
  /// 26 px · w800 · Poppins — screen titles
  ///

  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// 20 px · w700 · Poppins — section headers
  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// 17 px · w700 · Poppins — card titles, dialog headers
  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 15 px · w600 · Poppins — sub-section labels
  static TextStyle get h4 => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  /// 15 px · w400 · Inter — primary reading text
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// 15 px · w500 · Inter — slightly emphasised body
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);

  /// 13 px · w400 · Inter — secondary / supporting text
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);

  // ── Labels ────────────────────────────────────────────────────────────────
  /// 13 px · w600 · Inter — list item primaries, row titles
  static TextStyle get labelLarge =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4);

  /// 11 px · w500 · Inter — captions, secondary row text
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// 10 px · w500 · Inter — tags, badges, chips
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────
  /// 15 px · w700 · Poppins — primary CTA buttons
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// 13 px · w600 · Poppins — secondary / ghost buttons
  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // ── Numeric / Mono ────────────────────────────────────────────────────────
  /// 28 px · w700 · JetBrains Mono — large money amounts
  static TextStyle get amountLarge => GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// 18 px · w600 · JetBrains Mono — medium amounts, totals
  static TextStyle get amount => GoogleFonts.jetBrainsMono(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 13 px · w500 · JetBrains Mono — small inline values, codes
  static TextStyle get amountSmall => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// 11 px · w400 · JetBrains Mono — referral codes, IDs
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ── Step / overline ───────────────────────────────────────────────────────
  /// 11 px · w600 · Inter · uppercase tracking — step indicators, overlines
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.8,
  );

  // ── App-bar title ─────────────────────────────────────────────────────────
  /// 16 px · w700 · Poppins — AppBar title
  static TextStyle get appBarTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // ── Helper: build the TextTheme consumed by buildTheme() ─────────────────
  static TextTheme buildTextTheme({required bool dark}) {
    final base = dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final fg = dark ? Colors.white : const Color(0xFF0F0F1A);
    return base.copyWith(
      displayLarge: display.copyWith(color: fg),
      headlineLarge: h1.copyWith(color: fg),
      headlineMedium: h2.copyWith(color: fg),
      headlineSmall: h3.copyWith(color: fg),
      titleLarge: h4.copyWith(color: fg),
      bodyLarge: body.copyWith(color: fg),
      bodyMedium: bodyMedium.copyWith(color: fg),
      bodySmall: bodySmall.copyWith(color: fg),
      labelLarge: labelLarge.copyWith(color: fg),
      labelSmall: labelSmall.copyWith(color: fg),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension: theme-aware styles on BuildContext
// ─────────────────────────────────────────────────────────────────────────────
extension AppTextStyleX on BuildContext {
  /// Shorthand for theme-aware typography.
  _ContextualTypography get t => _ContextualTypography(this);
}

class _ContextualTypography {
  final BuildContext _ctx;
  const _ContextualTypography(this._ctx);

  bool get _dark => Theme.of(_ctx).brightness == Brightness.dark;
  Color get _fg => _dark ? Colors.white : const Color(0xFF0F0F1A);

  // textMuted and textSub come from AppColors via context.c
  Color get _muted => _dark ? const Color(0xFF52526E) : const Color(0xFF9090B0);
  Color get _sub => _dark ? const Color(0xFF8080A0) : const Color(0xFF606080);

  TextStyle get display => AppTypography.display.copyWith(color: _fg);
  TextStyle get h1 => AppTypography.h1.copyWith(color: _fg);
  TextStyle get h2 => AppTypography.h2.copyWith(color: _fg);
  TextStyle get h3 => AppTypography.h3.copyWith(color: _fg);
  TextStyle get h4 => AppTypography.h4.copyWith(color: _fg);
  TextStyle get body => AppTypography.body.copyWith(color: _fg);
  TextStyle get bodyMedium => AppTypography.bodyMedium.copyWith(color: _fg);
  TextStyle get bodySmall => AppTypography.bodySmall.copyWith(color: _fg);
  TextStyle get labelLarge => AppTypography.labelLarge.copyWith(color: _fg);
  TextStyle get labelSmall => AppTypography.labelSmall.copyWith(color: _fg);
  TextStyle get caption => AppTypography.caption.copyWith(color: _fg);
  TextStyle get button => AppTypography.button.copyWith(color: _fg);
  TextStyle get buttonSmall => AppTypography.buttonSmall.copyWith(color: _fg);
  TextStyle get overline => AppTypography.overline.copyWith(color: _muted);
  TextStyle get appBarTitle => AppTypography.appBarTitle.copyWith(color: _fg);
  TextStyle get amountLarge => AppTypography.amountLarge.copyWith(color: _fg);
  TextStyle get amount => AppTypography.amount.copyWith(color: _fg);
  TextStyle get amountSmall => AppTypography.amountSmall.copyWith(color: _fg);
  TextStyle get mono => AppTypography.mono.copyWith(color: _muted);

  // Semantic colour shortcuts
  TextStyle get labelMuted => AppTypography.labelSmall.copyWith(color: _muted);
  TextStyle get bodySub => AppTypography.bodySmall.copyWith(color: _sub);
  TextStyle get captionMuted => AppTypography.caption.copyWith(color: _muted);
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience extension on TextStyle
// ─────────────────────────────────────────────────────────────────────────────
extension TextStyleX on TextStyle {
  TextStyle colored(Color color) => copyWith(color: color);
  TextStyle sized(double size) => copyWith(fontSize: size);
  TextStyle weighted(FontWeight w) => copyWith(fontWeight: w);
}
