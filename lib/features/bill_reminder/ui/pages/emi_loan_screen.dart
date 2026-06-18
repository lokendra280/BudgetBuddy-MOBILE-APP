import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/emi_loan_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/add_emi_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_strip_alert.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/emi_detail_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/emi_title.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmiLoanScreen — main screen
// ─────────────────────────────────────────────────────────────────────────────

class EmiLoanScreen extends ConsumerWidget {
  const EmiLoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emiLoanProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.emiAndLoans,
          style: context.t.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2,
              ),
            )
          : state.loans.isEmpty
          ? _EmptyEmiState(onAdd: () => _showAddSheet(context, ref))
          : CustomScrollView(
              slivers: [
                // ── Alert strip ─────────────────────────────────────────
                if (state.overdueLoans.isNotEmpty ||
                    state.dueSoonLoans.isNotEmpty)
                  SliverToBoxAdapter(
                    child: BillAlertStrip(
                      overdue: state.overdueLoans,
                      dueSoon: state.dueSoonLoans,
                      fmt: fmt,
                      onTap: () {},
                    ),
                  ),

                // ── Dashboard summary ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _EmiDashboard(state: state, fmt: fmt),
                  ),
                ),

                // ── Section label ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      AppLocalizations.of(context)!.yourLoans,
                      style: context.t.h4,
                    ),
                  ),
                ),

                // ── Loan cards ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: state.loans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => EmiTile(
                      loan: state.loans[i],
                      fmt: fmt,
                      onTap: () =>
                          _showDetailSheet(context, ref, state.loans[i]),
                      onEdit: () =>
                          _showAddSheet(context, ref, existing: state.loans[i]),
                      onDelete: () =>
                          _confirmDelete(context, ref, state.loans[i]),
                      onToggle: () => ref
                          .read(emiLoanProvider.notifier)
                          .toggleActive(state.loans[i].id),
                      onPay: () =>
                          _showPaySheet(context, ref, state.loans[i], fmt),
                    ),
                  ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.addLoan,
          style: AppTypography.buttonSmall.colored(Colors.white),
        ),
      ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────

  static void _showAddSheet(
    BuildContext context,
    WidgetRef ref, {
    EmiLoan? existing,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddEmiSheet(existing: existing),
  );

  static void _showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    EmiLoan loan,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => EmiDetailSheet(loan: loan),
  );

  static void _showPaySheet(
    BuildContext context,
    WidgetRef ref,
    EmiLoan loan,
    String Function(double) fmt,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecordPaymentSheet(loan: loan, fmt: fmt),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmiLoan loan,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        title: Text(
          AppLocalizations.of(context)!.deleteLoan,
          style: AppTypography.h3,
        ),
        content: Text(
          AppLocalizations.of(context)!.willBeRemoved(loan.title),
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTypography.body.colored(kAccent),
            ),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(emiLoanProvider.notifier).deleteLoan(loan.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard summary card
// ─────────────────────────────────────────────────────────────────────────────

class _EmiDashboard extends StatelessWidget {
  final EmiLoanState state;
  final String Function(double) fmt;
  const _EmiDashboard({required this.state, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      child: Column(
        children: [
          // Top row: outstanding + monthly EMI
          Row(
            children: [
              _DashTile(
                label: 'Total Outstanding',
                value: fmt(state.totalOutstanding),
                color: kAccent,
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(width: 12),
              _DashTile(
                label: 'Monthly EMIs',
                value: fmt(state.totalMonthlyEmi),
                color: AppColors.primaryColor,
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 12),
          // Bottom row: active / overdue / missed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill(
                '${state.activeLoans.length}',
                AppLocalizations.of(context)!.active,
                AppColors.primaryColor,
              ),
              _StatPill(
                '${state.overdueLoans.length}',
                AppLocalizations.of(context)!.overdue,
                kAccent,
              ),
              _StatPill(
                '${state.totalMissedPayments}',
                AppLocalizations.of(context)!.missed,
                kAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _DashTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.amount.colored(color)),
          Text(
            label,
            style: AppTypography.caption.colored(context.c.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTypography.h3.colored(color)),
      Text(label, style: AppTypography.caption),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyEmiState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyEmiState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🏦', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noLoansYet, style: context.t.h2),
          const SizedBox(height: 8),
          Text(
            'Track EMIs, monitor progress and get reminded before due dates.',
            style: context.t.bodySub,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: AppLocalizations.of(context)!.addFirstLoan,
            onTap: onAdd,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Record Payment bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final EmiLoan loan;
  final String Function(double) fmt;
  const _RecordPaymentSheet({required this.loan, required this.fmt});

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isExtra = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.loan.emiAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);

    final payment = EmiPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      isExtraPayment: _isExtra,
      note: _noteCtrl.text.trim(),
    );

    if (_isExtra) {
      await ref
          .read(emiLoanProvider.notifier)
          .recordExtraPayment(widget.loan.id, amount, _noteCtrl.text.trim());
    } else {
      await ref
          .read(emiLoanProvider.notifier)
          .recordPayment(widget.loan.id, payment);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context)!.recordPayment,
            style: context.t.h3,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.loan.title} · ${AppLocalizations.of(context)!.emi}${widget.fmt(widget.loan.emiAmount)}',
            style: context.t.bodySub,
          ),
          const SizedBox(height: 18),

          // Amount field
          InputField(
            hint: AppLocalizations.of(context)!.amount,
            controller: _amountCtrl,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            prefix: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.loan.currency,
                style: AppTypography.body.colored(AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Note field
          InputField(
            hint: AppLocalizations.of(context)!.notesOptional,
            controller: _noteCtrl,
          ),
          const SizedBox(height: 12),

          // Extra payment toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.extraPartPayment,
                      style: context.t.labelLarge,
                    ),
                    Text(
                      AppLocalizations.of(context)!.reducesPrincipal,
                      style: context.t.labelMuted,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isExtra,
                onChanged: (v) => setState(() => _isExtra = v),
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          AppButton(
            label: _saving
                ? AppLocalizations.of(context)!.saved
                : (_isExtra ? 'Record Extra Payment' : 'Mark as Paid'),
            onTap: _saving ? () {} : _save,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}
