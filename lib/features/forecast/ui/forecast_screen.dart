import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/forecast/providers/forecast_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});
  @override
  ConsumerState<ForecastScreen> createState() => _State();
}

class _State extends ConsumerState<ForecastScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final forecast = ref.watch(forecastProvider);
    final history = ref.watch(monthlyHistoryProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;
    final maxY = history
        .map((h) => h.amount)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expense Forecast',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Prediction card — locked behind rewarded ad
          _unlocked
              ? AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔮', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fmt(forecast.predicted),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'predicted next month',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(forecast.confidence * 100).toInt()}% confidence',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        forecast.message,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      _Bar(
                        '3-month avg',
                        forecast.avg3Month,
                        forecast.avg3Month,
                        fmt,
                      ),
                      const SizedBox(height: 8),
                      _Bar(
                        'Predicted',
                        forecast.predicted,
                        forecast.avg3Month,
                        fmt,
                      ),
                    ],
                  ),
                )
              : _Gate(
                  onUnlock: () => ref
                      .read(adServiceProvider)
                      .showRewarded(
                        onRewarded: () => setState(() => _unlocked = true),
                      ),
                ),

          const SizedBox(height: 16),
          const SectionLabel('Monthly History'),
          const SizedBox(height: 12),

          // Bar chart
          AppCard(
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.3,
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
                        reservedSize: 20,
                        getTitlesWidget: (v, _) => Text(
                          history[v.toInt() % history.length].label,
                          style: TextStyle(fontSize: 9, color: c.textMuted),
                        ),
                      ),
                    ),
                  ),
                  barGroups: history
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.amount,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.4),
                                  AppColors.primaryColor,
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Monthly stats table
          const SectionLabel('Month Breakdown'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                ...history
                    .asMap()
                    .entries
                    .map(
                      (e) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.value.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                fmt(e.value.amount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: e.value.amount > 0
                                      ? kAccent
                                      : c.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (e.key < history.length - 1)
                            Divider(color: c.border, height: 16),
                        ],
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value, max;
  final String Function(double) fmt;
  const _Bar(this.label, this.value, this.max, this.fmt);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.c.textMuted),
          ),
          Text(
            fmt(value),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: max > 0 ? (value / max).clamp(0.0, 1.2) : 0,
          minHeight: 7,
          backgroundColor: context.c.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
        ),
      ),
    ],
  );
}

class _Gate extends StatelessWidget {
  final VoidCallback onUnlock;
  const _Gate({required this.onUnlock});
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const SizedBox(height: 8),
        const Text('🔮', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        const Text(
          'Unlock Forecast',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Watch a short ad to see next month\'s prediction',
          style: TextStyle(fontSize: 12, color: context.c.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onUnlock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Watch Ad & Unlock',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
