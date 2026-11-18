import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/budgeting/models/budget_plan.dart';
import 'package:budgetbuddy/features/budgeting/providers/budget_planner_provider.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_progress_bar.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_style.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetOverviewCard extends ConsumerWidget {
  final VoidCallback onEditLimit;

  const BudgetOverviewCard({super.key, required this.onEditLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final o = ref.watch(budgetOverviewProvider);
    final fmt = ref.watch(fmtProvider);
    final health = o.health;

    final status = switch (health) {
      BudgetHealth.notSet => l10n.setLimitToStart,
      BudgetHealth.over => l10n.overBy(fmt(-o.remaining)),
      _ =>
        o.daysLeft > 0
            ? l10n.amountLeftPerDayFor(
                fmt(o.remaining),
                fmt(o.perDayAllowance),
                o.daysLeft,
              )
            : l10n.amountLeft(fmt(o.remaining)),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.monthBudget(localizedMonthName(context, o.month)),
                  style: context.t.bodySub,
                ),
              ),
              GestureDetector(
                onTap: onEditLimit,
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      o.hasLimit ? l10n.editLimit : l10n.setLimit,
                      style: context.t.buttonSmall.colored(
                        AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: fmt(o.spent), style: context.t.amountLarge),
                if (o.hasLimit)
                  TextSpan(
                    text: '  /  ${fmt(o.limit)}',
                    style: context.t.amountSmall.colored(context.c.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BudgetProgressBar(value: o.ratio, color: health.color),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(health.icon, size: 14, color: health.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: context.t.labelLarge.colored(health.color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
