import 'package:budgetbuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetbuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PredictTab extends ConsumerWidget {
  const PredictTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final pred = ref.watch(predictionProvider);
    final history = ref.watch(incomeHistoryProvider);
    final growth = ref.watch(incomeGrowthProvider);
    final cashFlow = ref.watch(cashFlowProvider);
    final billHealth = ref.watch(billHealthProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        // ── Next month forecast card ─────────────────────────────────────────
        BrandHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l.nextMonthForecast, style: context.heroLabel),
                  ),
                  Text('🔮', style: AppTypography.h2.copyWith(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fmt(pred.nextMonthExpense),
                  style: context.heroValue,
                ),
              ),
              Text(l.predictSpend, style: context.heroBody),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HeroChip(
                      icon: Icons.south_west_rounded,
                      label: l.predictedIncome,
                      value: fmt(pred.nextMonthIncome),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroChip(
                      icon: pred.futureBalance >= 0
                          ? Icons.savings_outlined
                          : Icons.warning_amber_rounded,
                      label: l.estBalance,
                      value:
                          '${pred.futureBalance >= 0 ? '+' : '-'}${fmt(pred.futureBalance.abs())}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Cash Flow Breakdown ──────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.nextMonthCashFlow,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _CashFlowBar(
                income: cashFlow.projectedIncome,
                expenses: cashFlow.projectedExpenses,
                bills: cashFlow.upcomingBillsTotal,
                goals: cashFlow.goalsRequiredThisMonth,
                l: l,
              ),
              const SizedBox(height: 14),
              _FlowRow(
                '💰 ${l.projectedIncome}',
                fmt(cashFlow.projectedIncome),
                kGreen,
              ),
              _FlowRow(
                '📉 ${l.expense}',
                fmt(cashFlow.projectedExpenses),
                kAccent,
              ),
              if (cashFlow.upcomingBillsTotal > 0)
                _FlowRow(
                  '📋 ${l.committedBills}',
                  fmt(cashFlow.upcomingBillsTotal),
                  kAmber,
                ),
              if (cashFlow.goalsRequiredThisMonth > 0)
                _FlowRow(
                  '🎯 ${l.goalsRequired}',
                  fmt(cashFlow.goalsRequiredThisMonth),
                  AppColors.primaryColor,
                ),
              const Divider(height: 20),
              _FlowRow(
                cashFlow.projectedSurplus >= 0
                    ? '✅ ${l.projectedSurplus}'
                    : '⚠️ ${l.projectedShortfall}',
                fmt(cashFlow.projectedSurplus.abs()),
                cashFlow.projectedSurplus >= 0 ? kGreen : kAccent,
                bold: true,
              ),
              if (cashFlow.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...cashFlow.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kAmber.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kAmber.withOpacity(0.2)),
                      ),
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
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Category predictions ─────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.categoryForecast,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (pred.byCategory.isEmpty)
                Text(
                  l.addMoreExpenseAcross,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                )
              else
                ...pred.byCategory
                    .take(3)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            EmojiBox(
                              p.emoji,
                              AppColors.primaryColor.withOpacity(0.1),
                              size: 32,
                              iconSize: 14,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p.category,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            p.isUp
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 14,
                                            color: p.isUp ? kAccent : kGreen,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${p.changePercent.abs().toInt()}%',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: p.isUp
                                                      ? kAccent
                                                      : kGreen,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ProgressBar(
                                    (p.predicted /
                                            (pred.nextMonthExpense > 0
                                                ? pred.nextMonthExpense
                                                : 1))
                                        .clamp(0, 1),
                                    p.isUp
                                        ? kAccent.withOpacity(0.8)
                                        : kGreen.withOpacity(0.8),
                                    height: 5,
                                    clip: 3,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${fmt(p.predicted)} predicted (was ${fmt(p.lastMonth)})',
                                    style: AppTypography.caption.copyWith(
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
              if (pred.byCategory.length > 3)
                RewardGate(
                  feature: 'predict_categories',
                  title:
                      '+${pred.byCategory.length - 3} more category forecasts',
                  subtitle: 'Watch a short ad · unlocked for 24h',
                  child: Column(
                    children: pred.byCategory
                        .skip(3)
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                EmojiBox(
                                  p.emoji,
                                  AppColors.primaryColor.withOpacity(0.1),
                                  size: 32,
                                  iconSize: 14,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            p.category,
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                p.isUp
                                                    ? Icons.trending_up_rounded
                                                    : Icons
                                                          .trending_down_rounded,
                                                size: 14,
                                                color: p.isUp
                                                    ? kAccent
                                                    : kGreen,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${p.changePercent.abs().toInt()}%',
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: p.isUp
                                                          ? kAccent
                                                          : kGreen,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ProgressBar(
                                        (p.predicted /
                                                (pred.nextMonthExpense > 0
                                                    ? pred.nextMonthExpense
                                                    : 1))
                                            .clamp(0, 1),
                                        p.isUp
                                            ? kAccent.withOpacity(0.8)
                                            : kGreen.withOpacity(0.8),
                                        height: 5,
                                        clip: 3,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${fmt(p.predicted)} predicted (was ${fmt(p.lastMonth)})',
                                        style: AppTypography.caption.copyWith(
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const AdSlot(),

        // ── Upcoming bills impact ────────────────────────────────────────────
        if (billHealth.dueSoonList.isNotEmpty ||
            billHealth.overdueList.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.upcomingBillImpact,
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (billHealth.overdueList.isNotEmpty) ...[
                  _BillImpactTile(
                    emoji: '🔴',
                    label: l.overdueBills,
                    bills: billHealth.overdueList,
                    fmt: fmt,
                    color: kAccent,
                  ),
                  const SizedBox(height: 8),
                ],
                if (billHealth.dueSoonList.isNotEmpty)
                  _BillImpactTile(
                    emoji: '⏰',
                    label: l.dueSoon,
                    bills: billHealth.dueSoonList,
                    fmt: fmt,
                    color: kAmber,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Income growth ────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.incomeGrowth,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _GrowthPill(growth),
                ],
              ),
              const SizedBox(height: 14),
              if (history.values.every((v) => v == 0))
                Text(
                  l.logIncome,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                )
              else
                SizedBox(height: 100, child: _IncomeChart(data: history)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _FlowRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _FlowRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? null : context.c.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _CashFlowBar extends StatelessWidget {
  final double income, expenses, bills, goals;
  final AppLocalizations l;
  const _CashFlowBar({
    required this.income,
    required this.expenses,
    required this.bills,
    required this.goals,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (income <= 0) return const SizedBox.shrink();
    final expFrac = (expenses / income).clamp(0.0, 1.0);
    final billFrac = (bills / income).clamp(0.0, 1.0 - expFrac);
    final goalFrac = (goals / income).clamp(0.0, 1.0 - expFrac - billFrac);
    final surplusFrac = (1.0 - expFrac - billFrac - goalFrac).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (expFrac > 0)
                  Expanded(
                    flex: (expFrac * 100).toInt(),
                    child: ColoredBox(color: kAccent),
                  ),
                if (billFrac > 0)
                  Expanded(
                    flex: (billFrac * 100).toInt(),
                    child: ColoredBox(color: kAmber),
                  ),
                if (goalFrac > 0)
                  Expanded(
                    flex: (goalFrac * 100).toInt(),
                    child: ColoredBox(color: AppColors.primaryColor),
                  ),
                if (surplusFrac > 0)
                  Expanded(
                    flex: (surplusFrac * 100).toInt(),
                    child: ColoredBox(color: kGreen),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: [
            _BarLegend(l.expense, kAccent),
            if (bills > 0) _BarLegend(l.bill, kAmber),
            if (goals > 0) _BarLegend(l.goals, AppColors.primaryColor),
            _BarLegend(l.saved, kGreen),
          ],
        ),
      ],
    );
  }
}

class _BarLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _BarLegend(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 9,
          color: context.c.textMuted,
        ),
      ),
    ],
  );
}

class _BillImpactTile extends StatelessWidget {
  final String emoji, label;
  final List<dynamic> bills;
  final String Function(double) fmt;
  final Color color;
  const _BillImpactTile({
    required this.emoji,
    required this.label,
    required this.bills,
    required this.fmt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = bills.fold(0.0, (s, b) => s + (b.amount as double));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: AppTypography.h3.copyWith(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  bills.take(2).map((b) => b.title as String).join(', '),
                  style: AppTypography.caption.copyWith(
                    color: context.c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt(total),
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthPill extends StatelessWidget {
  final double growth;
  const _GrowthPill(this.growth);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (growth >= 0 ? kGreen : kAccent).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% MoM',
      style: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: growth >= 0 ? kGreen : kAccent,
      ),
    ),
  );
}

class _IncomeChart extends StatelessWidget {
  final Map<String, double> data;
  const _IncomeChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final values = data.values.toList();
    final labels = data.keys.toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) => Text(
                labels[v.toInt() < labels.length ? v.toInt() : 0],
                style: AppTypography.caption.copyWith(
                  fontSize: 9,
                  color: context.c.textMuted,
                ),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: values
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: kGreen,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              color: kGreen.withOpacity(0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
