import 'dart:io';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/features/auth/ui/login_screen.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/pages/bill_reminder_screen.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_strip_alert.dart';
import 'package:budgetBuddy/features/buddy_chat/pages/buddy_chat_page.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/expense/services/category_services.dart';
import 'package:budgetBuddy/features/expense/ui/statemet_screen.dart';
import 'package:budgetBuddy/features/home/providers/sync_provider.dart';
import 'package:budgetBuddy/features/home/ui/widgets/app_drawer.dart';
import 'package:budgetBuddy/features/home/ui/widgets/header_widget.dart';
import 'package:budgetBuddy/features/home/ui/widgets/home_bar_graph.dart';
import 'package:budgetBuddy/features/profile/ui/profile_screen.dart';
import 'package:budgetBuddy/features/sms_service/services/sms_auto_sync_service.dart';
import 'package:budgetBuddy/features/sms_service/ui/widgets/sms_permision_gard.dart';
import 'package:budgetBuddy/features/social/services/share_service.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(bool)? onDrawerChanged;
  const HomeScreen({super.key, this.onDrawerChanged});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Core app services
    ref.read(expenseProvider.notifier).updateStreak();
    ref.read(syncProvider.notifier).sync();
    ref.read(adServiceProvider).preloadRewarded();
    NotificationService.scheduleDailyReminder();
    CategoryService.init();

    // ── SMS auto-sync — Android only, throttled internally ──────────────
    // if (!Platform.isIOS) {
    //   await _runSmsSync(ignoreThrottle: false); // ← throttled
    // }
  }

  // Future<bool> _isOnline() async {
  //   final result = await Connectivity().checkConnectivity();
  //   // On newer connectivity_plus versions checkConnectivity() returns a
  //   // List<ConnectivityResult> — adjust this line to match your version.
  //   return result != ConnectivityResult.none;
  // }

  // Future<void> _maybeShowFeedback() async {
  //   if (!FeedbackPromptService.shouldShowToday) return;
  //   if (!mounted) return;
  //   if (!await _isOnline()) return;
  //   if (!mounted) return;
  //   showFeedbackSheet(context, isDailyPrompt: true);
  // }

  /// Runs SMS sync using the current Riverpod expense list.
  /// Called both from _init() on every app open AND from the permission
  /// guard's onSyncRequested callback when user first grants permission.
  // In home_screen.dart
  // Future<void> _runSmsSync({bool ignoreThrottle = false}) async {
  //   final expenses = ref.read(expenseProvider).all;
  //   await SmsAutoSyncService.sync(
  //     addExpense:
  //         ({
  //           required String title,
  //           required double amount,
  //           required String category,
  //           required bool isIncome,
  //           required DateTime date,
  //         }) async {
  //           await ref
  //               .read(expenseProvider.notifier)
  //               .addExpense(
  //                 title: title,
  //                 amount: amount,
  //                 category: category,
  //                 isIncome: isIncome,
  //                 date: date,
  //               );
  //         },
  //     existingExpenses: expenses,
  //     ignoreThrottle: ignoreThrottle, // ← pass through
  //   );
  // }

  void _push(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final overdueBills = ref.watch(overdueBillsProvider);
    final dueSoonBills = ref.watch(dueSoonBillsProvider);
    final hasBillAlert = overdueBills.isNotEmpty || dueSoonBills.isNotEmpty;
    final fmt = ref.watch(fmtProvider);
    final syncStatus = ref.watch(syncProvider);

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: widget.onDrawerChanged,
      drawer: AppDrawer(
        onPush: _push,
        onShare: () => ShareService.shareReport(context),
      ),
      body: Column(
        children: [
          // ── SMS banner — Android only ──────────────────────────────────
          // Shows if user skipped the splash dialog.
          // onSyncRequested triggers immediate sync when they enable here.
          // In HomeScreen.build() — banner passes ignoreThrottle: true for first grant
          // if (!Platform.isIOS)
          //   SmsPermissionGuard(
          //     modal: false,
          //     onSyncRequested: () =>
          //         _runSmsSync(ignoreThrottle: true), // ← true
          //     child: const SizedBox.shrink(),
          //   ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _HomeHeader(
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
                      const SizedBox(height: 16),
                      const _MetricRow(),
                      const SizedBox(height: 14),
                      _ChatCard(
                        onTap: () =>
                            NavigationService.push(target: BuddyChatPage()),
                      ),
                      const SizedBox(height: 14),
                      const _BarChartCard(),
                      const SizedBox(height: 14),
                      const _WeeklyInsightCard(),
                      const SizedBox(height: 14),
                      const _WeekCompareCard(),
                      const SizedBox(height: 14),
                      _RecentTransactions(
                        onSeeAll: () => _push(const StatementsScreen()),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          if (hasBillAlert)
            BillAlertStrip(
              overdue: overdueBills,
              dueSoon: dueSoonBills,
              fmt: fmt,
              onTap: () => _push(const BillReminderScreen()),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Split consumers
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  final dynamic syncResult;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const _HomeHeader({
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = ref.watch(monthNetProvider);
    final totalExp = ref.watch(monthTotalExpenseProvider);
    final totalInc = ref.watch(monthTotalIncomeProvider);
    final budget = ref.watch(budgetProvider);
    return HeaderWidget(
      net: net,
      totalExp: totalExp,
      totalInc: totalInc,
      budget: budget,
      syncResult: syncResult,
      onMenuTap: onMenuTap,
      onProfileTap: onProfileTap,
    );
  }
}

class _MetricRow extends ConsumerWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalExp = ref.watch(monthTotalExpenseProvider);
    final totalInc = ref.watch(monthTotalIncomeProvider);
    final all = ref.watch(monthExpensesProvider);
    final fmt = ref.watch(fmtProvider);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        MetricCard(
          label: l10n.expense,
          value: fmt(totalExp),
          color: kAccent,
          icon: Icons.arrow_upward_rounded,
          subtitle: '${all.where((e) => !e.isIncome).length} ${l10n.thisweek}',
        ),
        const SizedBox(width: 10),
        MetricCard(
          label: l10n.income,
          value: fmt(totalInc),
          color: kGreen,
          icon: Icons.arrow_downward_rounded,
          subtitle: '${all.where((e) => e.isIncome).length} ${l10n.lastWeek}',
        ),
      ],
    );
  }
}

class _ChatCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatCard({required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
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
            child: CommonSvgWidget(svgName: Assets.chat, height: 20, width: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.chatWithBuddy,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BarChartCard extends ConsumerWidget {
  const _BarChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyData = ref.watch(daily7Provider);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.last7Days,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _Leg(kGreen, l10n.income),
                  const SizedBox(width: 12),
                  _Leg(kAccent, l10n.expense),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          HomeBarGraph(data: dailyData),
        ],
      ),
    );
  }
}

