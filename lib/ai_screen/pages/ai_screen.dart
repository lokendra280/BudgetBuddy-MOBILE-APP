import 'package:expensetracker/ai_screen/pages/widget/over_view_tab.dart';
import 'package:expensetracker/ai_screen/services/ai_services.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _State();
}

class _State extends State<AiScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (mounted) setState(() => _tab = _tabs.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: c.textMuted,
          indicatorColor: AppColors.primaryColor,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '📊 Overview'),
            Tab(text: '💰 Budget'),
            Tab(text: '🔮 Predict'),
            Tab(text: '🎯 Goals'),
            Tab(text: '🤖 Coach'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          OverViewTab(),
          _BudgetTab(),
          _PredictTab(),
          _GoalsTab(),
          _CoachTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — OVERVIEW: health score + burn rate + alerts + insights
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — SMART BUDGET (50/30/20 + auto categorised)
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = AiService.smartBudget();
    final c = context.c;
    final sym = ExpenseService.symbol;
    final remaining = (b.income - b.currentSpend).clamp(0.0, b.income);
    final savingsAchieved = b.income > 0
        ? ((remaining / b.income) * 100).toInt()
        : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Header
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('💰', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Budget — 50/30/20 Rule',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Based on ${b.income > 0 ? "your income" : "budget limit"}',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _BudgetBar(
                'Needs (50%)',
                b.needsBudget,
                b.currentSpend,
                AppColors.primaryColor,
                sym,
                hint: 'Rent, food, bills, transport',
              ),
              const SizedBox(height: 12),
              _BudgetBar(
                'Wants (30%)',
                b.wantsBudget,
                b.currentSpend * 0.3,
                kAmber,
                sym,
                hint: 'Entertainment, shopping, dining out',
              ),
              const SizedBox(height: 12),
              _BudgetBar(
                'Savings (20%)',
                b.savingsGoal,
                remaining,
                kGreen,
                sym,
                hint: 'Emergency fund, investments, goals',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Income breakdown
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
                  _IncomeStat('Income', ExpenseService.fmt(b.income), kGreen),
                  Container(width: 1, height: 40, color: c.border),
                  _IncomeStat(
                    'Spent',
                    ExpenseService.fmt(b.currentSpend),
                    kAccent,
                  ),
                  Container(width: 1, height: 40, color: c.border),
                  _IncomeStat(
                    'Saved',
                    '$savingsAchieved%',
                    savingsAchieved >= 20 ? kGreen : kAmber,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (b.income > 0) ...[
                Text(
                  'Savings rate this month',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (savingsAchieved / 100).clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation(
                      savingsAchieved >= 20
                          ? kGreen
                          : savingsAchieved >= 10
                          ? kAmber
                          : kAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$savingsAchieved% achieved',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    Text(
                      'Target: 20%',
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

        // Auto-categorization tip
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('🏷️', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Auto-Categorization',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
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
                          ('Uber → Transport 🚗'),
                          ('Netflix → Entertainment 🎬'),
                          ('McDonald\'s → Food 🍜'),
                          ('Pharmacy → Health 💊'),
                          ('Amazon → Shopping 🛍'),
                          ('Salary → Income 💼'),
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

class _BudgetBar extends StatelessWidget {
  final String label, hint;
  final double budget, spent;
  final Color color;
  final String sym;
  const _BudgetBar(
    this.label,
    this.budget,
    this.spent,
    this.color,
    this.sym, {
    required this.hint,
  });
  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '$sym${spent.toStringAsFixed(0)} / $sym${budget.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: context.c.border,
            valueColor: AlwaysStoppedAnimation(pct > 1 ? kAccent : color),
          ),
        ),
        const SizedBox(height: 3),
        Text(hint, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    );
  }
}

class _IncomeStat extends StatelessWidget {
  final String l, v;
  final Color c;
  const _IncomeStat(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c),
        ),
        const SizedBox(height: 3),
        Text(l, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PREDICT (next month forecast + income growth)
// ─────────────────────────────────────────────────────────────────────────────
class _PredictTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pred = AiService.predict();
    final history = AiService.incomeHistory();
    final growth = AiService.incomeGrowthPercent();
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Next month forecast
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.14),
                AppColors.primaryColor.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
          ),
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
                    ExpenseService.fmt(pred.nextMonthExpense),
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
                  _PredStat(
                    'Predicted Income',
                    ExpenseService.fmt(pred.nextMonthIncome),
                    kGreen,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.primaryColor.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _PredStat(
                    'Est. Balance',
                    ExpenseService.fmt(pred.futureBalance.abs()),
                    pred.futureBalance >= 0 ? kGreen : kAccent,
                    prefix: pred.futureBalance >= 0 ? '+' : '-',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Category predictions
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
                  'Add more expenses across months to see category predictions.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                )
              else
                ...pred.byCategory.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value:
                                      (p.predicted /
                                              (pred.nextMonthExpense > 0
                                                  ? pred.nextMonthExpense
                                                  : 1))
                                          .clamp(0, 1),
                                  minHeight: 5,
                                  backgroundColor: c.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    p.isUp
                                        ? kAccent.withOpacity(0.8)
                                        : kGreen.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ExpenseService.fmt(p.predicted)} predicted (was ${ExpenseService.fmt(p.lastMonth)})',
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

        // Income growth tracker
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (history.values.every((v) => v == 0))
                Text(
                  'Log income entries to track income growth over time.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                )
              else
                SizedBox(height: 100, child: _IncomeLineChart(data: history)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PredStat extends StatelessWidget {
  final String l, v;
  final Color c;
  final String prefix;
  const _PredStat(this.l, this.v, this.c, {this.prefix = ''});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$prefix$v',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c),
      ),
      Text(l, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
    ],
  );
}

class _IncomeLineChart extends StatelessWidget {
  final Map<String, double> data;
  const _IncomeLineChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final values = data.values.toList();
    final labels = data.keys.toList();
    final maxY = values.fold(0.0, (m, v) => v > m ? v : m);
    if (maxY == 0) return const SizedBox.shrink();
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — GOALS
// ─────────────────────────────────────────────────────────────────────────────
class _GoalsTab extends StatefulWidget {
  @override
  State<_GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<_GoalsTab> {
  void _refresh() => setState(() {});

  void _showAddGoal() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '90');
    String emoji = '🎯';
    final emojis = [
      '🎯',
      '🏠',
      '🚗',
      '✈️',
      '💍',
      '📱',
      '🎓',
      '💰',
      '🏖️',
      '🎮',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Savings Goal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Emoji picker
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ss(() => emoji = e);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: emoji == e
                                ? AppColors.primaryColor.withOpacity(0.12)
                                : ctx.c.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: emoji == e
                                  ? AppColors.primaryColor
                                  : ctx.c.border,
                              width: emoji == e ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Goal name (e.g. New Phone)',
                  hintStyle: TextStyle(color: ctx.c.textMuted),
                  filled: true,
                  fillColor: ctx.c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ctx.c.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Target amount',
                        hintStyle: TextStyle(color: ctx.c.textMuted),
                        prefixText: ExpenseService.symbol,
                        filled: true,
                        fillColor: ctx.c.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ctx.c.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Days to save',
                        hintStyle: TextStyle(color: ctx.c.textMuted),
                        suffixText: 'days',
                        filled: true,
                        fillColor: ctx.c.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ctx.c.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Create Goal',
                icon: Icons.add_rounded,
                onTap: () async {
                  if (nameCtrl.text.isEmpty || targetCtrl.text.isEmpty) return;
                  final target = double.tryParse(targetCtrl.text) ?? 0;
                  final days = int.tryParse(daysCtrl.text) ?? 90;
                  if (target <= 0) return;
                  await AiService.addGoal(
                    nameCtrl.text.trim(),
                    emoji,
                    target,
                    days,
                  );
                  Navigator.pop(context);
                  _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = AiService.goals();
    final c = context.c;
    final sym = ExpenseService.symbol;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Savings Goals'),
            GestureDetector(
              onTap: _showAddGoal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'New Goal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (goals.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  'No savings goals yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a goal to track your progress towards a target.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Create my first goal',
                  icon: Icons.add_rounded,
                  onTap: _showAddGoal,
                ),
              ],
            ),
          )
        else
          ...goals.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              g.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${g.daysLeft} days remaining · Save $sym${g.dailySuggestion.toStringAsFixed(0)}/day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: c.textMuted,
                          ),
                          onPressed: () async {
                            await AiService.deleteGoal(g.id);
                            _refresh();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$sym${g.saved.toStringAsFixed(0)} saved',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Target: $sym${g.target.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.progress,
                        minHeight: 10,
                        backgroundColor: c.border,
                        valueColor: AlwaysStoppedAnimation(
                          g.progress >= 1
                              ? kGreen
                              : AppColors.primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(g.progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 11,
                            color: g.progress >= 1 ? kGreen : c.textMuted,
                            fontWeight: g.progress >= 1
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (g.progress < 1)
                          GestureDetector(
                            onTap: () => _showAddAmount(g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+ Add savings',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddAmount(SavingsGoal g) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to "${g.name}"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Amount saved',
                prefixText: ExpenseService.symbol,
                filled: true,
                fillColor: context.c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onTap: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt <= 0) return;
                await AiService.addToGoal(g.id, amt);
                Navigator.pop(context);
                _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5 — AI COACH
// ─────────────────────────────────────────────────────────────────────────────
class _CoachTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = AiService.coachTips();
    final rec = AiService.detectRecurring();
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Coach header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.14),
                const Color(0xFF6366F1).withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your AI Financial Coach',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalised tips based on your spending patterns this month.',
                      style: TextStyle(
                        fontSize: 12,
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

        const SizedBox(height: 16),
        const SectionLabel('Personalised Advice'), const SizedBox(height: 12),

        if (tips.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text(
                  'Keep tracking!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add more expenses and income to unlock personalised coaching.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...tips.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(e.value.impactColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              e.value.emoji,
                              style: const TextStyle(fontSize: 17),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tip ${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.value.action,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: kAmber),
                        const SizedBox(width: 4),
                        Text(
                          'Impact: ',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                        Text(
                          e.value.impact,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(e.value.impactColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
        const SectionLabel('Recurring Expenses'), const SizedBox(height: 10),
        if (rec.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No recurring patterns detected yet.',
              style: TextStyle(fontSize: 12, color: c.textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...rec.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          r.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${r.occurrences}× · avg ${ExpenseService.fmt(r.avgAmount)} · next ~${DateFormat('MMM d').format(r.nextEstimate)}',
                            style: TextStyle(fontSize: 10, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🔄', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
