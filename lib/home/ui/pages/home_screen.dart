import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/shimmer_widget.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/category_services.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/widgets/app_drawer.dart';
import 'package:expensetracker/home/ui/widgets/header_widget.dart';
import 'package:expensetracker/home/ui/widgets/home_bar_graph.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/social/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
    _startBackgroundServices();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
    if (AuthService.isLoggedIn) {
      SyncService.sync().then((r) {
        if (mounted) setState(() => _syncResult = r);
      });
    }
  }

  void _startBackgroundServices() {
    // 🚀 Non-critical services
    AdService.init();
    AdService.preloadInterstitial();

    NotificationService.init();

    CategoryService.init(); // API fetch
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

      if (_isLoading) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: context.c.bg,
          body: const SafeArea(child: HomeShimmer()),
        );
      }

      return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          onPush: _push,
          onShare: () => ShareService.shareReport(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  HeaderWidget(
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
                              HomeBarGraph(data: dailyData),
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
            //  const BannerAdWidget(),
          ],
        ),
      );
    },
  );
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
