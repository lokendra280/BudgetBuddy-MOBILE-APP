import 'package:expensetracker/features/auth/providers/auth_provider.dart';
import 'package:expensetracker/features/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/widgets/shimmer_widget.dart';
import 'package:expensetracker/features/expense/models/expense.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
import 'package:expensetracker/features/expense/services/category_services.dart';
import 'package:expensetracker/features/expense/ui/statemet_screen.dart';
import 'package:expensetracker/features/home/providers/sync_provider.dart';
import 'package:expensetracker/features/home/ui/widgets/app_drawer.dart';
import 'package:expensetracker/features/home/ui/widgets/header_widget.dart';
import 'package:expensetracker/features/home/ui/widgets/home_bar_graph.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:expensetracker/features/profile/ui/profile_screen.dart';
import 'package:expensetracker/features/social/services/share_service.dart';
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
    final fmt = ref.watch(fmtProvider); 
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
                              label: AppLocalizations.of(context)!.expense,
                              value: fmt(totalExp),
                              color: kAccent,
                              icon: Icons.arrow_upward_rounded,
                              subtitle:
                                  '${all.where((e) => !e.isIncome).length} ${AppLocalizations.of(context)!.thisweek}',
                            ),
                            const SizedBox(width: 10),
                            MetricCard(
                              label: AppLocalizations.of(context)!.income,
                              value: fmt(totalInc),
                              color: kGreen,
                              icon: Icons.arrow_downward_rounded,
                              subtitle:
                                  '${all.where((e) => e.isIncome).length} ${AppLocalizations.of(context)!.lastWeek}',
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
                                Text(
                                  AppLocalizations.of(context)!.last7Days,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _Leg(
                                      kGreen,
                                      AppLocalizations.of(context)!.income,
                                    ),
                                    const SizedBox(width: 12),
                                    _Leg(
                                      kAccent,
                                      AppLocalizations.of(context)!.expense,
                                    ),
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
                            SectionLabel(
                              AppLocalizations.of(context)!.weeklyComparsion,
                            ),
                            const SizedBox(height: 14),
                            WeekCompareBar(thisWeek: thisW, lastWeek: lastW),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Recent transactions ───────────────────────────
                      SectionLabel(
                        AppLocalizations.of(context)!.recent,
                        trailing: TextButton(
                          onPressed: () => _push(const StatementsScreen()),
                          child: Text(
                            AppLocalizations.of(context)!.all,
                            style: const TextStyle(
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
                              Image.asset(Assets.salary, width: 64, height: 64),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.noEntryYet,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.tapToAddIncome,
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
    if (thisW == 0) return AppLocalizations.of(context)!.youHaventSpend;
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
