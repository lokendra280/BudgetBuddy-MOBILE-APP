import 'package:expensetracker/ai_screen/pages/ai_screen.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/expense/ui/add_expense_screen.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/profile/ui/setting_screen.dart';
import 'package:expensetracker/profile/ui/social_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  SyncResult? _syncResult;

  @override
  void initState() {
    super.initState();
    ExpenseService.updateStreak();
    if (AuthService.isLoggedIn) {
      SyncService.sync().then((r) {
        if (mounted) setState(() => _syncResult = r);
      });
    }
  }

  Future<T?> _push<T>(Widget s) =>
      Navigator.push<T>(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Hive.box<Expense>('expenses').listenable(),
    builder: (_, __, ___) {
      final all = ExpenseService.forMonth(DateTime.now());
      final totalExp = ExpenseService.expenseFor(all);
      final totalInc = ExpenseService.incomeFor(all);
      final net = totalInc - totalExp;
      final budget = ExpenseService.budget;
      final (thisW, lastW) = ExpenseService.weekComparison();
      final dailyData = ExpenseService.dailyTotals(days: 7);

      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _Header(
                    net: net,
                    totalExp: totalExp,
                    totalInc: totalInc,
                    budget: budget,
                    syncResult: _syncResult,
                    onProfileTap: () => _push(
                      AuthService.isLoggedIn
                          ? const ProfileScreen()
                          : const LoginScreen(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Metrics ──────────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              MetricCard(
                                label: 'Expenses',
                                value: ExpenseService.fmt(totalExp),
                                color: kAccent,
                                icon: Icons.arrow_upward_rounded,
                                subtitle:
                                    '${all.where((e) => !e.isIncome).length} transactions',
                              ),
                              const SizedBox(width: 10),
                              MetricCard(
                                label: 'Income',
                                value: ExpenseService.fmt(totalInc),
                                color: kGreen,
                                icon: Icons.arrow_downward_rounded,
                                subtitle:
                                    '${all.where((e) => e.isIncome).length} entries',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Income vs Expense chart ───────────────────────────────────
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Last 7 days',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _Legend(kGreen, 'Income'),
                                      const SizedBox(width: 12),
                                      _Legend(kAccent, 'Expense'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _DualBarChart(data: dailyData),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Insight chip ──────────────────────────────────────────────
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Center(
                                  child: Text(
                                    '💡',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ExpenseService.wasteMessage(thisW, lastW),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Week compare ──────────────────────────────────────────────
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('Week comparison'),
                              const SizedBox(height: 14),
                              WeekCompareBar(thisWeek: thisW, lastWeek: lastW),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Recent ────────────────────────────────────────────────────
                        SectionLabel(
                          'Recent',
                          trailing: TextButton(
                            onPressed: () => _push(const StatementsScreen()),
                            child: const Text(
                              'Statements →',
                              style: TextStyle(fontSize: 12, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (all.isEmpty)
                          AppCard(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                const Text(
                                  '💸',
                                  style: TextStyle(fontSize: 36),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No entries yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap + to add income or expense',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ...all.take(6).map((e) {
                          final cats = e.isIncome
                              ? kIncomeCategories
                              : kCategories;
                          final idx = cats.indexOf(e.category);
                          final col = e.isIncome
                              ? kGreen
                              : kCatColors[idx < 0
                                    ? 0
                                    : idx % kCatColors.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpenseTile(
                              e: e,
                              color: col,
                              onDelete: () async {
                                await SyncService.deleteExpense(e);
                                AdService.trackAction();
                              },
                            ),
                          );
                        }),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
        bottomNavigationBar: _NavBar(
          onAdd: () =>
              _push(AddExpenseScreen()).then((_) => AdService.trackAction()),
          onStatements: () => _push(const StatementsScreen()),
          onSocial: () => _push(const SocialScreen()),
          onAI: () => _push(const AiScreen()),
          onSettings: () => _push(const SettingsScreen()),
        ),
      );
    },
  );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final double net, totalExp, totalInc;
  final Budget budget;
  final SyncResult? syncResult;
  final VoidCallback onProfileTap;
  const _Header({
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
    required this.syncResult,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLoggedIn = AuthService.isLoggedIn;
    final netColor = net >= 0 ? kGreen : kAccent;
    final sym = ExpenseService.symbol;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 16,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTime.now().hour < 12
                            ? 'Good morning ☀️'
                            : DateTime.now().hour < 17
                            ? 'Good afternoon 👋'
                            : 'Good evening 🌙',
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SpendSense',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kPrimary, Color(0xFF818CF8)],
                          ),
                          border: Border.all(
                            color: kPrimary.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isLoggedIn
                              ? Text(
                                  AuthService.userInitials,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      if (syncResult == SyncResult.success)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 10,
                                color: kGreen,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: kGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Net balance hero
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net >= 0 ? 'Net Savings' : 'Net Deficit',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${net >= 0 ? '+' : ''}${ExpenseService.fmt(net.abs())}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniStat(
                      '↑ Expenses',
                      ExpenseService.fmt(totalExp),
                      kAccent,
                    ),
                    const SizedBox(height: 4),
                    _MiniStat('↓ Income', ExpenseService.fmt(totalInc), kGreen),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            BudgetBar(percent: ExpenseService.budgetUsedPercent()),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ExpenseService.fmt(totalExp)} spent',
                  style: TextStyle(fontSize: 10, color: c.textMuted),
                ),
                Text(
                  '${ExpenseService.fmt(budget.monthlyLimit)} limit',
                  style: TextStyle(fontSize: 10, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      const SizedBox(width: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

// ── Dual bar chart ────────────────────────────────────────────────────────────
class _DualBarChart extends StatelessWidget {
  final List<({double income, double expense})> data;
  const _DualBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(
      0.0,
      (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
    );
    final now = DateTime.now();
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    if (maxVal == 0) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No data yet — add some expenses!',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.3,
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
                      borderRadius: BorderRadius.circular(4),
                      color: kGreen.withOpacity(0.85),
                    ),
                    BarChartRodData(
                      toY: e.value.expense,
                      width: 10,
                      borderRadius: BorderRadius.circular(4),
                      color: kAccent.withOpacity(0.85),
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
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final dayIndex = v.toInt();
                  final date = now.subtract(Duration(days: 6 - dayIndex));
                  final label = days[date.weekday - 1];
                  final isToday = date.day == now.day;
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday ? kPrimary : context.c.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // tooltipRoundedRadius: 8,
              getTooltipItem: (group, _, rod, rodIndex) {
                final sym = ExpenseService.symbol;
                return BarTooltipItem(
                  '${rodIndex == 0 ? '↓ ' : '↑ '}$sym${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rodIndex == 0 ? kGreen : kAccent,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: context.c.textSub)),
    ],
  );
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final VoidCallback onAdd, onStatements, onSocial, onAI, onSettings;
  const _NavBar({
    required this.onAdd,
    required this.onStatements,
    required this.onSocial,
    required this.onAI,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 26),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Btn(Icons.home_rounded, 'Home', true, () {}),
          _Btn(Icons.receipt_long_rounded, 'Statements', false, onStatements),
          _Fab(onAdd),
          _Btn(Icons.people_rounded, 'Social', false, onSocial),
          _Btn(Icons.auto_awesome_rounded, 'AI', false, onAI),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab(this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    ),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? kPrimary : context.c.textMuted),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active ? kPrimary : context.c.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
