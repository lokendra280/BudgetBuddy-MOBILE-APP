import 'dart:io';

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "New: home-screen widgets" announcement + how-to.
///
/// Shown automatically once per install (also reaches existing users the
/// first time they open a version that has widgets), and on demand from
/// Profile → "Home screen widget".
class WidgetIntro {
  WidgetIntro._();

  static const _seenKey = 'widget_intro_seen_v1';

  /// Shows the sheet if the user hasn't seen it yet. Returns true if shown.
  static Future<bool> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seenKey) ?? false) return false;
      await prefs.setBool(_seenKey, true);
    } catch (_) {
      return false; // never block Home on a prefs error
    }
    if (!context.mounted) return false;
    await show(context);
    return true;
  }

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddWidgetGuideSheet(),
  );
}

class AddWidgetGuideSheet extends StatelessWidget {
  const AddWidgetGuideSheet({super.key});

  List<String> get _steps => Platform.isIOS
      ? const [
          'Touch and hold an empty spot on your Home Screen until the apps jiggle',
          'Tap Edit (or +) in the top corner, then Add Widget',
          'Search for "BudgetBuddy" and pick a size',
          'Tap Add Widget, then Done',
        ]
      : const [
          'Touch and hold an empty spot on your home screen',
          'Tap Widgets',
          'Find "BudgetBuddy" → Daily Streak',
          'Drag it onto your home screen',
        ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // "NEW" pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.isDark ? kMidGreen.withValues(alpha: .25) : kMint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✨ NEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: kMidGreen,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your streak, right on\nyour home screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Piggy reminds you to log, cheers when you\'re on track, '
              'and shows what\'s left in your budget.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: c.textSub),
            ),
            const SizedBox(height: 18),

            // Live previews of the two main moods
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WidgetPreview(
                  mood: PiggyMood.happy,
                  streak: 7,
                  title: 'Nice work!',
                  message: "You're on track today",
                ),
                SizedBox(width: 12),
                _WidgetPreview(
                  mood: PiggyMood.worried,
                  streak: 7,
                  title: 'Haven\'t logged 👀',
                  message: 'It only takes a few seconds',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Steps
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How to add it',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? kMidGreen.withValues(alpha: .25)
                            : kMint,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kMidGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          _steps[i],
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: kMidGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can find this anytime in Profile → Home screen widget',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small-widget mock that mirrors the native widget's look.
class _WidgetPreview extends StatelessWidget {
  final PiggyMood mood;
  final int streak;
  final String title, message;

  const _WidgetPreview({
    required this.mood,
    required this.streak,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (mood) {
      PiggyMood.happy => const [kDeepGreen, kMidGreen],
      PiggyMood.worried => const [Color(0xFFB45309), Color(0xFFF59E0B)],
      PiggyMood.sad => const [Color(0xFF9F1239), Color(0xFFF43F5E)],
    };

    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PiggyMascot(mood: mood, size: 50),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔥 $streak',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.25,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
