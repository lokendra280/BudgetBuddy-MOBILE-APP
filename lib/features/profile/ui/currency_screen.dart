import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/auth/services/user_profile_service.dart';
import 'package:budgetBuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyScreen extends ConsumerStatefulWidget {
  final String suggestedCurrency;
  const CurrencyScreen({super.key, required this.suggestedCurrency});
  @override
  ConsumerState<CurrencyScreen> createState() => _State();
}

class _State extends ConsumerState<CurrencyScreen> {
  late String _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.suggestedCurrency;
  }

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);
    await UserProfileService.saveProfile(currency: _sel);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final selInfo = currencyOf(_sel);

    return Scaffold(
      backgroundColor: c.bg,
      // Use resizeToAvoidBottomInset so keyboard doesn't cause overflow
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _StepBar(step: 2, total: 2),
              const SizedBox(height: 24),

              const Text('💱', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Choose your currency',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All amounts will be shown in your preferred currency.',
                style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
              ),

              const SizedBox(height: 20),

              // ── Currency grid ──────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // FIX: use a fixed item extent ratio — avoids overflow from
                    // content trying to expand beyond the cell height
                    childAspectRatio: 1.65,
                  ),
                  itemCount: kCurrencies.length,
                  itemBuilder: (_, i) {
                    final cur = kCurrencies[i];
                    final isSel = _sel == cur.code;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sel = cur.code);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryColor.withOpacity(0.08)
                              : c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? AppColors.primaryColor : c.border,
                            width: isSel ? 2 : 1,
                          ),
                          boxShadow: !context.isDark && !isSel
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        // FIX: Remove the invalid `Expanded` that was here.
                        // Expanded only works as a direct child of Row/Column/Flex.
                        // Inside a Container/AnimatedContainer it causes
                        // "RenderFlex overflowed" because the parent has no
                        // flex context to expand into.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // ← don't try to fill
                          children: [
                            Row(
                              children: [
                                Text(
                                  cur.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const Spacer(),
                                if (isSel)
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Text(
                            //   cur.symbol,
                            //   style: TextStyle(
                            //     fontSize: 20,
                            //     fontWeight: FontWeight.w800,
                            //     color: isSel
                            //         ? AppColors.primaryColor
                            //         : context.textPrimary,
                            //   ),
                            // ),
                            // const SizedBox(height: 2),
                            Text(
                              '${cur.name} (${cur.code})',
                              style: TextStyle(
                                fontSize: 10,
                                color: c.textSub,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── Preview banner ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: kGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${selInfo.flag} ${selInfo.name} · '
                        'Amounts shown as ${selInfo.symbol}1,000',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              AppButton(
                label: 'Get Started ',
                onTap: _confirm,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step, total;
  const _StepBar({required this.step, required this.total});

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
