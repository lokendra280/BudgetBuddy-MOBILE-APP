import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/emi_loan_provider.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEmiSheet extends ConsumerStatefulWidget {
  final EmiLoan? existing;
  const AddEmiSheet({super.key, this.existing});

  @override
  ConsumerState<AddEmiSheet> createState() => _AddEmiSheetState();
}

class _AddEmiSheetState extends ConsumerState<AddEmiSheet> {
  final _titleCtrl = TextEditingController();
  final _lenderCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = kLoanCategories[2]; // 'Personal'
  int _dayOfMonth = 1;
  int _remindDays = 3;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  bool _autoCalcEmi = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _lenderCtrl.text = e.lenderName;
      _principalCtrl.text = e.principalAmount.toStringAsFixed(0);
      _emiCtrl.text = e.emiAmount.toStringAsFixed(0);
      _rateCtrl.text = e.interestRate.toString();
      _tenureCtrl.text = (e.tenureMonths / 12).toString();
      _notesCtrl.text = e.notes;
      _category = e.category;
      _dayOfMonth = e.dayOfMonth;
      _remindDays = e.remindDaysBefore;
      _startDate = e.startDate;
      _autoCalcEmi = false;
    }
    _principalCtrl.addListener(_recalcEmi);
    _rateCtrl.addListener(_recalcEmi);
    _tenureCtrl.addListener(_recalcEmi);
  }

  void _recalcEmi() {
    if (!_autoCalcEmi) return;
    final p = double.tryParse(_principalCtrl.text) ?? 0;
    final r = double.tryParse(_rateCtrl.text) ?? 0;
    final years = double.tryParse(_tenureCtrl.text) ?? 0;
    final n = (years * 12).round(); // convert years -> months
    if (p <= 0 || n <= 0) {
      _emiCtrl.clear();
      return;
    }
    final emi = r <= 0 ? p / n : _calcEmi(p, r, n);
    _emiCtrl.text = emi.toStringAsFixed(0);
  }

  double _calcEmi(double p, double annualRate, int n) {
    final r = annualRate / 12 / 100;
    final pow = _powD(1 + r, n);
    return p * r * pow / (pow - 1);
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _lenderCtrl,
      _principalCtrl,
      _emiCtrl,
      _rateCtrl,
      _tenureCtrl,
      _notesCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    final title = _titleCtrl.text.trim();
    final lender = _lenderCtrl.text.trim();
    final principal = double.tryParse(_principalCtrl.text.replaceAll(',', ''));
    final emi = double.tryParse(_emiCtrl.text.replaceAll(',', ''));
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final years = double.tryParse(_tenureCtrl.text) ?? 0;
    final tenureMonths = (years * 12)
        .round(); // ✅ convert years -> months, once
    if (title.isEmpty || principal == null || emi == null || tenureMonths <= 0)
      return;

    setState(() => _saving = true);
    final currency = ref.read(currencyProvider);

    final loan = EmiLoan(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      lenderName: lender.isEmpty ? l10n.lenderUnknown : lender,
      principalAmount: principal,
      emiAmount: emi,
      interestRate: rate,
      tenureMonths: tenureMonths,
      startDate: _startDate,
      dayOfMonth: _dayOfMonth,
      currency: currency,
      category: _category,
      emoji: kLoanEmojis[_category] ?? '🏦',
      remindDaysBefore: _remindDays,
      notes: _notesCtrl.text.trim(),
      payments: widget.existing?.payments ?? const [],
      totalExtraPayments: widget.existing?.totalExtraPayments ?? 0,
    );

    widget.existing != null
        ? await ref.read(emiLoanProvider.notifier).updateLoan(loan)
        : await ref.read(emiLoanProvider.notifier).addLoan(loan);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _startDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    // ── "day" / "days" suffix localised ─────────────────────────────────────
    String dayLabel(int d) => '$d ${d == 1 ? l10n.day : l10n.days}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ────────────────────────────────────────────────────
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

            // ── Title ─────────────────────────────────────────────────────
            Text(
              widget.existing != null ? l10n.editLoan : l10n.addEmiLoan,
              style: context.t.h3,
            ),
            const SizedBox(height: 18),

            // ── Loan name ─────────────────────────────────────────────────
            InputField(
              hint: l10n.loanNameHint,
              controller: _titleCtrl,
              prefix: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  kLoanEmojis[_category] ?? '🏦',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Lender ────────────────────────────────────────────────────
            InputField(hint: l10n.lenderHint, controller: _lenderCtrl),
            const SizedBox(height: 14),

            // ── Category ──────────────────────────────────────────────────
            Text(l10n.category, style: context.t.labelMuted),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kLoanCategories.map((cat) {
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _category = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryColor : c.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primaryColor : c.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            kLoanEmojis[cat] ?? '🏦',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat,
                            style: AppTypography.caption.colored(
                              sel ? Colors.white : c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Principal + Rate ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: InputField(
                    hint: l10n.principalAmount,
                    controller: _principalCtrl,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputField(
                    hint: l10n.ratePerAnnum,
                    controller: _rateCtrl,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Tenure ────────────────────────────────────────────────────
            InputField(
              hint: l10n.tenureMonths,
              controller: _tenureCtrl,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // ── Auto-calc toggle ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.autoCalcEmi, style: context.t.labelLarge),
                      Text(l10n.autoCalcEmiSub, style: context.t.labelMuted),
                    ],
                  ),
                ),
                Switch(
                  value: _autoCalcEmi,
                  onChanged: (v) {
                    setState(() => _autoCalcEmi = v);
                    if (v) _recalcEmi();
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── EMI amount ────────────────────────────────────────────────
            InputField(
              hint: l10n.monthlyEmiAmount,
              controller: _emiCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_autoCalcEmi,
            ),
            const SizedBox(height: 16),

            // ── Start date ────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickStartDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.loanStarted(
                        DateFormat('MMM d, yyyy').format(_startDate),
                      ),
                      style: context.t.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Due day ───────────────────────────────────────────────────
            Text(l10n.emiDueDay, style: context.t.labelMuted),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 5, 7, 10, 15, 20, 25, 28].map((d) {
                  final sel = _dayOfMonth == d;
                  return GestureDetector(
                    onTap: () => setState(() => _dayOfMonth = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryColor : c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.primaryColor : c.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$d',
                          style: AppTypography.caption.colored(
                            sel ? Colors.white : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // ── Remind days ───────────────────────────────────────────────
            Text(l10n.remindMeBefore, style: context.t.labelMuted),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 2, 3, 5, 7].map((d) {
                  final sel = _remindDays == d;
                  return GestureDetector(
                    onTap: () => setState(() => _remindDays = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? kGreen : c.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? kGreen : c.border),
                      ),
                      child: Text(
                        dayLabel(d),
                        style: AppTypography.caption.colored(
                          sel ? Colors.white : c.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // ── Notes ─────────────────────────────────────────────────────
            InputField(hint: l10n.notesOptional, controller: _notesCtrl),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────────
            AppButton(
              label: _saving
                  ? l10n.saving
                  : (widget.existing != null ? l10n.updateLoan : l10n.addLoan),
              onTap: _saving ? () {} : () => _save(l10n),
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

double _powD(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) r *= base;
  return r;
}
