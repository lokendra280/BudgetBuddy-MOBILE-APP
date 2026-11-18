import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/budgeting/providers/budget_planner_provider.dart';
import 'package:budgetbuddy/features/budgeting/ui/widgets/budget_style.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditBudgetMode { monthlyLimit, newCategory, editCategory }

/// One screen for all three budget edits. It's a pushed route, not a
/// bottom sheet — same reason as your currency picker (ref.watch reactivity).
class EditBudgetScreen extends ConsumerStatefulWidget {
  final EditBudgetMode mode;
  final String? category;

  const EditBudgetScreen.monthlyLimit({super.key})
    : mode = EditBudgetMode.monthlyLimit,
      category = null;

  /// [category] pre-selects a chip (used by "Set budget" on unbudgeted spend).
  const EditBudgetScreen.newCategory({super.key, this.category})
    : mode = EditBudgetMode.newCategory;

  const EditBudgetScreen.editCategory({
    super.key,
    required String this.category,
  }) : mode = EditBudgetMode.editCategory;

  @override
  ConsumerState<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends ConsumerState<EditBudgetScreen> {
  final _ctrl = TextEditingController();
  String? _selected;

  bool get _isMonthly => widget.mode == EditBudgetMode.monthlyLimit;

  @override
  void initState() {
    super.initState();
    _selected = widget.category;
    final initial = _isMonthly
        ? ref.read(budgetProvider).monthlyLimit
        : ref.read(categoryBudgetsProvider)[widget.category];
    if (initial != null && initial > 0) {
      _ctrl.text = initial.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color col) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: col,
          behavior: SnackBarBehavior.floating,
        ),
      );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final value = double.tryParse(_ctrl.text.replaceAll(',', ''));
    if (value == null || value <= 0) {
      _snack(l10n.enterValidAmount, kAccent);
      return;
    }
    if (!_isMonthly && _selected == null) {
      _snack(l10n.chooseCategory, kAccent);
      return;
    }

    HapticFeedback.mediumImpact();
    if (_isMonthly) {
      await ref.read(expenseProvider.notifier).updateBudget(limit: value);
    } else {
      await ref
          .read(categoryBudgetsProvider.notifier)
          .setBudget(_selected!, value);
    }
    if (!mounted) return;
    _snack(l10n.budgetSaved, kGreen);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(categoryBudgetsProvider.notifier).remove(widget.category!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final symbol = ref.watch(symbolProvider);
    final fmt = ref.watch(fmtProvider);
    final overview = ref.watch(budgetOverviewProvider);
    final spentBy = ref.watch(byCategoryProvider);
    final options = ref.watch(availableBudgetCategoriesProvider);

    final title = switch (widget.mode) {
      EditBudgetMode.monthlyLimit => l10n.monthlybudget,
      EditBudgetMode.newCategory => l10n.newCategoryBudget,
      EditBudgetMode.editCategory => widget.category!,
    };

    final spentHint = _isMonthly
        ? overview.spent
        : (_selected == null ? null : spentBy[_selected] ?? 0);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── Category picker (new budgets only) ──────────────────────────
          if (widget.mode == EditBudgetMode.newCategory) ...[
            SectionLabel(l10n.category),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in options)
                  _CategoryChip(
                    category: cat,
                    selected: cat == _selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = cat);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          // ── Amount ──────────────────────────────────────────────────────
          SectionLabel(
            _isMonthly ? l10n.monthlySpendingLimit : l10n.monthlyLimit,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputField(
                  hint: l10n.amount,
                  controller: _ctrl,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      symbol,
                      style: context.t.amount.colored(AppColors.primaryColor),
                    ),
                  ),
                ),
                if (spentHint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.spentThisMonth(fmt(spentHint)),
                    style: context.t.labelMuted,
                  ),
                ],
                if (!_isMonthly && overview.hasLimit && overview.unassigned > 0)
                  Text(
                    l10n.notAssignedYet(fmt(overview.unassigned)),
                    style: context.t.labelMuted,
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: l10n.saveBudget,
                  icon: Icons.check_rounded,
                  onTap: _save,
                ),
              ],
            ),
          ),

          // ── Delete (existing category only) ─────────────────────────────
          if (widget.mode == EditBudgetMode.editCategory) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: kAccent,
                  size: 18,
                ),
                label: Text(
                  l10n.removeBudget,
                  style: context.t.buttonSmall.colored(kAccent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor.withOpacity(0.08) : c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryColor : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(category),
              size: 16,
              color: categoryColor(category),
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: selected
                  ? context.t.labelLarge.colored(AppColors.primaryColor)
                  : context.t.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
