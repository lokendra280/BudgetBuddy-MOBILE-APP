import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/features/profile/ui/currency_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});
  @override
  ConsumerState<LanguageScreen> createState() => _State(); // ← was State<LanguageScreen>
}

class _LangOption {
  final String code, flag, native, english, defaultCurrency;
  const _LangOption(
    this.code,
    this.flag,
    this.native,
    this.english,
    this.defaultCurrency,
  );
}

const _langs = [
  _LangOption('ne', '🇳🇵', 'नेपाली', 'Nepali', 'NPR'),
  _LangOption('en', '🇺🇸', 'English', 'English (US)', 'USD'),
  _LangOption('hi', '🇮🇳', 'हिन्दी', 'Hindi', 'INR'),
  _LangOption('en', '🇬🇧', 'English (UK)', 'English (UK)', 'GBP'),
];

class _State extends ConsumerState<LanguageScreen> {
  int _sel = 0;

  @override
  void initState() {
    super.initState();
    // Pre-select the language that is currently active so the screen
    // doesn't always open on the first item.
    final currentCode = ref.read(localeProvider).languageCode;
    final idx = _langs.indexWhere((l) => l.code == currentCode);
    if (idx >= 0) _sel = idx;
  }

  // BUG FIX 1a: change language INSTANTLY on tap — MaterialApp.locale is
  // driven by localeProvider which SpendSenseApp watches. Calling setLocale()
  // here means the whole widget tree rebuilds immediately with the new locale,
  // so the user sees translated strings before they even press Next.
  Future<void> _select(int index) async {
    HapticFeedback.selectionClick();
    setState(() => _sel = index);
    // Instant language switch — MaterialApp.locale updates in the same frame
    await ref
        .read(localeProvider.notifier)
        .setLocale(Locale(_langs[index].code));
  }

  Future<void> _next() async {
    HapticFeedback.mediumImpact();
    final lang = _langs[_sel];
    // setLocale already called in _select — no need to call again
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CurrencyScreen(suggestedCurrency: lang.defaultCurrency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Watch the provider so the screen itself rebuilds when locale changes
    // (e.g. the title text would update if it used AppLocalizations)
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
              const Text(
                'Pick your language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this anytime in Settings',
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),

              const SizedBox(height: 32),

              ..._langs.asMap().entries.map((e) {
                final lang = e.value;
                final sel = _sel == e.key;
                return GestureDetector(
                  onTap: () => _select(e.key), // ← calls setLocale immediately
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
                        Text(lang.flag, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.native,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? AppColors.primaryColor
                                      : context.textPrimary,
                                ),
                              ),
                              Text(
                                lang.english,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sel)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.border, width: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

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
        Text(
          'Step $step of $total',
          style: TextStyle(
            fontSize: 11,
            color: c.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
