import 'package:expensetracker/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:expensetracker/ai_screen/providers/ai_providers.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PredictTab extends ConsumerWidget {
  const PredictTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pred = ref.watch(predictionProvider);
    final history = ref.watch(incomeHistoryProvider);
    final growth = ref.watch(incomeGrowthProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── Next month forecast card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: gradBox(AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔮', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Next Month Forecast',
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(pred.nextMonthExpense),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'predicted spend',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  PredStat(
                    'Predicted Income',
                    fmt(pred.nextMonthIncome),
                    kGreen,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.primaryColor.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  PredStat(
                    'Est. Balance',
                    fmt(pred.futureBalance.abs()),
                    pred.futureBalance >= 0 ? kGreen : kAccent,
                    prefix: pred.futureBalance >= 0 ? '+' : '-',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Category predictions ───────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Forecast',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (pred.byCategory.isEmpty)
                Text(
                  'Add more expenses across months to see predictions.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                )
              else
                ...pred.byCategory.map(
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
                                    style: const TextStyle(
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
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: p.isUp ? kAccent : kGreen,
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
                                style: TextStyle(
                                  fontSize: 10,
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

        const SizedBox(height: 14),

        // ── Income growth ──────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Income Growth',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  _GrowthPill(growth),
                ],
              ),
              const SizedBox(height: 14),
              if (history.values.every((v) => v == 0))
                Text(
                  'Log income entries to track growth over time.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
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
      style: TextStyle(
        fontSize: 11,
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
        gridData: FlGridData(show: false),
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
                style: TextStyle(fontSize: 9, color: context.c.textMuted),
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
