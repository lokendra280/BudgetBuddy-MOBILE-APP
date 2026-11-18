import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/budgeting/providers/budget_planner_provider.dart';
import 'package:budgetbuddy/features/budgeting/ui/pages/edit_budget_screen.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_allocation_card.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_overview_card.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_style.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/category_budget_tile.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetPlannerScreen extends ConsumerWidget {
  const BudgetPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(budgetOverviewProvider);
    final statuses = ref.watch(categoryBudgetStatusesProvider);
    final unbudgeted = ref.watch(unbudgetedSpendProvider);
    final fmt = ref.watch(fmtProvider);

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        // Style comes from appBarTheme (AppTypography.appBarTitle).
        title: Text(l10n.budgetPlanner),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          BudgetOverviewCard(
            onEditLimit: () => open(const EditBudgetScreen.monthlyLimit()),
          ),
          if (overview.hasLimit) ...[
            const SizedBox(height: 12),
            const BudgetAllocationCard(),
          ],
          const SizedBox(height: 22),

          // ── Category budgets ────────────────────────────────────────────
          SectionLabel(l10n.categoryBudgets),
          const SizedBox(height: 12),
          if (statuses.isEmpty)
            AppCard(
              child: Text(l10n.categoryBudgetsEmpty, style: context.t.bodySub),
            )
          else
            for (final s in statuses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CategoryBudgetTile(
                  status: s,
                  onTap: () =>
                      open(EditBudgetScreen.editCategory(category: s.category)),
                ),
              ),
          const SizedBox(height: 12),
          AppButton(
            label: l10n.addCategoryBudget,
            icon: Icons.add_rounded,
            onTap: () => open(const EditBudgetScreen.newCategory()),
          ),

          // ── Spending with no budget ─────────────────────────────────────
          if (unbudgeted.isNotEmpty) ...[
            const SizedBox(height: 26),
            SectionLabel(l10n.spendingWithoutBudget),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  for (final e in unbudgeted.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CategoryIconTile(category: e.key),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key, style: context.t.labelLarge),
                                Text(
                                  l10n.amountSpent(fmt(e.value)),
                                  style: context.t.labelMuted,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => open(
                              EditBudgetScreen.newCategory(category: e.key),
                            ),
                            child: Text(
                              l10n.setBudget,
                              style: context.t.buttonSmall.colored(
                                AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
