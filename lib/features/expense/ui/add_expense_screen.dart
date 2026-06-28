import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/button.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/common/widgets/emoji_image.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/pages/commitments_screen.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/expense/services/category_services.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/item_row.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/row.dart';
import 'package:budgetBuddy/features/voice_expense/view/voice_expense_screen.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  bool _isIncome = false;
  List<AppCategory> _cats = [];
  AppCategory? _selCat;
  final List<RowData> _rows = [];
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
    _addRow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use adServiceProvider — consistent with rest of app
      _banner = ref.read(adServiceProvider).createBanner();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _banner?.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  void _reloadCategories() {
    final cats = _isIncome
        ? CategoryService.incomeCategories
        : CategoryService.expenseCategories;
    setState(() {
      _cats = cats;
      _selCat = cats.isNotEmpty ? cats.first : null;
      for (final r in _rows) {
        r.catName = cats.isNotEmpty ? cats.first.name : '';
      }
    });
  }

  void _addRow() => setState(() => _rows.add(RowData(_selCat?.name ?? '')));

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    _rows[i].dispose();
    setState(() => _rows.removeAt(i));
  }

  Color get _accentColor => _isIncome ? kGreen : AppColors.primaryColor;

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }

  void _saveAll() {
    final valid = _rows.where((r) => r.valid).toList();
    if (valid.isEmpty) {
      _showSnack('Fill in at least one item', kAccent);
      return;
    }

    HapticFeedback.mediumImpact();

    // Use Riverpod notifier — reactive, uses correct currency
    final notifier = ref.read(expenseProvider.notifier);
    for (final r in valid) {
      notifier.addExpense(
        title: r.tc.text.trim(),
        amount: r.parsedAmount,
        category: r.catName,
        isIncome: _isIncome,
        date: DateTime.now(),
      );
    }

    Navigator.pop(context);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Reactive currency from Riverpod — not stale Hive reads ──────────────
    final sym = ref.watch(symbolProvider);
    final c = context.c;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final validCount = _rows.where((r) => r.valid).length;
    final l10n = AppLocalizations.of(context)!;

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
          l10n.addEntry,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.mic, color: AppColors.primaryColor),
              tooltip: 'Voice entry',
              onPressed: () =>
                  NavigationService.push(target: VoiceExpenseScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
        children: [
          // ── Income / Expense / EMI toggle ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                _Toggle(
                  label: '↑  ${l10n.expense}',
                  active: !_isIncome,
                  color: kAccent,
                  onTap: () => setState(() {
                    _isIncome = false;
                    _reloadCategories();
                  }),
                ),
                _Toggle(
                  label: '↓  ${l10n.income}',
                  active: _isIncome,
                  color: kGreen,
                  onTap: () => setState(() {
                    _isIncome = true;
                    _reloadCategories();
                  }),
                ),
                _Toggle(
                  label: l10n.emi,
                  active: false,
                  color: c.border,
                  onTap: () =>
                      NavigationService.push(target: CommitmentsScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Category label ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.category,
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
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Category horizontal scroll ─────────────────────────────────
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _cats[i];
                final isSel = _selCat?.id == cat.id;
                final col = _colorFromHex(cat.color);
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

          // ── Items header ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.items,
                style: TextStyle(
                  fontSize: 10,
                  color: c.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_rows.length} ${l10n.row}${_rows.length == 1 ? '' : 's'}'
                ' · $validCount ${l10n.ready}',
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Dynamic rows ───────────────────────────────────────────────
          ..._rows.asMap().entries.map(
            (e) => ItemRow(
              key: ValueKey(e.key),
              row: e.value,
              idx: e.key,
              total: _rows.length,
              col: _accentColor,
              sym: sym, // ← Riverpod, always current
              cats: _cats,
              fromHex: _colorFromHex,
              onRemove: () => _removeRow(e.key),
              onCatChange: (name) => setState(() => e.value.catName = name),
              onChanged: () => setState(() {}),
            ),
          ),

          // ── Add row button ─────────────────────────────────────────────
          PrimaryButton(
            onPressed: _addRow,
            title: l10n.addAnotherItems,
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
        ],
      ),

      // ── Save FAB + banner ad ───────────────────────────────────────────
      floatingActionButton: isKeyboardOpen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_banner != null)
                  Container(
                    width: _banner!.size.width.toDouble(),
                    height: _banner!.size.height.toDouble(),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: AdWidget(ad: _banner!),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: PrimaryButton(
                    onPressed: _saveAll,
                    title: _rows.length == 1
                        ? (_isIncome ? l10n.saveIncome : l10n.saveExpense)
                        : 'Save $validCount Item${validCount == 1 ? '' : 's'}',
                    radius: 8,
                    height: 50,
                    textSize: 18,
                    color: _accentColor,
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.c.textMuted,
          ),
        ),
      ),
    ),
  );
}
