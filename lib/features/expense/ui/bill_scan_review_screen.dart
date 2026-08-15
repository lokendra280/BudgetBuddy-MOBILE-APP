// lib/expense/ui/pages/bill_scan_review_screen.dart
//
// Shown after a successful scan (Gemini or ML Kit — either produces a
// BillScanResult). Lets the user review each detected line item, flip it
// between Expense/Income, edit the amount if OCR got it slightly wrong,
// deselect items that shouldn't be added, then commits the selected ones
// via ExpenseProvider — same notifier AddExpenseScreen already uses.

import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/expense/services/bill_scaning_service.dart';
import 'package:budgetBuddy/features/expense/services/category_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ReviewItem {
  final BillItem original;
  bool included;
  bool isIncome;
  final TextEditingController amountController;
  final TextEditingController nameController;

  _ReviewItem(this.original)
    : included = true,
      isIncome = false,
      amountController = TextEditingController(
        text: original.amount.toStringAsFixed(2),
      ),
      nameController = TextEditingController(text: original.name);

  double get parsedAmount => double.tryParse(amountController.text) ?? 0;

  void dispose() {
    amountController.dispose();
    nameController.dispose();
  }
}

class BillScanReviewScreen extends ConsumerStatefulWidget {
  final BillScanResult result;

  const BillScanReviewScreen({super.key, required this.result});

  @override
  ConsumerState<BillScanReviewScreen> createState() =>
      _BillScanReviewScreenState();
}

class _BillScanReviewScreenState extends ConsumerState<BillScanReviewScreen> {
  late final List<_ReviewItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.result.items.map(_ReviewItem.new).toList();
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  int get _includedCount => _items.where((i) => i.included).length;

  void _saveSelected() {
    final selected = _items.where((i) => i.included && i.parsedAmount > 0);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to add')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final notifier = ref.read(expenseProvider.notifier);

    for (final item in selected) {
      final cats = item.isIncome
          ? CategoryService.incomeCategories
          : CategoryService.expenseCategories;
      notifier.addExpense(
        title: item.nameController.text.trim(),
        amount: item.parsedAmount,
        category: cats.isNotEmpty ? cats.first.name : '',
        isIncome: item.isIncome,
        date: DateTime.now(),
      );
    }

    Navigator.of(context)
      ..pop() // review screen
      ..pop(); // (if pushed on top of a scan trigger screen) — remove this
    // second pop if BillScanReviewScreen is pushed directly on the
    // dashboard rather than on top of another screen.

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${selected.length} item(s)')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: const Text(
          'Review Bill',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (widget.result.merchant != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 16, color: c.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    widget.result.merchant!,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_includedCount of ${_items.length} selected',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ItemCard(item: _items[i], onChanged: () => setState(() {})),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Add $_includedCount Item${_includedCount == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final _ReviewItem item;
  final VoidCallback onChanged;

  const _ItemCard({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = item.isIncome ? kGreen : kAccent;

    return Opacity(
      opacity: item.included ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.included ? accent.withOpacity(0.3) : c.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.included,
                  activeColor: accent,
                  onChanged: (v) {
                    item.included = v ?? true;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: item.nameController,
                    enabled: item.included,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: item.amountController,
                      enabled: item.included,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '${item.original.currency} ',
                        prefixStyle: TextStyle(
                          fontSize: 12,
                          color: c.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  _TypeToggle(
                    isIncome: item.isIncome,
                    enabled: item.included,
                    onChanged: (v) {
                      item.isIncome = v;
                      onChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isIncome;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({
    required this.isIncome,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget seg(String label, bool value, Color color) => GestureDetector(
      onTap: enabled ? () => onChanged(value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isIncome == value ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isIncome == value ? Colors.white : c.textMuted,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('Expense', false, kAccent), seg('Income', true, kGreen)],
      ),
    );
  }
}
