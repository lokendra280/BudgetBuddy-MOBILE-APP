import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_svg_widget.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'dart:math' as math;
import 'package:budgetbuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetbuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetbuddy/features/ai_screen/services/ai_services.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
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
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          // ── Financial Health Score ───────────────────────────────────────────
          BrandHeroCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.financialHealth, style: context.heroLabel),
                      const SizedBox(height: 4),
                      Text(score.grade, style: context.heroValue),
                      const SizedBox(height: 6),
                      Text(score.headline, style: context.heroBody),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ScoreRing(score: score.score),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What's behind your score", style: context.t.h4),
                const SizedBox(height: 12),
                ...score.factors.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? kMidGreen.withValues(alpha: .2)
                                : kMint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: CommonSvgWidget(svgName: f.emoji),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      f.resolveLabel(l),
                                      style: context.t.labelLarge,
                                    ),
                                  ),
                                  Text(
                                    '${f.score}',
                                    style: context.t.labelLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: _factorColor(f.score),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ProgressBar(
                                f.score / 100,
                                _factorColor(f.score),
                                height: 6,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                f.resolveDetail(l),
                                style: context.t.labelMuted,
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
                          style: AppTypography.labelSmall.copyWith(
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
                          Text(
                            '⚠️',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: AppTypography.labelSmall.copyWith(
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
          const AdSlot(),

          // ── Smart Alerts ─────────────────────────────────────────────────────
          if (alerts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel(l.smartAlerts),
                Chip(
                  label: Text(
                    '${alerts.length}',
                    style: AppTypography.caption.copyWith(
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
                      Text(a.emoji, style: AppTypography.h2),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Color(a.severityColor),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.body,
                              style: AppTypography.labelSmall.copyWith(
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
                    style: AppTypography.labelSmall.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...billHealth.largestBills.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            b.emoji,
                            style: AppTypography.h4.copyWith(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.title,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            fmt(b.amount),
                            style: AppTypography.labelSmall.copyWith(
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
                        Text(
                          '🔴',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${billHealth.overdueList.map((b) => b.title).take(2).join(', ')} ${l.overdue.toLowerCase()}',
                            style: AppTypography.labelSmall.copyWith(
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
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.body,
                              style: AppTypography.labelSmall.copyWith(
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
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: AppTypography.caption.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt(amount),
                      style: AppTypography.labelLarge.copyWith(
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
      Text(
        label,
        style: AppTypography.caption.copyWith(color: context.c.textMuted),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

Color _factorColor(int v) => v >= 70
    ? kGreen
    : v >= 40
    ? kAmber
    : kAccent;

/// Animated 0–100 ring for the hero card.
class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 84,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => CustomPaint(
        painter: _RingPainter(v),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(v * 100).round()}',
                style: context.t.h2.copyWith(color: Colors.white),
              ),
              Text('/ 100', style: context.heroLabel.copyWith(fontSize: 9)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 7.0;
    final r = (Offset.zero & size).deflate(w / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6EE7B7),
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v;
}
