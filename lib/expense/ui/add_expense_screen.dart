import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/models/expense.dart';

import 'package:expensetracker/expense/services/bill_scaning_service.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _State();
}

class _State extends State<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  String _cat = kCategories.first;
  bool _isIncome = false;
  bool _scanning = false;

  List<String> get _cats => _isIncome ? kIncomeCategories : kCategories;

  Color get _activeColor => _isIncome ? kGreen : kPrimary;

  void _save() {
    final amt = double.tryParse(_amount.text.replaceAll(',', ''));
    if (amt == null || amt <= 0 || _title.text.trim().isEmpty) {
      _snack('Please fill in amount and title', kAccent);
      return;
    }
    HapticFeedback.mediumImpact();
    final currency = ExpenseService.currency;
    Hive.box<Expense>('expenses').add(
      Expense(
        id: const Uuid().v4(),
        title: _title.text.trim(),
        amount: amt,
        category: _cat,
        date: DateTime.now(),
        isIncome: _isIncome,
        currency: currency,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _showScanOptions() => showModalBottomSheet(
    context: context,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan Bill',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Automatically detect items and total',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: kPrimary),
            ),
            title: const Text(
              'Take a photo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Use camera to scan bill',
              style: TextStyle(fontSize: 12, color: context.c.textMuted),
            ),
            onTap: () {
              Navigator.pop(context);
              _scan(fromCamera: true);
            },
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_rounded, color: kBlue),
            ),
            title: const Text(
              'Choose from gallery',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Pick existing bill photo',
              style: TextStyle(fontSize: 12, color: context.c.textMuted),
            ),
            onTap: () {
              Navigator.pop(context);
              _scan(fromCamera: false);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  Future<void> _scan({required bool fromCamera}) async {
    setState(() => _scanning = true);
    try {
      final result = await BillScannerService.scan(fromCamera: fromCamera);
      if (result == null || !mounted) return;

      if (result.hasItems || result.totalAmount != null) {
        // Show item review sheet
        await _showScanReview(result);
      } else {
        _snack('No items detected. Try a clearer photo.', kAmber);
      }
    } catch (e) {
      if (mounted)
        _snack('Scan failed: ${e.toString().split('\n').first}', kAccent);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _showScanReview(BillScanResult result) async {
    final sym = currencyOf(result.detectedCurrency).symbol;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScanReviewSheet(
        result: result,
        sym: sym,
        onSelectItem: (item) {
          if (mounted)
            setState(() {
              _amount.text = item.amount.toStringAsFixed(0);
              _title.text = item.name;
            });
          Navigator.pop(context);
        },
        onSelectTotal: result.totalAmount == null
            ? null
            : () {
                if (mounted)
                  setState(() {
                    _amount.text = result.totalAmount!.toStringAsFixed(0);
                    _title.text = result.merchant ?? 'Bill Total';
                  });
                Navigator.pop(context);
              },
      ),
    );
  }

  void _snack(String msg, Color col) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: col,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Entry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Scan bill',
              icon: _scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.document_scanner_outlined,
                      color: kPrimary,
                    ),
              onPressed: _scanning ? null : _showScanOptions,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type toggle ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  _TypeBtn(
                    'Expense',
                    !_isIncome,
                    kAccent,
                    () => setState(() {
                      _isIncome = false;
                      _cat = kCategories.first;
                    }),
                  ),
                  _TypeBtn(
                    'Income',
                    _isIncome,
                    kGreen,
                    () => setState(() {
                      _isIncome = true;
                      _cat = kIncomeCategories.first;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Amount card ────────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      color: c.textMuted,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        ExpenseService.symbol,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _activeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amount,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: context.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: c.border,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            InputField(
              hint: _isIncome
                  ? 'Source (e.g. Monthly salary)'
                  : 'What did you spend on?',
              controller: _title,
              prefix: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _isIncome ? '💰' : '📝',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 10,
                color: c.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ── Category grid ──────────────────────────────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: _cats.map((cat) {
                final sel = _cat == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _cat = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel ? _activeColor.withOpacity(0.12) : c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? _activeColor : c.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          kCatEmoji[cat] ?? '📦',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: sel ? _activeColor : c.textSub,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            AppButton(
              label: _isIncome ? 'Save Income' : 'Save Expense',
              onTap: _save,
              color: _activeColor,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type toggle button ────────────────────────────────────────────────────────
class _TypeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn(this.label, this.active, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active
                  ? (color == kGreen
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded)
                  : Icons.circle_outlined,
              size: 14,
              color: active ? Colors.white : context.c.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : context.c.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Scan review bottom sheet ──────────────────────────────────────────────────
class _ScanReviewSheet extends StatelessWidget {
  final BillScanResult result;
  final String sym;
  final ValueChanged<BillItem> onSelectItem;
  final VoidCallback? onSelectTotal;
  const _ScanReviewSheet({
    required this.result,
    required this.sym,
    required this.onSelectItem,
    required this.onSelectTotal,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scanned Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.merchant != null)
                      Text(
                        result.merchant!,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap an item to add it as expense',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: c.bg,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Grand total row
                  if (result.totalAmount != null) ...[
                    GestureDetector(
                      onTap: onSelectTotal,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: kGreen.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '🧾',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grand Total',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Use full bill amount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$sym${result.totalAmount!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: c.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'or pick individual items',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: c.border)),
                        ],
                      ),
                    ),
                  ],

                  // Individual items
                  if (result.items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              'No individual items found',
                              style: TextStyle(color: c.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try using Grand Total above',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...result.items.asMap().entries.map(
                      (e) => GestureDetector(
                        onTap: () => onSelectItem(e.value),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$sym${e.value.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
