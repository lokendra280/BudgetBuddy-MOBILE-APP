import 'package:expensetracker/auth/providers/auth_provider.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/shimmer_widget.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:expensetracker/expense/services/category_services.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/providers/sync_provider.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/widgets/app_drawer.dart';
import 'package:expensetracker/home/ui/widgets/header_widget.dart';
import 'package:expensetracker/home/ui/widgets/home_bar_graph.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/social/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _H();
}

class _H extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();

    // ── Update streak via Riverpod notifier ───────────────────────────────
    Future.microtask(() => ref.read(expenseProvider.notifier).updateStreak());

    // ── Trigger cloud sync via Riverpod notifier ──────────────────────────
    Future.microtask(() => ref.read(syncProvider.notifier).sync());

    // ── Non-critical background services (unchanged) ──────────────────────
    _startBackgroundServices();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _startBackgroundServices() {
    AdService.init();
    AdService.preloadInterstitial();
    NotificationService.init();
    CategoryService.init(); // pre-warms Supabase category cache
  }

  void _push(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    // ── Watch all reactive state from Riverpod ────────────────────────────
    final all = ref.watch(monthExpensesProvider);
    final totalExp = ref.watch(monthTotalExpenseProvider);
    final totalInc = ref.watch(monthTotalIncomeProvider);
    final net = ref.watch(monthNetProvider);
    final budget = ref.watch(budgetProvider);
    final (thisW, lastW) = ref.watch(weekComparisonProvider);
    final dailyData = ref.watch(daily7Provider);
    final syncStatus = ref.watch(syncProvider);
    final fmt = ref.watch(fmtProvider); // String Function(double)
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // ── Loading shimmer ───────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.c.bg,
        body: const SafeArea(child: HomeShimmer()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,

      // ── Drawer (reads its own providers internally) ───────────────────
      drawer: AppDrawer(
        onPush: _push,
        onShare: () => ShareService.shareReport(context),
      ),

      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Header: net balance, budget bar, sync status ──────────
                HeaderWidget(
                  net: net,
                  totalExp: totalExp,
                  totalInc: totalInc,
                  budget: budget,
                  syncResult: syncStatus,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onProfileTap: () => _push(
                    isLoggedIn ? const ProfileScreen() : const LoginScreen(),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Income / Expense metric cards ─────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            MetricCard(
                              label: 'Expenses',
                              value: fmt(totalExp),
                              color: kAccent,
                              icon: Icons.arrow_upward_rounded,
                              subtitle:
                                  '${all.where((e) => !e.isIncome).length} transactions',
                            ),
                            const SizedBox(width: 10),
                            MetricCard(
                              label: 'Income',
                              value: fmt(totalInc),
                              color: kGreen,
                              icon: Icons.arrow_downward_rounded,
                              subtitle:
                                  '${all.where((e) => e.isIncome).length} entries',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 7-day dual bar chart ──────────────────────────
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            // ← Extracted widget, receives data from provider
                            HomeBarGraph(data: dailyData),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Weekly insight ────────────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.10),
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
                                _wasteMessage(thisW, lastW, fmt),
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

                      // ── Week comparison bar ───────────────────────────
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

                      // ── Recent transactions ───────────────────────────
                      SectionLabel(
                        'Recent',
                        trailing: TextButton(
                          onPressed: () => _push(const StatementsScreen()),
                          child: const Text(
                            'All →',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Empty state
                      if (all.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              const Text('💸', style: TextStyle(fontSize: 36)),
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

                      // Recent expense tiles — delete via syncProvider
                      ...all.take(6).map((e) {
                        final isInc = e.isIncome;
                        final cats = isInc ? kIncomeCategories : kCategories;
                        final idx = cats.indexOf(e.category);
                        final col = isInc
                            ? kGreen
                            : kCatColors[idx < 0 ? 0 : idx % kCatColors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ExpenseTile(
                            e: e,
                            color: col,
                            onDelete: () async {
                              // ← Delete through syncProvider (removes from
                              //   both Hive and Supabase, updates state)
                              await ref
                                  .read(syncProvider.notifier)
                                  .deleteExpense(e);
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
          // const BannerAdWidget(), // uncomment when ads are ready
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _wasteMessage(
    double thisW,
    double lastW,
    String Function(double) fmt,
  ) {
    if (thisW == 0) return "You haven't spent anything yet 🧘";
    if (lastW == 0) return "${fmt(thisW)} spent this week 💸";
    final diff = thisW - lastW;
    if (diff > 0) return "Spent ${fmt(diff)} MORE than last week 😳";
    if (diff < 0) return "Saved ${fmt(-diff)} vs last week 🎉";
    return "Spending about the same as last week 😌";
  }
}

// ── Legend dot ───────────────────────────────────────────────────────────────
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
