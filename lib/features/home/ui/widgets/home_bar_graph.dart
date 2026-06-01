import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeBarGraph extends ConsumerWidget {
  final List<({double income, double expense})> data;
  const HomeBarGraph({super.key, required this.data});

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(fmtProvider);
    final now = DateTime.now();

    // Day labels always aligned with data[i]
    final dayLabels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      const map = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return map[day.weekday - 1];
    });

    final hasData = data.any((d) => d.income > 0 || d.expense > 0);
    if (!hasData) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.addexpense,
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ),
      );
    }

    final maxV = data.fold(
      0.0,
      (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
    );
    final maxY = maxV * 1.25;

    // ── THE FIX ──────────────────────────────────────────────────────────
    // Root cause: 50K next to 60K on a scale of 75K (60K * 1.25) renders at
    // 66% height — that's fine. BUT when maxV is something large like 570K,
    // a 50K bar = 50K / 712K = 7% of chart height → looks like a dot.
    //
    // Fix: if a value is non-zero, clamp it UP to at minimum 4% of maxY so
    // it always draws as a clearly visible bar. The REAL value is still shown
    // in the tooltip — only the rendered height is bumped up.
    double vis(double v) {
      if (v <= 0) return 0;
      final floor = maxY * 0.04; // 4% of chart = always clearly visible
      return v < floor ? floor : v;
    }

    const barWidth = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 8),
        //   child: Row(
        //     children: [
        //       _LegendDot(color: kGreen, label: 'Income'),
        //       const SizedBox(width: 14),
        //       _LegendDot(color: kAccent, label: 'Expense'),
        //     ],
        //   ),
        // ),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY,

              barGroups: data.asMap().entries.map((e) {
                final i = e.key;
                final day = now.subtract(Duration(days: 6 - i));
                final isToday = day.day == now.day && day.month == now.month;

                return BarChartGroupData(
                  x: i,
                  barsSpace: 2,
                  barRods: [
                    BarChartRodData(
                      // ← vis() ensures non-zero values are always visible
                      toY: vis(e.value.income),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          kGreen.withOpacity(isToday ? 0.6 : 0.4),
                          kGreen.withOpacity(isToday ? 1.0 : 0.8),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    BarChartRodData(
                      // ← vis() here too
                      toY: vis(e.value.expense),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          kAccent.withOpacity(isToday ? 0.6 : 0.4),
                          kAccent.withOpacity(isToday ? 1.0 : 0.8),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }).toList(),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: context.c.border,
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),

              borderData: FlBorderData(show: false),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: maxY / 4,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _compact(v),
                        style: TextStyle(
                          fontSize: 9,
                          color: context.c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
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
                    reservedSize: 26,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= dayLabels.length) {
                        return const SizedBox.shrink();
                      }
                      final day = now.subtract(Duration(days: 6 - i));
                      final isToday =
                          day.day == now.day && day.month == now.month;

                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: isToday
                            ? Container(
                                width: 22,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayLabels[i],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                dayLabels[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.c.textMuted,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),

              // Tooltip shows REAL value (not the clamped vis() value)
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  getTooltipColor: (_) => context.c.surface.withOpacity(0.95),
                  getTooltipItem: (group, _, rod, rodIndex) {
                    // Use original data value for tooltip, not vis() value
                    final realValue = rodIndex == 0
                        ? data[group.x].income
                        : data[group.x].expense;
                    if (realValue <= 0) return null;
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? '↓ ' : '↑ '}${fmt(realValue)}',
                      TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? kGreen : kAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 400),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: context.c.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
