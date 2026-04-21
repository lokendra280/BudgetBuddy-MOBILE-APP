import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeBarGraph extends ConsumerWidget {
  final List<({double income, double expense})> data;
  const HomeBarGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(fmtProvider);
    final maxV = data.fold(
      0.0,
      (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
    );
    final now = DateTime.now();
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    if (maxV == 0) {
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

    return SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          maxY: maxV * 1.3,
          barGroups: data
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.income,
                      width: 10,
                      color: kGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: e.value.expense,
                      width: 10,
                      color: kAccent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )
              .toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.c.border, strokeWidth: 0.5),
          ),
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
                getTitlesWidget: (v, _) {
                  final day = now.subtract(Duration(days: 6 - v.toInt()));
                  final isToday = day.day == now.day && day.month == now.month;
                  final label = labels[(day.weekday - 1) % 7];
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primaryColor
                          : context.c.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, ri) => BarTooltipItem(
                '${ri == 0 ? '↓' : '↑'} ${fmt(rod.toY)}',
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ri == 0 ? kGreen : kAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
