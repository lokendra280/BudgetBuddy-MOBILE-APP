import 'package:expensetracker/features/auth/services/user_profile_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/dashboard/pages/dashboard_page.dart';
import 'package:expensetracker/features/expense/models/expense.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
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
  bool _saving = false; // add this line
  @override
  void initState() {
    super.initState();
    _sel = widget.suggestedCurrency;
  }

  // Future<void> _confirm() async {
  //   HapticFeedback.mediumImpact();

  //   // Save to Hive
  //   // final b = ExpenseService.budget;
  //   // b.currency = _sel;
  //   // await b.save();
  //   await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);

  //   // Save to Supabase user_profiles
  //   await UserProfileService.saveProfile(currency: _sel);

  //   if (!mounted) return;
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => const DashboardPage()),
  //   );
  // }
  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();

    setState(() => _saving = true); // add bool _saving = false field

    try {
      await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);
      await UserProfileService.saveProfile(currency: _sel);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress (step 2 of 2)
              const SizedBox(height: 20),
              _StepBar(step: 2, total: 2),
              const SizedBox(height: 32),

              const Text('💱', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 16),
              const Text(
                'Choose your currency',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All amounts will be shown in your preferred currency.',
                style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
              ),

              const SizedBox(height: 28),

              // Currency grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: kCurrencies.map((cur) {
                    final isSel = _sel == cur.code;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sel = cur.code);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cur.flag,
                                  style: const TextStyle(fontSize: 22),
                                ),

                                if (isSel)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                Text(
                                  cur.name,
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Preview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${selInfo.flag} ${selInfo.name} · Amounts shown as ${selInfo.symbol}1,000',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AppButton(
                label: 'Get Started',
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
