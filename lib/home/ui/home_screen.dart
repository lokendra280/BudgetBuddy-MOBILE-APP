import 'package:expensetracker/ai_screen/pages/ai_screen.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/shimmer_widget.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/expense/ui/add_expense_screen.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/inslight_screen.dart';
import 'package:expensetracker/profile/ui/about_page.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/profile/ui/setting_screen.dart';
import 'package:expensetracker/social/services/share_service.dart';
import 'package:expensetracker/social/ui/social_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _H();
}

class _H extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  SyncResult? _syncResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ExpenseService.updateStreak();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
    if (AuthService.isLoggedIn) {
      SyncService.sync().then((r) {
        if (mounted) setState(() => _syncResult = r);
      });
    }
  }

  _push(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

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

      if (_isLoading)
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: context.c.bg,
          body: const SafeArea(child: HomeShimmer()),
        );

      return Scaffold(
        key: _scaffoldKey,
        drawer: _AppDrawer(
          onPush: _push,
          onShare: () => ShareService.shareReport(context),
        ),
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
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                        // Metric cards
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
                        const SizedBox(height: 14),

                        // Income/Expense bar chart (REAL DATA)
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
                                      _Leg(kGreen, 'Income'),
                                      const SizedBox(width: 12),
                                      _Leg(kAccent, 'Expense'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _DualBar(data: dailyData),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Insight card
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
                        const SizedBox(height: 14),

                        // Week compare
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
                        const SizedBox(height: 14),

                        // Recent
                        SectionLabel(
                          'Recent',
                          trailing: TextButton(
                            onPressed: () => _push(const StatementsScreen()),
                            child: const Text(
                              'All →',
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
                          final isInc = e.isIncome;
                          final cats = isInc ? kIncomeCategories : kCategories;
                          final idx = cats.indexOf(e.category);
                          final col = isInc
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
          onAdd: () => _push(
            const AddExpenseScreen(),
          ).then((_) => AdService.trackAction()),
          onStatements: () => _push(const StatementsScreen()),
          onSocial: () => _push(const SocialScreen()),
          onAI: () => _push(const AiScreen()),
        ),
      );
    },
  );
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final void Function(Widget) onPush;
  final VoidCallback onShare;
  const _AppDrawer({required this.onPush, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLogged = AuthService.isLoggedIn;
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.12),
                    kPrimary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onPush(
                        isLogged ? const ProfileScreen() : const LoginScreen(),
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kPrimary, Color(0xFF818CF8)],
                        ),
                        border: Border.all(
                          color: kPrimary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isLogged ? AuthService.userInitials : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLogged ? AuthService.userName : 'Guest',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isLogged ? AuthService.userEmail : 'Sign in to sync',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StreakBadge(days: ExpenseService.budget.streakDays),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DItem(
                    Icons.home_rounded,
                    'Home',
                    kPrimary,
                    () => Navigator.pop(context),
                  ),
                  _DItem(Icons.receipt_long_rounded, 'Statements', null, () {
                    Navigator.pop(context);
                    onPush(const StatementsScreen());
                  }),
                  _DItem(Icons.bar_chart_rounded, 'Insights', null, () {
                    Navigator.pop(context);
                    onPush(const InsightsScreen());
                  }),
                  _DItem(Icons.auto_awesome_rounded, 'AI Insights', null, () {
                    Navigator.pop(context);
                    onPush(const AiScreen());
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),
                  _DItem(Icons.people_rounded, 'Community', kAmber, () {
                    Navigator.pop(context);
                    onPush(const SocialScreen());
                  }),
                  _DItem(Icons.share_rounded, 'Share Report', kGreen, () {
                    Navigator.pop(context);
                    onShare();
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),
                  _DItem(Icons.settings_outlined, 'Settings', null, () {
                    Navigator.pop(context);
                    onPush(const SettingsScreen());
                  }),
                  _DItem(Icons.info_outline_rounded, 'About', null, () {
                    Navigator.pop(context);
                    onPush(const AboutScreen());
                  }),
                  if (!isLogged)
                    _DItem(Icons.login_rounded, 'Sign In', kPrimary, () {
                      Navigator.pop(context);
                      onPush(const LoginScreen());
                    }),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'SpendSense v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _DItem(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? context.c.textSub, size: 22),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
    dense: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final double net, totalExp, totalInc;
  final Budget budget;
  final SyncResult? syncResult;
  final VoidCallback onMenuTap, onProfileTap;
  const _Header({
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nc = net >= 0 ? kGreen : kAccent;
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
                // Hamburger
                GestureDetector(
                  onTap: onMenuTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 20,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'BudgetBuddy',
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
                            colors: [kPrimary, Color(0xFF818CF8)],
                          ),
                          border: Border.all(
                            color: kPrimary.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AuthService.isLoggedIn
                              ? Text(
                                  AuthService.userInitials,
                                  style: const TextStyle(
                                    fontSize: 13,
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
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net >= 0 ? 'Net Savings' : 'Net Deficit',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${net >= 0 ? '+' : ''}${ExpenseService.fmt(net.abs())}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: nc,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MS('↑ Expenses', ExpenseService.fmt(totalExp), kAccent),
                    const SizedBox(height: 4),
                    _MS('↓ Income', ExpenseService.fmt(totalInc), kGreen),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            BudgetBar(percent: ExpenseService.budgetUsedPercent()),
            const SizedBox(height: 6),
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

class _MS extends StatelessWidget {
  final String l, v;
  final Color c;
  const _MS(this.l, this.v, this.c);
  @override
  Widget build(BuildContext ctx) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(l, style: TextStyle(fontSize: 10, color: ctx.c.textMuted)),
      const SizedBox(width: 6),
      Text(
        v,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    ],
  );
}

// ── Dual bar chart ────────────────────────────────────────────────────────────
class _DualBar extends StatelessWidget {
  final List<({double income, double expense})> data;
  const _DualBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxV = data.fold(
      0.0,
      (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
    );
    final now = DateTime.now();
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (maxV == 0)
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Add expenses to see chart',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ),
      );
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
                  final d = now.subtract(Duration(days: 6 - v.toInt()));
                  final isToday = d.day == now.day && d.month == now.month;
                  final lbl = labels[(d.weekday - 1) % 7];
                  return Text(
                    lbl,
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
              tooltipBorderRadius: BorderRadius.circular(6),
              getTooltipItem: (group, _, rod, ri) => BarTooltipItem(
                '${ri == 0 ? '↓' : '↑'} ${ExpenseService.fmt(rod.toY)}',
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

class _Leg extends StatelessWidget {
  final Color c;
  final String l;
  const _Leg(this.c, this.l);
  @override
  Widget build(BuildContext ctx) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(l, style: TextStyle(fontSize: 11, color: ctx.c.textSub)),
    ],
  );
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final VoidCallback onAdd, onStatements, onSocial, onAI;
  const _NavBar({
    required this.onAdd,
    required this.onStatements,
    required this.onSocial,
    required this.onAI,
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
          _N(Icons.home_rounded, 'Home', true, () {}),
          _N(Icons.receipt_long_rounded, 'Statements', false, onStatements),
          _Fab(onAdd),
          _N(Icons.people_rounded, 'Social', false, onSocial),
          _N(Icons.auto_awesome_rounded, 'AI', false, onAI),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback t;
  const _Fab(this.t);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: t,
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimary, Color(0xFF818CF8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    ),
  );
}

class _N extends StatelessWidget {
  final IconData i;
  final String l;
  final bool a;
  final VoidCallback t;
  const _N(this.i, this.l, this.a, this.t);
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: t,
    child: SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 22, color: a ? kPrimary : ctx.c.textMuted),
          const SizedBox(height: 3),
          Text(
            l,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: a ? kPrimary : ctx.c.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}
