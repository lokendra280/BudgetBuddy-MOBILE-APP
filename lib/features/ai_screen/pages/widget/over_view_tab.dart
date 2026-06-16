import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/score_test_animation.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetBuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final score = ref.watch(healthScoreProvider);
    final burn = ref.watch(burnRateProvider);
    final alerts = ref.watch(alertsProvider);
    final insights = ref.watch(aiSuggestionsProvider);
    final subs = ref.watch(subscriptionsProvider);
    final rec = ref.watch(recurringProvider);
    final billHealth = ref.watch(billHealthProvider);
    final cashFlow = ref.watch(cashFlowProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        children: [
          // ── Financial Health Score ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  score.color.withOpacity(0.2),
                  score.color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AwesomeScoreWidget(score: score),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.financialHealth,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9090B0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score.headline,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...score.factors.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              CommonSvgWidget(svgName: f.emoji),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          f.resolveLabel(l),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${f.score}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: score.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    ProgressBar(
                                      f.score / 100,
                                      score.color,
                                      height: 4,
                                    ),
                                    Text(
                                      f.resolveDetail(l),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Burn Rate ────────────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconLabel(Assets.strike, l.burnRateAndRunWay),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatCol(l.dailySpend, fmt(burn.dailySpend), kAccent),
                    StatCol(
                      l.monthlyRate,
                      fmt(burn.monthlySpend),
                      AppColors.primaryColor,
                    ),
                    StatCol(
                      l.runWay,
                      '${burn.runwayDays} days',
                      burn.runwayDays < 30
                          ? kAccent
                          : burn.runwayDays < 90
                          ? kAmber
                          : kGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (burn.runwayDays < 30 ? kAccent : kGreen)
                        .withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CommonSvgWidget(
                        svgName: burn.runwayDays < 30
                            ? Assets.warning
                            : burn.runwayDays < 90
                            ? Assets.blub
                            : Assets.correct,
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          burn.runwayDays < 30
                              ? 'Critical: runs out in ${burn.runwayDays} days at this rate'
                              : burn.runwayDays < 90
                              ? 'Moderate: ${burn.runwayDays} day runway. Build emergency fund.'
                              : 'Healthy ${burn.runwayDays}-day runway 🎉',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: burn.runwayDays < 30
                                ? kAccent
                                : burn.runwayDays < 90
                                ? kAmber
                                : kGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Cash Flow Forecast ───────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconLabel(Assets.balance, l.nextMonthCashFlow),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatCol(l.income, fmt(cashFlow.projectedIncome), kGreen),
                    StatCol(
                      l.expense,
                      fmt(cashFlow.projectedExpenses),
                      kAccent,
                    ),
                    StatCol(
                      cashFlow.projectedSurplus >= 0 ? l.saved : l.netDeficit,
                      fmt(cashFlow.projectedSurplus.abs()),
                      cashFlow.projectedSurplus >= 0 ? kGreen : kAccent,
                    ),
                  ],
                ),
                if (cashFlow.upcomingBillsTotal > 0 ||
                    cashFlow.goalsRequiredThisMonth > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (cashFlow.upcomingBillsTotal > 0)
                        Expanded(
                          child: _MiniStat(
                            '📋 ${l.bill}',
                            fmt(cashFlow.upcomingBillsTotal),
                            kAmber,
                          ),
                        ),
                      if (cashFlow.goalsRequiredThisMonth > 0)
                        Expanded(
                          child: _MiniStat(
                            '🎯 ${l.goals}',
                            fmt(cashFlow.goalsRequiredThisMonth),
                            AppColors.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ],
                if (cashFlow.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...cashFlow.warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Smart Alerts ─────────────────────────────────────────────────────
          if (alerts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel(l.smartAlerts),
                Chip(
                  label: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kAccent,
                    ),
                  ),
                  backgroundColor: kAccent.withOpacity(0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...alerts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(a.severityColor).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(a.severityColor).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(a.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(a.severityColor),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.body,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Bill Commitments ─────────────────────────────────────────────────
          SectionLabel(l.billCommitments),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        l.monthlyBills,
                        fmt(billHealth.totalMonthlyCommitment),
                        billHealth.isCritical
                            ? kAccent
                            : billHealth.isHigh
                            ? kAmber
                            : kGreen,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        l.ofIncome,
                        '${(billHealth.incomeCommitmentRatio * 100).toInt()}%',
                        billHealth.isCritical
                            ? kAccent
                            : billHealth.isHigh
                            ? kAmber
                            : kGreen,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        l.overdue,
                        '${billHealth.overdueList.length}',
                        billHealth.overdueList.isEmpty ? kGreen : kAccent,
                      ),
                    ),
                  ],
                ),
                if (billHealth.largestBills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    l.largestBills,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ...billHealth.largestBills.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(b.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            fmt(b.amount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (billHealth.overdueList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔴', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${billHealth.overdueList.map((b) => b.title).take(2).join(', ')} ${l.overdue.toLowerCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: kAccent,
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

          const SizedBox(height: 14),

          // ── AI Spending Insights ─────────────────────────────────────────────
          SectionLabel(l.aiSpendingInsight),
          const SizedBox(height: 10),
          if (insights.isEmpty)
            EmptyCard(Assets.star, l.addMoreExpenses, l.wellAnalysisPatternOnce)
          else
            ...insights.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmojiBox(s.emoji, Color(s.color)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.body,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Subscriptions + Recurring ────────────────────────────────────────
          const SizedBox(height: 8),
          SectionLabel(l.subscriptions),
          const SizedBox(height: 10),
          ...[...subs, ...rec].take(5).map((i) {
            late final String title;
            late final String subtitle;
            late final String emoji;
            late final double amount;

            if (i is SubscriptionItem) {
              title = i.name;
              subtitle = i.frequency;
              emoji = i.emoji;
              amount = i.amount;
            } else if (i is RecurringExpense) {
              title = i.title;
              subtitle = i.category;
              emoji = i.emoji;
              amount = i.avgAmount;
            } else {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    EmojiBox(emoji, AppColors.primaryColor.withOpacity(0.12)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 10, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt(amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
