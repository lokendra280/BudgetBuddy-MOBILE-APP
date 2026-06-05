import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddBillSheet extends ConsumerStatefulWidget {
  final BillReminder? existing;
  final String sym;
  const AddBillSheet({this.existing, required this.sym});
  @override
  ConsumerState<AddBillSheet> createState() => _AddState();
}

class _AddState extends ConsumerState<AddBillSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = kBillCategories[0];
  int _dayOfMonth = 1;
  int _remindDays = 3;
  bool _isRecurring = true;
  bool _saving = false;
  DateTime? _oneTimeDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _category = e.category;
      _dayOfMonth = e.dayOfMonth;
      _remindDays = e.remindDaysBefore;
      _isRecurring = e.isRecurring;
      _oneTimeDate = e.nextDueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final notifier = ref.read(billReminderProvider.notifier);
    final sym = ref.read(currencyProvider);

    final bill = BillReminder(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      category: _category,
      dayOfMonth: _dayOfMonth,
      currency: sym,
      remindDaysBefore: _remindDays,
      isRecurring: _isRecurring,
      nextDueDate: _oneTimeDate,
      emoji: kBillEmojis[_category] ?? '📋',
    );

    widget.existing != null
        ? await notifier.update(bill)
        : await notifier.add(bill);
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
              widget.existing != null ? 'Edit Bill' : 'Add Bill / EMI',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),

            // Title
            InputField(
              hint: 'Bill name (e.g. Netflix, Home EMI)',
              controller: _titleCtrl,
              prefix: CommonSvgWidget(
                svgName: kBillEmojis[_category] ?? '📋',
                height: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            InputField(
              hint: 'Amount',
              controller: _amountCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              prefix: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.sym,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category picker
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kBillCategories
                    .map(
                      (cat) => GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _category == cat
                                ? AppColors.primaryColor
                                : c.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _category == cat
                                  ? AppColors.primaryColor
                                  : c.border,
                            ),
                          ),
                          child: CommonSvgWidget(
                            svgName: kBillEmojis[cat] ?? '📋',
                            height: 30,
                            width: 30,
                            color: _category == cat ? Colors.white : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recurring monthly',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isRecurring
                            ? 'Repeats every month'
                            : 'One-time payment',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Due day (recurring) or date picker (one-time)
            if (_isRecurring) ...[
              Text(
                'Due on day of month',
                style: TextStyle(
                  fontSize: 12,
                  color: c.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 5, 7, 10, 15, 20, 25, 28]
                      .map(
                        (d) => GestureDetector(
                          onTap: () => setState(() => _dayOfMonth = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _dayOfMonth == d
                                  ? AppColors.primaryColor
                                  : c.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dayOfMonth == d
                                    ? AppColors.primaryColor
                                    : c.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$d',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _dayOfMonth == d
                                      ? Colors.white
                                      : c.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _oneTimeDate ??
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _oneTimeDate = d);
                },
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
                        _oneTimeDate != null
                            ? DateFormat('MMM d, yyyy').format(_oneTimeDate!)
                            : 'Select due date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _oneTimeDate != null ? null : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Remind days before
            Text(
              'Remind me before',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 5, 7]
                  .map(
                    (d) => GestureDetector(
                      onTap: () => setState(() => _remindDays = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _remindDays == d ? kGreen : c.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _remindDays == d ? kGreen : c.border,
                          ),
                        ),
                        child: Text(
                          '$d day${d == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _remindDays == d
                                ? Colors.white
                                : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            AppButton(
              label: _saving
                  ? 'Saving…'
                  : (widget.existing != null
                        ? 'Update Bill'
                        : 'Add & Schedule Reminder'),
              onTap: _saving ? () {} : _save,
              icon: Icons.notifications_active_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
