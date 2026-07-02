import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/emi_loan_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/services/emi_cycle_service.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final String loanId;
  final String Function(double) fmt;
  const RecordPaymentSheet({required this.loanId, required this.fmt});

  @override
  ConsumerState<RecordPaymentSheet> createState() => RecordPaymentSheetState();
}

class RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isExtra = false;
  bool _saving = false;
  bool _initialized = false;

  EmiLoan? _loan(WidgetRef ref) => ref
      .watch(emiLoanProvider)
      .loans
      .where((l) => l.id == widget.loanId)
      .cast<EmiLoan?>()
      .firstWhere((_) => true, orElse: () => null);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(EmiLoan loan) async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    if (!_isExtra && EmiCycleService.paidForCurrentCycle(loan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EMI for this month is already paid.')),
      );
      return;
    }

    setState(() => _saving = true);

    bool success;
    if (_isExtra) {
      await ref
          .read(emiLoanProvider.notifier)
          .recordExtraPayment(loan.id, amount, _noteCtrl.text.trim());
      success = true;
    } else {
      final payment = EmiPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: amount,
        isExtraPayment: false,
        note: _noteCtrl.text.trim(),
      );
      success = await ref
          .read(emiLoanProvider.notifier)
          .recordPayment(loan.id, payment);
    }

    if (!success) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EMI for this month is already paid.')),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loan = _loan(ref);
    if (loan == null) return const SizedBox.shrink(); // loan deleted mid-flow

    final alreadyPaid = EmiCycleService.paidForCurrentCycle(loan);

    if (!_initialized) {
      _amountCtrl.text = loan.emiAmount.toStringAsFixed(0);
      if (alreadyPaid) _isExtra = true;
      _initialized = true;
    }

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
          Text('Record Payment', style: context.t.h3),
          const SizedBox(height: 4),
          Text(
            '${loan.title} · EMI ${widget.fmt(loan.emiAmount)}',
            style: context.t.bodySub,
          ),
          const SizedBox(height: 18),
          InputField(
            hint: 'Amount',
            controller: _amountCtrl,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            prefix: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                loan.currency,
                style: AppTypography.body.colored(AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InputField(hint: 'Note (optional)', controller: _noteCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extra / Part Payment', style: context.t.labelLarge),
                    Text(
                      alreadyPaid
                          ? 'Regular EMI already paid this month — only extra payments allowed.'
                          : AppLocalizations.of(context)!.reducesPrincipal,
                      style: context.t.labelMuted,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isExtra,
                onChanged: alreadyPaid
                    ? null
                    : (v) => setState(() => _isExtra = v),
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _saving
                ? 'Saving…'
                : (_isExtra ? 'Record Extra Payment' : 'Mark as Paid'),
            onTap: _saving ? () {} : () => _save(loan),
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}
