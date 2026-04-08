import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/services/lang_provider.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _State();
}

class _State extends State<LanguageScreen> {
  String _selected = 'en';

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    await LangProvider.set(Locale(_selected));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────────
              const SizedBox(height: 24),
              const Text('🌐', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 20),
              const Text(
                'Select your\nlanguage',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this anytime in Settings',
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),

              const SizedBox(height: 40),

              // ── Language options ───────────────────────────────────────────────
              ...LangProvider.supported.map((locale) {
                final code = locale.languageCode;
                final (native, english) = LangProvider.labels[code]!;
                final flag = LangProvider.flags[code]!;
                final selected = _selected == code;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = code);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? kPrimary.withOpacity(0.08) : c.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? kPrimary : c.border,
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: !context.isDark && !selected
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
                        Text(flag, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                native,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? kPrimary
                                      : (context.isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E)),
                                ),
                              ),
                              Text(
                                english,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: kPrimary,
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

              // ── Continue button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
