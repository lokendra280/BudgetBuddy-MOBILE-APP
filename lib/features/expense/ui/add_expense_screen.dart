import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/button.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/widgets/emoji_image.dart';
import 'package:expensetracker/features/expense/services/category_services.dart';
import 'package:expensetracker/features/expense/services/expenses_service.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

// ── Single entry row model ────────────────────────────────────────────────────
class _Row {
  final tc = TextEditingController(); // title
  final ac = TextEditingController(); // amount
  String catName;
  _Row(this.catName);
  void dispose() {
    tc.dispose();
    ac.dispose();
  }

  bool get valid =>
      tc.text.trim().isNotEmpty &&
      (double.tryParse(ac.text.replaceAll(',', '')) ?? 0) > 0;
  double get parsedAmount => double.tryParse(ac.text.replaceAll(',', '')) ?? 0;
}

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
  final List<_Row> _rows = [];

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

  void _addRow() => setState(() => _rows.add(_Row(_selCat?.name ?? '')));

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

  // ── Bill scan ───────────────────────────────────────────────────────────────
  // Future<void> _scan({required bool camera}) async {
  //   setState(() => _scanning = true);
  //   try {
  //     final res = await BillScannerService.scan(fromCamera: camera);
  //     if (res == null || !mounted) return;
  //     if (!res.hasItems && res.totalAmount == null) {
  //       _snack('No items found. Try a clearer photo.', kAmber);
  //       return;
  //     }
  //     await _showReview(res);
  //   } catch (_) {
  //     _snack('Scan failed. Try again.', kAccent);
  //   } finally {
  //     if (mounted) setState(() => _scanning = false);
  //   }
  // }

  // ── Multi-item review sheet with checkboxes ─────────────────────────────────
  // Future<void> _showReview(BillScanResult res) async {
  //   final sym = currencyOf(
  //     res.detectedCurrency ?? ExpenseService.currency,
  //   ).symbol;
  //   final Set<int> sel = Set.from(List.generate(res.items.length, (i) => i));

  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: context.c.card,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
  //     ),
  //     builder: (_) => StatefulBuilder(
  //       builder: (ctx, ss) => DraggableScrollableSheet(
  //         expand: false,
  //         initialChildSize: 0.75,
  //         maxChildSize: 0.95,
  //         minChildSize: 0.45,
  //         builder: (_, sc) => Column(
  //           children: [
  //             // Header
  //             Container(
  //               padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
  //               decoration: BoxDecoration(
  //                 color: context.c.card,
  //                 border: Border(bottom: BorderSide(color: context.c.border)),
  //               ),
  //               child: Column(
  //                 children: [
  //                   Container(
  //                     width: 36,
  //                     height: 4,
  //                     decoration: BoxDecoration(
  //                       color: context.c.border,
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           const Text(
  //                             'Scanned Items',
  //                             style: TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w700,
  //                             ),
  //                           ),
  //                           if (res.merchant != null)
  //                             Text(
  //                               res.merchant!,
  //                               style: TextStyle(
  //                                 fontSize: 11,
  //                                 color: context.c.textMuted,
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                       TextButton(
  //                         onPressed: () => ss(
  //                           () => sel.length == res.items.length
  //                               ? sel.clear()
  //                               : sel.addAll(
  //                                   List.generate(res.items.length, (i) => i),
  //                                 ),
  //                         ),
  //                         child: Text(
  //                           sel.length == res.items.length
  //                               ? 'Deselect all'
  //                               : 'Select all',
  //                           style: const TextStyle(
  //                             fontSize: 12,
  //                             color: AppColors.primaryColor,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             Expanded(
  //               child: ListView(
  //                 controller: sc,
  //                 padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
  //                 children: [
  //                   // Grand total quick-pick
  //                   if (res.totalAmount != null)
  //                     GestureDetector(
  //                       onTap: () {
  //                         Navigator.pop(context);
  //                         _rows.removeWhere((r) => !r.valid);
  //                         if (_rows.isEmpty)
  //                           _rows.add(_Row(_selCat?.name ?? ''));
  //                         _rows.last.tc.text = res.merchant ?? 'Bill Total';
  //                         _rows.last.ac.text = res.totalAmount!.toStringAsFixed(
  //                           0,
  //                         );
  //                         setState(() {});
  //                       },
  //                       child: Container(
  //                         margin: const EdgeInsets.only(bottom: 10),
  //                         padding: const EdgeInsets.all(14),
  //                         decoration: BoxDecoration(
  //                           color: kGreen.withOpacity(0.07),
  //                           borderRadius: BorderRadius.circular(14),
  //                           border: Border.all(
  //                             color: kGreen.withOpacity(0.3),
  //                             width: 1.5,
  //                           ),
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             Container(
  //                               width: 38,
  //                               height: 38,
  //                               decoration: BoxDecoration(
  //                                 color: kGreen.withOpacity(0.12),
  //                                 borderRadius: BorderRadius.circular(10),
  //                               ),
  //                               child: const Center(
  //                                 child: Text(
  //                                   '🧾',
  //                                   style: TextStyle(fontSize: 16),
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(width: 12),
  //                             Expanded(
  //                               child: Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   const Text(
  //                                     'Grand Total — tap to use',
  //                                     style: TextStyle(
  //                                       fontSize: 13,
  //                                       fontWeight: FontWeight.w700,
  //                                     ),
  //                                   ),
  //                                   Text(
  //                                     'Use full bill as one expense',
  //                                     style: TextStyle(
  //                                       fontSize: 11,
  //                                       color: context.c.textMuted,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                             Text(
  //                               '$sym${res.totalAmount!.toStringAsFixed(0)}',
  //                               style: const TextStyle(
  //                                 fontSize: 15,
  //                                 fontWeight: FontWeight.w800,
  //                                 color: kGreen,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),

  //                   if (res.hasItems) ...[
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(vertical: 6),
  //                       child: Row(
  //                         children: [
  //                           Expanded(child: Divider(color: context.c.border)),
  //                           Padding(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 10,
  //                             ),
  //                             child: Text(
  //                               'or select items',
  //                               style: TextStyle(
  //                                 fontSize: 11,
  //                                 color: context.c.textMuted,
  //                               ),
  //                             ),
  //                           ),
  //                           Expanded(child: Divider(color: context.c.border)),
  //                         ],
  //                       ),
  //                     ),
  //                     ...res.items.asMap().entries.map((e) {
  //                       final isSel = sel.contains(e.key);
  //                       return GestureDetector(
  //                         onTap: () => ss(
  //                           () => isSel ? sel.remove(e.key) : sel.add(e.key),
  //                         ),
  //                         child: AnimatedContainer(
  //                           duration: const Duration(milliseconds: 150),
  //                           margin: const EdgeInsets.only(bottom: 8),
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 14,
  //                             vertical: 12,
  //                           ),
  //                           decoration: BoxDecoration(
  //                             color: isSel
  //                                 ? AppColors.primaryColor.withOpacity(0.07)
  //                                 : context.c.card,
  //                             borderRadius: BorderRadius.circular(14),
  //                             border: Border.all(
  //                               color: isSel ? AppColors.primaryColor : context.c.border,
  //                               width: isSel ? 1.5 : 1,
  //                             ),
  //                           ),
  //                           child: Row(
  //                             children: [
  //                               AnimatedContainer(
  //                                 duration: const Duration(milliseconds: 150),
  //                                 width: 22,
  //                                 height: 22,
  //                                 decoration: BoxDecoration(
  //                                   color: isSel
  //                                       ? AppColors.primaryColor
  //                                       : Colors.transparent,
  //                                   shape: BoxShape.circle,
  //                                   border: Border.all(
  //                                     color: isSel
  //                                         ? AppColors.primaryColor
  //                                         : context.c.border,
  //                                     width: 1.5,
  //                                   ),
  //                                 ),
  //                                 child: isSel
  //                                     ? const Icon(
  //                                         Icons.check_rounded,
  //                                         size: 13,
  //                                         color: Colors.white,
  //                                       )
  //                                     : null,
  //                               ),
  //                               const SizedBox(width: 10),
  //                               Container(
  //                                 width: 26,
  //                                 height: 26,
  //                                 decoration: BoxDecoration(
  //                                   color: AppColors.primaryColor.withOpacity(0.10),
  //                                   borderRadius: BorderRadius.circular(7),
  //                                 ),
  //                                 child: Center(
  //                                   child: Text(
  //                                     '${e.key + 1}',
  //                                     style: const TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: FontWeight.w800,
  //                                       color: AppColors.primaryColor,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 10),
  //                               Expanded(
  //                                 child: Text(
  //                                   e.value.name,
  //                                   style: const TextStyle(
  //                                     fontSize: 13,
  //                                     fontWeight: FontWeight.w600,
  //                                   ),
  //                                 ),
  //                               ),
  //                               Text(
  //                                 '$sym${e.value.amount.toStringAsFixed(2)}',
  //                                 style: const TextStyle(
  //                                   fontSize: 13,
  //                                   fontWeight: FontWeight.w700,
  //                                   color: AppColors.primaryColor,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }),
  //                   ],
  //                 ],
  //               ),
  //             ),

  //             if (res.hasItems)
  //               Padding(
  //                 padding: EdgeInsets.fromLTRB(
  //                   16,
  //                   8,
  //                   16,
  //                   MediaQuery.of(context).padding.bottom + 14,
  //                 ),
  //                 child: AppButton(
  //                   label: sel.isEmpty
  //                       ? 'Tap items to select'
  //                       : 'Add ${sel.length} item${sel.length == 1 ? '' : 's'} as expenses',
  //                   color: sel.isEmpty ? context.c.borderStrong : AppColors.primaryColor,
  //                   icon: Icons.add_rounded,
  //                   onTap: sel.isEmpty
  //                       ? () {}
  //                       : () {
  //                           Navigator.pop(context);
  //                           _rows.removeWhere((r) => !r.valid);
  //                           if (_rows.isEmpty)
  //                             _rows.add(_Row(_selCat?.name ?? ''));
  //                           for (final idx in sel.toList()..sort()) {
  //                             final it = res.items[idx];
  //                             final nr = _Row(_selCat?.name ?? '');
  //                             nr.tc.text = it.name;
  //                             nr.ac.text = it.amount.toStringAsFixed(0);
  //                             _rows.add(nr);
  //                           }
  //                           setState(() {});
  //                         },
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // void _scanOpts() => showModalBottomSheet(
  //   context: context,
  //   backgroundColor: context.c.card,
  //   shape: const RoundedRectangleBorder(
  //     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //   ),
  //   builder: (_) => SafeArea(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const SizedBox(height: 8),
  //         Container(
  //           width: 36,
  //           height: 4,
  //           decoration: BoxDecoration(
  //             color: context.c.border,
  //             borderRadius: BorderRadius.circular(2),
  //           ),
  //         ),
  //         const SizedBox(height: 14),
  //         const Text(
  //           'Scan Bill',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           'Detects every item on the bill',
  //           style: TextStyle(fontSize: 12, color: context.c.textMuted),
  //         ),
  //         const SizedBox(height: 12),
  //         ListTile(
  //           leading: Container(
  //             width: 40,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: AppColors.primaryColor.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryColor),
  //           ),
  //           title: const Text(
  //             'Camera',
  //             style: TextStyle(fontWeight: FontWeight.w600),
  //           ),
  //           subtitle: Text(
  //             'Scan with camera',
  //             style: TextStyle(fontSize: 11, color: context.c.textMuted),
  //           ),
  //           onTap: () {
  //             Navigator.pop(context);
  //             _scan(camera: true);
  //           },
  //         ),
  //         ListTile(
  //           leading: Container(
  //             width: 40,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: kBlue.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: const Icon(Icons.photo_library_rounded, color: kBlue),
  //           ),
  //           title: const Text(
  //             'Gallery',
  //             style: TextStyle(fontWeight: FontWeight.w600),
  //           ),
  //           subtitle: Text(
  //             'Pick from gallery',
  //             style: TextStyle(fontSize: 11, color: context.c.textMuted),
  //           ),
  //           onTap: () {
  //             Navigator.pop(context);
  //             _scan(camera: false);
  //           },
  //         ),
  //         const SizedBox(height: 8),
  //       ],
  //     ),
  //   ),
  // );

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
    final valid = _rows.where((r) => r.valid).length;
    return Scaffold(
      backgroundColor: c.bg,
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
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8),
        //     child: IconButton(
        //       icon: _scanning
        //           ? const SizedBox(
        //               width: 18,
        //               height: 18,
        //               child: CircularProgressIndicator(
        //                 strokeWidth: 2,
        //                 color: AppColors.primaryColor,
        //               ),
        //             )
        //           : const Icon(
        //               Icons.document_scanner_outlined,
        //               color: AppColors.primaryColor,
        //             ),
        //       tooltip: 'Scan bill',
        //       onPressed: _scanning ? null : _scanOpts,
        //     ),
        //   ),
        // ],
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
                        EmojiImage(
                          value: cat.emoji,
                          size: 20,
                        ), // Text(cat.emoji, style: const TextStyle(fontSize: 22)),
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
            (e) => _ItemRow(
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
              height: 18,
              width: 18,
              color: AppColors.white,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
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
          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
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

// ── Single item row widget ────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final _Row row;
  final int idx, total;
  final Color col;
  final String sym;
  final List<AppCategory> cats;
  final Color Function(String) fromHex;
  final VoidCallback onRemove, onChanged;
  final ValueChanged<String> onCatChange;
  const _ItemRow({
    super.key,
    required this.row,
    required this.idx,
    required this.total,
    required this.col,
    required this.sym,
    required this.cats,
    required this.fromHex,
    required this.onRemove,
    required this.onChanged,
    required this.onCatChange,
  });

  AppCategory get _cur => cats.firstWhere(
    (c) => c.name == row.catName,
    orElse: () => cats.isNotEmpty
        ? cats.first
        : AppCategory(
            id: '',
            name: 'Other',
            emoji: '📦',
            color: '#6366F1',
            isIncome: false,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: col.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: col,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: row.tc,
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.itemName,
                    hintStyle: TextStyle(
                      color: c.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (total > 1)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: c.textMuted,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 36),
              // Amount field
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        sym,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: col,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: row.ac,
                          onChanged: (_) => onChanged(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: c.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Per-row category override
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _catPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        EmojiImage(value: _cur.emoji, size: 20), //
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _cur.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 14,
                          color: c.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _catPicker(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    backgroundColor: ctx.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            ...cats.map((cat) {
              final isSel = row.catName == cat.name;
              final col = fromHex(cat.color);
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: EmojiImage(value: cat.emoji, size: 18)),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: isSel
                    ? Icon(Icons.check_circle_rounded, color: col)
                    : null,
                onTap: () {
                  onCatChange(cat.name);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
