import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/budgeting/providers/budget_planner_provider.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows how much of the monthly limit is split into categories,
/// and warns when category budgets add up to more than the limit.
class BudgetAllocationCard extends ConsumerWidget {
  const BudgetAllocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final o = ref.watch(budgetOverviewProvider);
    final fmt = ref.watch(fmtProvider);
    final over = o.overPlanned;

    return AppCard(
      color: over ? kAccent.withOpacity(0.07) : null,
      child: Row(
        children: [
          Icon(
            over
                ? Icons.warning_amber_rounded
                : Icons.pie_chart_outline_rounded,
            size: 18,
            color: over ? kAccent : AppColors.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              over
                  ? l10n.categoryBudgetsOverLimit(fmt(-o.unassigned))
                  : l10n.plannedNotAssigned(fmt(o.assigned), fmt(o.unassigned)),
              style: over
                  ? context.t.labelLarge.colored(kAccent)
                  : context.t.bodySub,
            ),
          ),
        ],
      ),
    );
  }
}
