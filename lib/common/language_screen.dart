import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_catalogue.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/theme_provider.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:budgetbuddy/features/profile/ui/currency_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language picker.
///
/// Two modes, detected automatically:
///  • Onboarding (first route, can't pop) → "Continue" goes to currency (step 2)
///  • From Settings (pushed)              → back arrow + "Save" just closes
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});
  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  int _sel = 0;

  static const _greetings = {
    'ne': 'नमस्ते!',
    'en': 'Hello!',
    'hi': 'नमस्ते!',
    'pt': 'Olá!',
    'zh': '你好!',
  };

  @override
  void initState() {
    super.initState();
    final currentCode = ref.read(localeProvider).languageCode;
    final idx = kLanguages.indexWhere((l) => l.code == currentCode);
    if (idx >= 0) _sel = idx;
  }

  Future<void> _select(int index) async {
    HapticFeedback.selectionClick();
    setState(() => _sel = index);
    await ref
        .read(localeProvider.notifier)
        .setLocale(Locale(kLanguages[index].code));
  }

  void _continue(bool fromSettings) {
    HapticFeedback.mediumImpact();
    if (fromSettings) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CurrencyScreen(suggestedCurrency: kLanguages[_sel].defaultCurrency),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final fromSettings = Navigator.canPop(context);
    final lang = kLanguages[_sel];

    return Scaffold(
      backgroundColor: context.c.bg,
      body: Column(
        children: [
          OnboardingStepHeader(
            step: 1,
            total: 2,
            showSteps: !fromSettings,
            onBack: fromSettings ? () => Navigator.pop(context) : null,
            mascot: PiggyMascot(size: 54),
            bubble: _greetings[lang.code] ?? 'Hello!',
            title: 'Choose your language',
            subtitle: 'You can change this anytime in Settings.',
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              itemCount: kLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _LanguageTile(
                lang: kLanguages[i],
                selected: _sel == i,
                onTap: () => _select(i),
              ),
            ),
          ),
          BottomCta(
            label: fromSettings ? 'Save' : 'Continue',
            onTap: () => _continue(fromSettings),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final LangOption lang;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? (context.isDark ? kMidGreen.withValues(alpha: .25) : kMint)
                  : c.cardElevated,
              shape: BoxShape.circle,
            ),
            child: Text(lang.flag, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.native,
                  style: context.t.h4.weighted(FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(lang.english, style: context.t.labelMuted),
              ],
            ),
          ),
          SelectionCheck(selected: selected),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared onboarding-step pieces (also used by currency_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

/// Mint header with step bar, piggy + speech bubble, title and subtitle.
class OnboardingStepHeader extends StatelessWidget {
  final int step, total;
  final bool showSteps;
  final VoidCallback? onBack;
  final Widget mascot;
  final String bubble;
  final String title;
  final String subtitle;

  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.mascot,
    required this.bubble,
    required this.title,
    required this.subtitle,
    this.showSteps = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDark
              ? [kDeepGreen.withValues(alpha: 0.35), context.c.bg]
              : [kMint, context.c.bg],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 10,
        18,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: context.textPrimary,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              if (showSteps) ...[
                Expanded(
                  child: Row(
                    children: List.generate(
                      total,
                      (i) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 5,
                          margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: i < step
                                ? kMidGreen
                                : kMidGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$step / $total',
                  style: context.t.labelSmall.colored(kMidGreen),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              mascot,
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: _SpeechBubble(bubble, key: ValueKey(bubble)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: context.t.h1),
          const SizedBox(height: 4),
          Text(subtitle, style: context.t.bodySub),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
      ),
      boxShadow: [
        BoxShadow(
          color: kDeepGreen.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      text,
      style: context.t.labelLarge.copyWith(
        fontWeight: FontWeight.w800,
        color: kMidGreen,
      ),
    ),
  );
}

/// Card with a green outline + mint fill when selected.
class SelectableCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? (context.isDark
                  ? kMidGreen.withValues(alpha: 0.14)
                  : const Color(0xFFF2FBF6))
            : c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? kMidGreen : c.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected || context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SelectionCheck extends StatelessWidget {
  final bool selected;
  const SelectionCheck({super.key, required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? kMidGreen : Colors.transparent,
      border: Border.all(
        color: selected ? kMidGreen : context.c.borderStrong,
        width: 1.6,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
        : null,
  );
}

/// Full-width green pill button pinned to the bottom (safe-area aware).
class BottomCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const BottomCta({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      18,
      10,
      18,
      MediaQuery.of(context).padding.bottom + 16,
    ),
    decoration: BoxDecoration(
      color: context.c.bg,
      border: Border(top: BorderSide(color: context.c.border, width: 0.5)),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: kMidGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kMidGreen.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: context.t.button.colored(Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    ),
  );
}
