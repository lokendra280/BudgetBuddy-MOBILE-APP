import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';

import 'package:budgetbuddy/features/budgeting/models/budget_plan.dart';
import 'package:budgetbuddy/features/budgeting/providers/budget_planner_provider.dart';
import 'package:budgetbuddy/features/budgeting/ui/pages/budget_planner_screen.dart';
import 'package:budgetbuddy/features/budgeting/ui/pages/edit_budget_screen.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_progress_bar.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_style.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetPromptCard extends ConsumerWidget {
  const BudgetPromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final step = ref.watch(budgetSetupStepProvider);
    final o = ref.watch(budgetOverviewProvider);
    final fmt = ref.watch(fmtProvider);

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    switch (step) {
      case BudgetSetupStep.setLimit:
        return _SetupCard(
          icon: Icons.savings_rounded,
          title: l10n.setYourMonthlyBudget,
          body: l10n.setYourMonthlyBudgetDesc,
          action: l10n.setBudget,
          onTap: () => open(const EditBudgetScreen.monthlyLimit()),
        );

      case BudgetSetupStep.planCategories:
        return _SetupCard(
          icon: Icons.pie_chart_rounded,
          title: l10n.planYourBudget,
          body: l10n.planYourBudgetDesc(fmt(o.limit)),
          action: l10n.planNow,
          onTap: () => open(const BudgetPlannerScreen()),
        );

      case BudgetSetupStep.done:
        final overCount = ref
            .watch(categoryBudgetStatusesProvider)
            .where((s) => s.isOver)
            .length;

        final String status;
        final Color statusColor;
        if (o.health == BudgetHealth.over) {
          status = l10n.overBy(fmt(-o.remaining));
          statusColor = kAccent;
        } else if (overCount > 0) {
          status = l10n.categoriesOverBudget(overCount);
          statusColor = kAccent;
        } else if (o.daysLeft > 0) {
          status = l10n.amountLeftPerDay(
            fmt(o.remaining),
            fmt(o.perDayAllowance),
          );
          statusColor = o.health.color;
        } else {
          status = l10n.amountLeft(fmt(o.remaining));
          statusColor = o.health.color;
        }

        return _StatusCard(
          title: l10n.budgetPlan,
          status: status,
          statusColor: statusColor,
          ratio: o.ratio,
          barColor: o.health.color,
          onTap: () => open(const BudgetPlannerScreen()),
        );
    }
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.primaryColor.withOpacity(0.06),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.t.h4),
                const SizedBox(height: 4),
                Text(body, style: context.t.bodySub),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    action,
                    style: context.t.buttonSmall.colored(AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final double ratio;
  final Color barColor;
  final VoidCallback onTap;

  const _StatusCard({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.ratio,
    required this.barColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.t.labelLarge),
                    Text(
                      status,
                      style: context.t.labelSmall
                          .colored(statusColor)
                          .weighted(FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.c.textMuted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          BudgetProgressBar(value: ratio, color: barColor, height: 6),
        ],
      ),
    );
  }
}
