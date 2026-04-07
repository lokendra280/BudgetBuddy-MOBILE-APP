import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/paywall_screen.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/premium_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/expense/ui/add_expense_screen.dart';
import 'package:expensetracker/home/ui/inslight_screen.dart';
import 'package:expensetracker/profile/ui/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Hive.box<Expense>('expenses').listenable(),
    builder: (_, __, ___) {
      ExpenseService.updateStreak();
      final expenses = ExpenseService.forMonth(DateTime.now());
      final total = ExpenseService.totalFor(expenses);
      final budget = ExpenseService.budget;
      final (thisW, lastW) = ExpenseService.weekComparison();
      final c = context.c;

      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _Header(total: total, budget: budget),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _MetricsRow(
                          expenses: expenses,
                          total: total,
                          budget: budget,
                        ),
                        const SizedBox(height: 16),
                        _WasteInsight(thisW: thisW, lastW: lastW),
                        const SizedBox(height: 16),
                        _WeekSection(thisW: thisW, lastW: lastW),
                        const SizedBox(height: 16),
                        SectionLabel(
                          'Recent',
                          trailing: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InsightsScreen(),
                              ),
                            ),
                            child: const Text(
                              'See all →',
                              style: TextStyle(fontSize: 12, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (expenses.isEmpty) _Empty(),
                        ...expenses.take(10).map((e) {
                          final idx = kCategories.indexOf(e.category);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpenseTile(
                              e: e,
                              color:
                                  kCatColors[idx < 0
                                      ? 0
                                      : idx % kCatColors.length],
                              onDelete: () {
                                e.delete();
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
            // ── Banner ad sits just above the nav bar ──
            const BannerAdWidget(),
          ],
        ),
        bottomNavigationBar: _BottomBar(context),
      );
    },
  );
}

class _Header extends StatelessWidget {
  final double total;
  final Budget budget;
  const _Header({required this.total, required this.budget});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        22,
      ),
      color: context.c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good day 👋',
                    style: TextStyle(fontSize: 12, color: context.c.textMuted),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'SpendSense',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Spacer(),
              if (PremiumService.isPremium)
                const PremiumBadge()
              else
                StreakBadge(days: budget.streakDays),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'spent this month',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
          const SizedBox(height: 14),
          BudgetBar(percent: ExpenseService.budgetUsedPercent()),
        ],
      ),
    ),
  );
}

class _MetricsRow extends StatelessWidget {
  final List<Expense> expenses;
  final double total;
  final Budget budget;
  const _MetricsRow({
    required this.expenses,
    required this.total,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        MetricCard(
          label: 'transactions',
          value: '${expenses.length}',
          color: kPrimary,
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(width: 10),
        MetricCard(
          label: 'budget left',
          value:
              '₹${(budget.monthlyLimit - total).clamp(0, 99999).toStringAsFixed(0)}',
          color: total > budget.monthlyLimit ? kAccent : kGreen,
          icon: Icons.savings_outlined,
        ),
      ],
    ),
  );
}

class _WasteInsight extends StatelessWidget {
  final double thisW, lastW;
  const _WasteInsight({required this.thisW, required this.lastW});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('💡', style: TextStyle(fontSize: 17)),
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
  );
}

class _WeekSection extends StatelessWidget {
  final double thisW, lastW;
  const _WeekSection({required this.thisW, required this.lastW});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Week vs last week'),
        const SizedBox(height: 14),
        WeekCompareBar(thisWeek: thisW, lastWeek: lastW),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text('💸', style: TextStyle(fontSize: 36)),
          SizedBox(height: 10),
          Text(
            'No expenses yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to start tracking',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final BuildContext ctx;
  const _BottomBar(this.ctx);

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: ctx.c.surface,
        border: Border(top: BorderSide(color: ctx.c.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(Icons.home_rounded, 'Home', true, () {}),
          _NavBtn(
            Icons.bar_chart_rounded,
            'Insights',
            false,
            () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const InsightsScreen()),
            ),
          ),
          _AddBtn(ctx),
          _NavBtn(
            Icons.star_outline_rounded,
            'Premium',
            false,
            () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
          _NavBtn(
            Icons.settings_outlined,
            'Settings',
            false,
            () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final BuildContext ctx;
  const _AddBtn(this.ctx);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
      ).then((_) => AdService.trackAction());
    },
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimary, Color(0xFF9D8FFF)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn(this.icon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: active ? kPrimary : context.c.textMuted),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active ? kPrimary : context.c.textMuted,
          ),
        ),
      ],
    ),
  );
}
