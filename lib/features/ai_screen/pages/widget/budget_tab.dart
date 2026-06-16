import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetBuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final b = ref.watch(smartBudgetProvider);
    final billHealth = ref.watch(billHealthProvider);
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final c = context.c;

    final rem = (b.income - b.currentSpend).clamp(0.0, b.income);
    final pct = b.income > 0 ? ((rem / b.income) * 100).toInt() : 0;
    final billRatioPct = (billHealth.incomeCommitmentRatio * 100).toInt().clamp(
      0,
      100,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── 50/30/20 Bars ────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconLabel(
                Assets.saving,
                'Smart Budget — 50/30/20 Rule',
                sub: b.income > 0 ? l.disposableIncome : l.monthlybudget,
              ),
              const SizedBox(height: 16),
              SmartBudgetBar(
                l.needs,
                b.needsBudget,
                b.currentSpend,
                AppColors.primaryColor,
                sym,
                l.needsDescription,
              ),
              SmartBudgetBar(
                l.wants,
                b.wantsBudget,
                b.currentSpend * 0.3,
                kAmber,
                sym,
                l.wantsDescription,
              ),
              SmartBudgetBar(
                l.savings,
                b.savingsGoal,
                rem,
                kGreen,
                sym,
                l.savingsDescription,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── This month summary ───────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.thisMonth,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IncomeStat(l.income, fmt(b.income), kGreen),
                  Container(width: 1, height: 40, color: c.border),
                  IncomeStat(l.spend, fmt(b.currentSpend), kAccent),
                  Container(width: 1, height: 40, color: c.border),
                  IncomeStat(l.saved, '$pct%', pct >= 20 ? kGreen : kAmber),
                ],
              ),
              if (b.income > 0) ...[
                const SizedBox(height: 14),
                Text(
                  l.savingsRateThisMonth,
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
                      '$pct% ${l.achieved}',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    Text(
                      l.target20,
                      style: const TextStyle(
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

        // ── Bill Commitment Breakdown ────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconLabel(
                Assets.balance,
                l.billCommitments,
                sub: l.billCommitmentSubtitle,
              ),
              const SizedBox(height: 14),

              // Ratio bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.billsVsIncome,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                  Text(
                    '$billRatioPct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: billHealth.isCritical
                          ? kAccent
                          : billHealth.isHigh
                          ? kAmber
                          : kGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ProgressBar(
                billHealth.incomeCommitmentRatio.clamp(0.0, 1.0),
                billHealth.isCritical
                    ? kAccent
                    : billHealth.isHigh
                    ? kAmber
                    : kGreen,
                height: 8,
                clip: 4,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${fmt(billHealth.totalMonthlyCommitment)}${l.perMonth} committed',
                    style: TextStyle(fontSize: 10, color: c.textMuted),
                  ),
                  Text(
                    billRatioPct > 50
                        ? '⚠️ ${l.tooHigh}'
                        : billRatioPct > 35
                        ? '↗ ${l.moderate}'
                        : '✅ ${l.healthy}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: billHealth.isCritical
                          ? kAccent
                          : billHealth.isHigh
                          ? kAmber
                          : kGreen,
                    ),
                  ),
                ],
              ),

              if (billHealth.largestBills.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  l.largestBillsLabel,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 8),
                ...billHealth.largestBills.map(
                  (bill) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(bill.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                bill.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt(bill.amount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              b.income > 0
                                  ? '${(bill.amount / b.income * 100).toInt()}% ${l.ofIncome}'
                                  : l.perMonth,
                              style: TextStyle(fontSize: 9, color: c.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Due soon strip
              if (billHealth.dueSoonList.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAmber.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${billHealth.dueSoonList.length} ${l.bill.toLowerCase()}${billHealth.dueSoonList.length > 1 ? "s" : ""} ${l.dueSoon.toLowerCase()} — ${billHealth.dueSoonList.map((b) => b.title).take(2).join(', ')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: kAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
