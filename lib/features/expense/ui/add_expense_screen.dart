import 'dart:io';

import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/button.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/common/widgets/emoji_image.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/pages/bill_reminder_screen.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/services/category_services.dart';
import 'package:budgetBuddy/features/expense/services/expenses_service.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/item_row.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/row.dart';
import 'package:budgetBuddy/features/sms_service/ui/pages/sms_import_screen.dart';
import 'package:budgetBuddy/features/voice_expense/view/voice_expense_screen.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _S();
}

class _S extends State<AddExpenseScreen> {
  bool _isIncome = false;
  bool _scanning = false;
  List<AppCategory> _cats = [];
  AppCategory? _selCat;
  final List<RowData> _rows = [];

  @override
  void initState() {
    super.initState();
    _reload();
    _addRow();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  void _reload() {
    final cats = _isIncome
        ? CategoryService.incomeCategories
        : CategoryService.expenseCategories;
    setState(() {
      _cats = cats;
      _selCat = cats.isNotEmpty ? cats.first : null;
      for (final r in _rows) r.catName = cats.isNotEmpty ? cats.first.name : '';
    });
  }

  void _addRow() => setState(() => _rows.add(RowData(_selCat?.name ?? '')));

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    _rows[i].dispose();
    setState(() => _rows.removeAt(i));
  }

  Color get _col => _isIncome ? kGreen : AppColors.primaryColor;

  Color _fromHex(String h) {
    try {
      return Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }

  void _saveAll() {
    final valid = _rows.where((r) => r.valid).toList();
    if (valid.isEmpty) {
      _snack('Fill in at least one item', kAccent);
      return;
    }
    HapticFeedback.mediumImpact();
    final box = Hive.box<Expense>('expenses');
    for (final r in valid) {
      box.add(
        Expense(
          id: const Uuid().v4(),
          title: r.tc.text.trim(),
          amount: r.parsedAmount,
          category: r.catName,
          date: DateTime.now(),
          isIncome: _isIncome,
          currency: ExpenseService.currency,
        ),
      );
    }
    Navigator.pop(context);
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final valid = _rows.where((r) => r.valid).length;
    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.addEntry,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: _scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : const Icon(Icons.mic, color: AppColors.primaryColor),
              tooltip: 'Scan bill',
              onPressed: () {
                NavigationService.push(target: VoiceExpenseScreen());
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
        children: [
          // Income/Expense toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                _Tog(
                  '↑  ${AppLocalizations.of(context)!.expense}',
                  !_isIncome,
                  kAccent,
                  () => setState(() {
                    _isIncome = false;
                    _reload();
                  }),
                ),
                _Tog(
                  '↓  ${AppLocalizations.of(context)!.income}',
                  _isIncome,
                  kGreen,
                  () => setState(() {
                    _isIncome = true;
                    _reload();
                  }),
                ),
                _Tog(AppLocalizations.of(context)!.emi, false, c.border, () {
                  NavigationService.push(target: BillReminderScreen());
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Category horizontal scroll (from Supabase)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.category,
                style: TextStyle(
                  fontSize: 10,
                  color: c.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _selCat?.name ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: _col,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _cats[i];
                final isSel = _selCat?.id == cat.id;
                final col = _fromHex(cat.color);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selCat = cat;
                      for (final r in _rows) r.catName = cat.name;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 74,
                    decoration: BoxDecoration(
                      color: isSel ? col.withOpacity(0.12) : c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? col : c.border,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmojiImage(value: cat.emoji, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isSel ? col : c.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Items header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.items,
                style: TextStyle(
                  fontSize: 10,
                  color: c.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_rows.length} ${AppLocalizations.of(context)!.row}${_rows.length == 1 ? '' : 's'} · $valid ${AppLocalizations.of(context)!.ready}',
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dynamic rows
          ..._rows.asMap().entries.map(
            (e) => ItemRow(
              key: ValueKey(e.key),
              row: e.value,
              idx: e.key,
              total: _rows.length,
              col: _col,
              sym: ExpenseService.symbol,
              cats: _cats,
              fromHex: _fromHex,
              onRemove: () => _removeRow(e.key),
              onCatChange: (name) => setState(() => e.value.catName = name),
              onChanged: () => setState(() {}),
            ),
          ),
          PrimaryButton(
            onPressed: _addRow,
            title: AppLocalizations.of(context)!.addAnotherItems,
            radius: 8,
            height: 50,
            textSize: 18,
            color: AppColors.primaryColor,
            icon: CommonSvgWidget(
              svgName: Assets.add,
              height: 20,
              width: 20,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 20),
          if (!Platform.isIOS)
            PrimaryButton(
              onPressed: () {
                NavigationService.push(target: SmsImportScreen());
              },
              title: AppLocalizations.of(context)!.importSms,
              radius: 8,
              height: 50,
              textSize: 18,
              color: AppColors.darkGrey,
              icon: CommonSvgWidget(
                svgName: Assets.sms,
                height: 20,
                width: 20,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
      floatingActionButton: isKeyboardOpen
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: PrimaryButton(
                onPressed: _saveAll,
                title: _rows.length == 1
                    ? (_isIncome
                          ? AppLocalizations.of(context)!.saveIncome
                          : AppLocalizations.of(context)!.saveExpense)
                    : 'Save $valid Item${valid == 1 ? '' : 's'}',
                radius: 8,
                height: 50,
                textSize: 18,
                color: _col,
                icon: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Tog extends StatelessWidget {
  final String l;
  final bool a;
  final Color c;
  final VoidCallback t;
  const _Tog(this.l, this.a, this.c, this.t);
  @override
  Widget build(BuildContext ctx) => Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        t();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: a ? c : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: a ? Colors.white : ctx.c.textMuted,
          ),
        ),
      ),
    ),
  );
}
