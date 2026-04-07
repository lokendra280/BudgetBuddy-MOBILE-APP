import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/models/expense.dart' hide kCategories;
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

  void _save() {
    final amt = double.tryParse(_amount.text);
    if (amt == null || amt <= 0 || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: kAccent,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Hive.box<Expense>('expenses').add(
      Expense(
        id: const Uuid().v4(),
        title: _title.text.trim(),
        amount: amt,
        category: _cat,
        date: DateTime.now(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Add Expense',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount input
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    color: kTextMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: kBorder,
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

          // ── Title input
          InputField(
            hint: 'What did you spend on?',
            controller: _title,
            prefix: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('📝', style: TextStyle(fontSize: 16)),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 10,
              color: kTextMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // ── Category grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: kCategories.map((c) {
              final sel = _cat == c;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cat = c);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: sel ? kPrimary.withOpacity(0.15) : kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? kPrimary : kBorder,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        kCatEmoji[c] ?? '📦',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: sel ? kPrimary : kTextSub,
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
            label: 'Save Expense',
            onTap: _save,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    ),
  );
}
