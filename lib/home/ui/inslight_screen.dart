import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InsightsScreen extends StatefulWidget {
  final bool showShare;
  const InsightsScreen({super.key, this.showShare = false});
  @override
  State<InsightsScreen> createState() => _State();
}

class _State extends State<InsightsScreen> {
  final _screenshotCtrl = ScreenshotController();
  int _period = 0;
  int _touchedPie = -1;
  bool _advancedUnlocked = false;

  @override
  void initState() {
    super.initState();
    // _advancedUnlocked = PremiumService.isPremium;
    AdService.preloadRewarded();
    if (widget.showShare) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _share());
    }
  }

  Future<void> _share() async {
    final expenses = ExpenseService.forMonth(DateTime.now());
    final total = ExpenseService.totalFor(expenses);
    final budget = ExpenseService.budget;
    final cats = ExpenseService.byCategory(expenses);
    final (thisW, lastW) = ExpenseService.weekComparison();

    final image = await _screenshotCtrl.captureFromWidget(
      ShareCard(
        total: total,
        saved: (budget.monthlyLimit - total).clamp(0, 99999),
        topCat: cats.isEmpty ? 'N/A' : cats.entries.first.key,
        message: ExpenseService.wasteMessage(thisW, lastW),
        streak: budget.streakDays,
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spendsense_share.png');
    await file.writeAsBytes(image);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'My SpendSense report 📊');
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Hive.box<Expense>('expenses').listenable(),
    builder: (_, __, ___) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final expenses = _period == 0
          ? ExpenseService.forMonth(now)
          : ExpenseService.forWeek(weekStart);
      final total = ExpenseService.totalFor(expenses);
      final cats = ExpenseService.byCategory(expenses);
      // final daily = ExpenseService.last7DayTotals();
      final budget = ExpenseService.budget;
      final (thisW, lastW) = ExpenseService.weekComparison();
      final c = context.c;

      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Insights',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.ios_share_rounded,
                size: 20,
                color: AppColors.primaryColor,
              ),
              onPressed: _share,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeriodToggle(
                value: _period,
                onChanged: (v) => setState(() => _period = v),
              ),
              const SizedBox(height: 18),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _period == 0 ? 'this month' : 'this week',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ExpenseService.wasteMessage(thisW, lastW),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    if (cats.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        ExpenseService.topWasteCategory(expenses),
                        style: const TextStyle(fontSize: 12, color: kAccent),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Standard pie chart (free) ──
              if (cats.isNotEmpty) ...[
                const SectionLabel('By category'),
                const SizedBox(height: 12),
                AppCard(
                  child: _PieChart(
                    cats: cats,
                    total: total,
                    touched: _touchedPie,
                    onTouch: (i) => setState(() => _touchedPie = i),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Bar chart (free) ──
              const SectionLabel('Last 7 days'),
              const SizedBox(height: 12),
              // AppCard(child: _BarChart(daily: daily)),
              const SizedBox(height: 16),

              // ── LOCKED: Advanced insights (rewarded ad or premium) ──
              // LockedInsightCard(
              //   title: 'Advanced insights',
              //   unlocked: _advancedUnlocked,
              //   onUnlock: () => setState(() => _advancedUnlocked = true),
              //   content: Column(
              //     children: [
              //       WeekCompareBar(thisWeek: thisW, lastWeek: lastW),
              //       const SizedBox(height: 14),
              //       BudgetBar(percent: ExpenseService.budgetUsedPercent()),
              //       const SizedBox(height: 14),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Text(
              //             '₹${total.toStringAsFixed(0)} spent',
              //             style: TextStyle(fontSize: 12, color: c.textMuted),
              //           ),
              //           Text(
              //             '₹${budget.monthlyLimit.toStringAsFixed(0)} limit',
              //             style: TextStyle(fontSize: 12, color: c.textMuted),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Share my report',
                onTap: _share,
                icon: Icons.share_rounded,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PeriodToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PeriodToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Row(
        children: [
          _Tab('This month', 0, value, onChanged),
          _Tab('This week', 1, value, onChanged),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int idx, current;
  final ValueChanged<int> onChanged;
  const _Tab(this.label, this.idx, this.current, this.onChanged);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () => onChanged(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: current == idx ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: current == idx ? Colors.white : context.c.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _PieChart extends StatelessWidget {
  final Map<String, double> cats;
  final double total;
  final int touched;
  final ValueChanged<int> onTouch;
  const _PieChart({
    required this.cats,
    required this.total,
    required this.touched,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final entries = cats.entries.toList();
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              pieTouchData: PieTouchData(
                touchCallback: (_, r) =>
                    onTouch(r?.touchedSection?.touchedSectionIndex ?? -1),
              ),
              sections: entries.asMap().entries.map((e) {
                final col = kCatColors[e.key % kCatColors.length];
                final hit = e.key == touched;
                return PieChartSectionData(
                  value: e.value.value,
                  color: col,
                  radius: hit ? 54 : 44,
                  showTitle: hit,
                  title: '${(e.value.value / total * 100).toInt()}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: entries.asMap().entries.map((e) {
            final col = kCatColors[e.key % kCatColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '${e.value.key} ${(e.value.value / total * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> daily;
  const _BarChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final max = daily.reduce((a, b) => a > b ? a : b);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          maxY: max <= 0 ? 100 : max * 1.3,
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
                  days[v.toInt()],
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            ),
          ),
          barGroups: daily
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      width: 20,
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
    );
  }
}