class _WeeklyInsightCard extends ConsumerWidget {
  const _WeeklyInsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (thisW, lastW) = ref.watch(weekComparisonProvider);
    final fmt = ref.watch(fmtProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
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
              child: CommonSvgWidget(
                svgName: Assets.blub,
                height: 20,
                width: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _msg(thisW, lastW, fmt, l10n),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _msg(
    double thisW,
    double lastW,
    String Function(double) fmt,
    AppLocalizations l10n,
  ) {
    if (thisW == 0) return l10n.youHaventSpend;
    if (lastW == 0) return '${fmt(thisW)} spent this week 💸';
    final diff = thisW - lastW;
    if (diff > 0) return 'Spent ${fmt(diff)} MORE than last week 😳';
    if (diff < 0) return 'Saved ${fmt(-diff)} vs last week 🎉';
    return 'Spending about the same as last week 😌';
  }
}

class _WeekCompareCard extends ConsumerWidget {
  const _WeekCompareCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (thisW, lastW) = ref.watch(weekComparisonProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(AppLocalizations.of(context)!.weeklyComparsion),
          const SizedBox(height: 14),
          WeekCompareBar(thisWeek: thisW, lastWeek: lastW),
        ],
      ),
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  final VoidCallback onSeeAll;
  const _RecentTransactions({required this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(monthExpensesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          l10n.recent,
          trailing: TextButton(
            onPressed: onSeeAll,
            child: Text(
              l10n.all,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (all.isEmpty)
          Center(
            child: AppCard(
              // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                children: [
                  Image.asset(Assets.salary, width: 64, height: 64),
                  const SizedBox(height: 10),
                  Text(
                    l10n.noEntryYet,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tapToAddIncome,
                    style: TextStyle(fontSize: 12, color: context.c.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...all.take(6).map((e) {
            final isInc = e.isIncome;
            final cats = isInc ? kIncomeCategories : kCategories;
            final idx = cats.indexOf(e.category);
            final col = isInc
                ? kGreen
                : kCatColors[idx < 0 ? 0 : idx % kCatColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DeletableTile(e: e, color: col),
            );
          }),
      ],
    );
  }
}

class _DeletableTile extends ConsumerWidget {
  final Expense e;
  final Color color;
  const _DeletableTile({required this.e, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpenseTile(
    e: e,
    color: color,
    onDelete: () => ref
        .read(adServiceProvider)
        .showRewarded(
          onRewarded: () => ref.read(syncProvider.notifier).deleteExpense(e),
          onNotAvailable: () =>
              ref.read(syncProvider.notifier).deleteExpense(e),
        ),
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
