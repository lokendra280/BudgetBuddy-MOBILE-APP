import 'package:expensetracker/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:expensetracker/ai_screen/providers/ai_providers.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(smartBudgetProvider);
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final c = context.c;
    final rem = (b.income - b.currentSpend).clamp(0.0, b.income);
    final pct = b.income > 0 ? ((rem / b.income) * 100).toInt() : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── 50/30/20 Bars ────────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconLabel(
                '💰',
                'Smart Budget — 50/30/20 Rule',
                sub:
                    'Based on ${b.income > 0 ? "your income" : "budget limit"}',
              ),
              const SizedBox(height: 16),
              // BudgetBar(
              //   'Needs (50%)',
              //   b.needsBudget,
              //   b.currentSpend,
              //   AppColors.primaryColor,
              //   sym,
              //   'Rent, food, bills, transport',
              //   percent: 20,
              // ),
              // const SizedBox(height: 12),
              // BudgetBar(
              //   'Wants (30%)',
              //   b.wantsBudget,
              //   b.currentSpend * 0.3,
              //   kAmber,
              //   sym,
              //   'Entertainment, shopping, dining out',
              // ),
              // const SizedBox(height: 12),
              // BudgetBar(
              //   'Savings (20%)',
              //   b.savingsGoal,
              //   rem,
              //   kGreen,
              //   sym,
              //   'Emergency fund, investments, goals',
              // ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── This month summary ───────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Month',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IncomeStat('Income', fmt(b.income), kGreen),
                  Container(width: 1, height: 40, color: c.border),
                  IncomeStat('Spent', fmt(b.currentSpend), kAccent),
                  Container(width: 1, height: 40, color: c.border),
                  IncomeStat('Saved', '$pct%', pct >= 20 ? kGreen : kAmber),
                ],
              ),
              if (b.income > 0) ...[
                const SizedBox(height: 14),
                Text(
                  'Savings rate this month',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  pct / 100,
                  pct >= 20
                      ? kGreen
                      : pct >= 10
                      ? kAmber
                      : kAccent,
                  height: 10,
                  clip: 6,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pct% achieved',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const Text(
                      'Target: 20%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Auto-categorization tip ──────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconLabel('🏷️', 'Auto-Categorization'),
              const SizedBox(height: 12),
              Text(
                'SpendSense detects categories automatically from your entry titles:',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          'Uber → Transport 🚗',
                          'Netflix → Entertainment 🎬',
                          "McDonald's → Food 🍜",
                          'Pharmacy → Health 💊',
                          'Amazon → Shopping 🛍',
                          'Salary → Income 💼',
                        ]
                        .map(
                          (ex) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ex,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
