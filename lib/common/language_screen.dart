import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_catalogue.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/common/theme_provider.dart';
import 'package:budgetBuddy/features/profile/ui/currency_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});
  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  int _sel = 0;

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

  Future<void> _next() async {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CurrencyScreen(suggestedCurrency: kLanguages[_sel].defaultCurrency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _StepIndicator(step: 1, total: 2),
              const SizedBox(height: 32),

              const Text('🌐', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 16),
              Text('Pick your language', style: context.t.h1),
              const SizedBox(height: 8),
              Text(
                'You can change this anytime in Settings',
                style: context.t.bodySub,
              ),

              const SizedBox(height: 28),

              // Language list — now iterates kLanguages from app_catalogue.dart
              Expanded(
                child: ListView.builder(
                  itemCount: kLanguages.length,
                  itemBuilder: (_, i) {
                    final lang = kLanguages[i];
                    final sel = _sel == i;
                    return GestureDetector(
                      onTap: () => _select(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primaryColor.withOpacity(0.08)
                              : c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? AppColors.primaryColor : c.border,
                            width: sel ? 1.5 : 1,
                          ),
                          boxShadow: !context.isDark && !sel
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang.flag,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.native,
                                    style: context.t.h4.colored(
                                      sel
                                          ? AppColors.primaryColor
                                          : context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.english,
                                    style: context.t.labelMuted,
                                  ),
                                ],
                              ),
                            ),
                            _SelectionDot(selected: sel),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              AppButton(
                label: 'Next — Select Currency',
                onTap: _next,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Green check dot when selected, empty circle when not.
class _SelectionDot extends StatelessWidget {
  final bool selected;
  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.c.border, width: 1.5),
      ),
    );
  }
}

/// Segmented progress bar + "Step N of M" label.
class _StepIndicator extends StatelessWidget {
  final int step, total;
  const _StepIndicator({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            total,
            (i) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < step ? AppColors.primaryColor : c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Step $step of $total', style: context.t.overline),
      ],
    );
  }
}
