import 'dart:io';
import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_svg_widget.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/common/navigation_service.dart';
import 'package:budgetbuddy/common/services/ads_service.dart';
import 'package:budgetbuddy/common/services/notification_service.dart';
import 'package:budgetbuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetbuddy/features/auth/ui/login_screen.dart';
import 'package:budgetbuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetbuddy/features/bill_reminder/ui/pages/bill_reminder_screen.dart';
import 'package:budgetbuddy/features/bill_reminder/ui/widgets/bill_strip_alert.dart';
import 'package:budgetbuddy/features/buddy_chat/pages/buddy_chat_page.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_prompt_card.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/features/expense/services/category_services.dart';
import 'package:budgetbuddy/features/expense/ui/add_expense_screen.dart';
import 'package:budgetbuddy/common/localization/category_localization.dart';
import 'package:intl/intl.dart';
import 'package:budgetbuddy/features/expense/ui/statemet_screen.dart';
import 'package:budgetbuddy/features/feedback/services/feedback_promt_services.dart';
import 'package:budgetbuddy/features/feedback/ui/feedback_sheet.dart';
import 'package:budgetbuddy/features/home/providers/sync_provider.dart';
import 'package:budgetbuddy/features/home/ui/widgets/app_drawer.dart';
import 'package:budgetbuddy/features/home/ui/widgets/chat_card.dart';
import 'package:budgetbuddy/features/home/ui/widgets/header_widget.dart';
import 'package:budgetbuddy/features/home/ui/widgets/home_banner_ad.dart';
import 'package:budgetbuddy/features/home/ui/widgets/home_bar_graph.dart';
import 'package:budgetbuddy/features/profile/ui/profile_screen.dart';
import 'package:budgetbuddy/features/sms_service/services/sms_auto_sync_service.dart';
import 'package:budgetbuddy/features/sms_service/ui/widgets/sms_permision_gard.dart';
import 'package:budgetbuddy/features/social/services/share_service.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (FeedbackPromptService.shouldShowToday) {
          showFeedbackSheet(context, isDailyPrompt: true);
        }
      });
    });
  }

  Future<void> _init() async {
    // Core app services
    ref.read(expenseProvider.notifier).updateStreak();
    ref.read(syncProvider.notifier).sync();
    ref.read(adServiceProvider).preloadRewarded();
    // Ask for notification permission once the UI is on screen (iOS only
    // shows the system prompt the first time; later calls return instantly).
    await NotificationService.requestPermission();
    NotificationService.scheduleDailyReminder();
    CategoryService.init();

    if (!Platform.isIOS) {
      await _runSmsSync(ignoreThrottle: false); // ← throttled
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    // On newer connectivity_plus versions checkConnectivity() returns a
    // List<ConnectivityResult> — adjust this line to match your version.
    return result != ConnectivityResult.none;
  }

  Future<void> _maybeShowFeedback() async {
    if (!FeedbackPromptService.shouldShowToday) return;
    if (!mounted) return;
    if (!await _isOnline()) return;
    if (!mounted) return;
    showFeedbackSheet(context, isDailyPrompt: true);
  }

  // / Runs SMS sync using the current Riverpod expense list.
  // / Called both from _init() on every app open AND from the permission
  // / guard's onSyncRequested callback when user first grants permission.
  // In home_screen.dart
  Future<void> _runSmsSync({bool ignoreThrottle = false}) async {
    final expenses = ref.read(expenseProvider).all;
    // await SmsAutoSyncService.sync(
    //   addExpense:
    //       ({
    //         required String title,
    //         required double amount,
    //         required String category,
    //         required bool isIncome,
    //         required DateTime date,
    //       }) async {
    //         await ref
    //             .read(expenseProvider.notifier)
    //             .addExpense(
    //               title: title,
    //               amount: amount,
    //               category: category,
    //               isIncome: isIncome,
    //               date: date,
    //             );
    //       },
    //   existingExpenses: expenses,
    //   ignoreThrottle: ignoreThrottle, // ← pass through
    // );
  }

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
          // SizedBox(height: 30),
          // ── SMS banner — Android only ──────────────────────────────────
          // Shows if user skipped the splash dialog.
          // onSyncRequested triggers immediate sync when they enable here.
          // In HomeScreen.build() — banner passes ignoreThrottle: true for first grant
          if (!Platform.isIOS)
            SmsPermissionGuard(
              modal: false,
              onSyncRequested: () =>
                  _runSmsSync(ignoreThrottle: true), // ← true
              child: const SizedBox.shrink(),
            ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _HomeHeader(
                  syncResult: syncStatus,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onProfileTap: () => _push(
                    isLoggedIn ? const ProfileScreen() : const LoginScreen(),
                  ),
                  onAddExpense: () => _push(const AddExpenseScreen()),
                  onAddIncome: () =>
                      _push(const AddExpenseScreen(initialIsIncome: true)),
                  onBillsTap: () => _push(const BillReminderScreen()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 14),
                      const BudgetPromptCard(),
                      const SizedBox(height: 18),
                      _RecentTransactions(
                        onSeeAll: () => _push(const StatementsScreen()),
                        onAddExpense: () => _push(const AddExpenseScreen()),
                        onAddIncome: () => _push(
                          const AddExpenseScreen(initialIsIncome: true),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const HomeBannerAd(),
                      const SizedBox(height: 14),
                      ChatCard(
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
                      const HomeBannerAd(),
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
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onBillsTap;

  const _HomeHeader({
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onBillsTap,
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
      onAddExpense: onAddExpense,
      onAddIncome: onAddIncome,
      onBillsTap: onBillsTap,
    );
  }
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
              Text(l10n.last7Days, style: context.t.h4),
              Row(
                children: [
                  _Leg(kGreen, l10n.income),
                  const SizedBox(width: 12),
                  _Leg(kAccent, l10n.expense),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  const _RecentTransactions({
    required this.onSeeAll,
    required this.onAddExpense,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(monthExpensesProvider);
    final recent = all.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent Transactions', style: context.t.h4),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: context.t.buttonSmall.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (all.isEmpty)
          _EmptyTransactions(
            onAddExpense: onAddExpense,
            onAddIncome: onAddIncome,
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  _DeletableTile(e: recent[i], color: _colorFor(recent[i])),
                  if (i != recent.length - 1)
                    Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 16,
                      color: context.c.border,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static Color _colorFor(Expense e) {
    if (e.isIncome) return kGreen;
    final idx = kCategories.indexOf(e.category);
    return kCatColors[idx < 0 ? 0 : idx % kCatColors.length];
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  const _EmptyTransactions({
    required this.onAddExpense,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = context.isDark
        ? AppColors.primaryColor.withOpacity(0.15)
        : kMint;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Icon in a soft double ring
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withOpacity(0.5),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 26,
                    color: kMidGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noEntryYet,
              style: context.t.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Your latest income and expenses will show up here.',
              style: context.t.bodySmall.copyWith(color: context.c.textSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _EmptyAction(
                    icon: Icons.north_east_rounded,
                    label: l10n.expense,
                    filled: true,
                    onTap: onAddExpense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EmptyAction(
                    icon: Icons.south_west_rounded,
                    label: l10n.income,
                    filled: false,
                    onTap: onAddIncome,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _EmptyAction({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = kMidGreen;
    return Material(
      color: filled ? green : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: green.withOpacity(0.35)),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : green),
              const SizedBox(width: 6),
              Text(
                'Add ${label.toLowerCase()}',
                style: context.t.buttonSmall.copyWith(
                  color: filled ? Colors.white : green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletableTile extends ConsumerWidget {
  final Expense e;
  final Color color;
  const _DeletableTile({required this.e, required this.color});

  void _delete(WidgetRef ref) => ref
      .read(adServiceProvider)
      .showRewarded(
        onRewarded: () => ref.read(syncProvider.notifier).deleteExpense(e),
        onNotAvailable: () => ref.read(syncProvider.notifier).deleteExpense(e),
      );

  static String _when(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final time = DateFormat('hh:mm a').format(d);
    if (day == today) return 'Today, $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return '${DateFormat('MMM d').format(d)}, $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sym = currencyOf(e.currency).symbol;
    final amount = NumberFormat('#,##0.##').format(e.amount);

    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: kAccent.withOpacity(0.12),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: kAccent,
          size: 20,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Image.asset(
                  kCatEmoji[e.category] ?? Assets.nodata,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: context.t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.isIncome
                        ? _when(e.date)
                        : '${CategoryLocalization.getName(l10n, e.category)} · ${_when(e.date)}',
                    style: context.t.caption.copyWith(
                      color: context.c.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${e.isIncome ? '+ ' : '- '}$sym$amount',
              style: context.t.amountSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: e.isIncome ? kGreen : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color;
  final String title;

  const _Leg(this.color, this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(title, style: context.t.labelMuted),
      ],
    );
  }
}
