import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/budgeting/models/budget_plan.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_progress_bar.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_style.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryBudgetTile extends ConsumerWidget {
  final CategoryBudgetStatus status;
  final VoidCallback onTap;

  const CategoryBudgetTile({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = ref.watch(fmtProvider);
    final color = status.health.color;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIconTile(category: status.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.category, style: context.t.labelLarge),
                    Text(
                      l10n.spentOfLimit(fmt(status.spent), fmt(status.limit)),
                      style: context.t.labelMuted,
                    ),
                  ],
                ),
              ),
              Text(
                '${(status.ratio * 100).round()}%',
                style: context.t.amountSmall
                    .colored(color)
                    .weighted(FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BudgetProgressBar(value: status.ratio, color: color),
          if (status.isOver) ...[
            const SizedBox(height: 6),
            Text(
              l10n.overBy(fmt(-status.remaining)),
              style: context.t.labelSmall
                  .colored(kAccent)
                  .weighted(FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
