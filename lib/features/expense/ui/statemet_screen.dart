import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/button.dart';
import 'package:budgetbuddy/common/common_svg_widget.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/common/localization/category_localization.dart';
import 'package:budgetbuddy/common/navigation_service.dart';
import 'package:budgetbuddy/common/services/ads_service.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/features/expense/services/excel_service.dart';
import 'package:budgetbuddy/features/expense/services/pdf_service.dart';
import 'package:budgetbuddy/features/expense/ui/widgets/button.dart';
import 'package:budgetbuddy/features/expense/ui/widgets/date_range.dart';
import 'package:budgetbuddy/features/expense/ui/widgets/fi_chip.dart';
import 'package:budgetbuddy/features/expense/ui/widgets/transcation_widget.dart';
import 'package:budgetbuddy/features/heatmap/ui/pages/heatmap_screen.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { month, dateRange }

enum _ExportFormat { pdf, excel }

class StatementsScreen extends ConsumerStatefulWidget {
  const StatementsScreen({super.key});

  @override
  ConsumerState<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends ConsumerState<StatementsScreen> {
  _Mode _mode = _Mode.month;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _filterCat;
  bool _showIncome = true;
  bool _showExpense = true;
  int _touchedPie = -1;
  bool _exporting = false;

  // ── Scroll controller for infinite scroll ─────────────────────────────────
  final _scrollController = ScrollController();
  static const _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load first page after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    ref.read(paginatedExpenseProvider(_month).notifier).loadInitial();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _scrollThreshold) {
      ref.read(paginatedExpenseProvider(_month).notifier).loadMore();
    }
  }

  // ── Period filter for summary (uses full list, not paginated) ─────────────
  List<Expense> _period(List<Expense> all) {
    if (_mode == _Mode.dateRange && _fromDate != null && _toDate != null) {
      final end = _toDate!.add(const Duration(days: 1));
      return all
          .where((e) => e.date.isAfter(_fromDate!) && e.date.isBefore(end))
          .toList();
    }
    return all
        .where(
          (e) => e.date.month == _month.month && e.date.year == _month.year,
        )
        .toList();
  }

  // ── Chip filter ────────────────────────────────────────────────────────────
  List<Expense> _chip(List<Expense> list) => list.where((e) {
    if (!_showIncome && e.isIncome) return false;
    if (!_showExpense && !e.isIncome) return false;
    if (_filterCat != null && e.category != _filterCat) return false;
    return true;
  }).toList();

  void _onMonthChanged(DateTime newMonth) {
    setState(() => _month = newMonth);
    ref.read(paginatedExpenseProvider(newMonth).notifier).loadInitial();
  }

  // ── Date range picker ──────────────────────────────────────────────────────
  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _fromDate = range.start;
      _toDate = range.end;
      _mode = _Mode.dateRange;
    });
  }

  // ── PDF export ─────────────────────────────────────────────────────────────
  Future<void> _export(
    List<Expense> expenses, {
    _ExportFormat format = _ExportFormat.pdf,
  }) async {
    if (expenses.isEmpty) {
      _showSnack('No transactions to export');
      return;
    }
    ref
        .read(adServiceProvider)
        .showRewarded(
          onRewarded: () async {
            await _doExport(expenses, format);
            ref.read(adServiceProvider).preloadRewarded();
          },
          onNotAvailable: () =>
              _showSnack('Ad not ready, please try again in a moment'),
        );
  }

  Future<void> _doExport(List<Expense> expenses, _ExportFormat format) async {
    setState(() => _exporting = true);
    try {
      final from = _mode == _Mode.dateRange && _fromDate != null
          ? _fromDate!
          : DateTime(_month.year, _month.month, 1);
      final to = _mode == _Mode.dateRange && _toDate != null
          ? _toDate!
          : DateTime(_month.year, _month.month + 1, 0);
      if (format == _ExportFormat.excel) {
        final l10n = AppLocalizations.of(context)!;
        final box = context.findRenderObject() as RenderBox?;
        await ExcelService.exportStatement(
          expenses: expenses,
          from: from,
          to: to,
          categoryName: (c) => CategoryLocalization.getName(l10n, c),
          shareOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        await PdfService.exportStatement(
          expenses: expenses,
          from: from,
          to: to,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _chooseExport(List<Expense> expenses) async {
    final format = await showModalBottomSheet<_ExportFormat>(
      context: context,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.c.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export statement',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${expenses.length} transactions',
                style: TextStyle(fontSize: 12, color: ctx.c.textMuted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ExportTile(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'PDF',
                      subtitle: 'Bank-style report',
                      color: kAccent,
                      onTap: () => Navigator.pop(ctx, _ExportFormat.pdf),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ExportTile(
                      icon: Icons.table_chart_rounded,
                      title: 'Excel',
                      subtitle: '.xlsx spreadsheet',
                      color: kMidGreen,
                      onTap: () => Navigator.pop(ctx, _ExportFormat.excel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !mounted) return;
    _export(expenses, format: format);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(expenseProvider).all;
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final paginated = ref.watch(paginatedExpenseProvider(_month));
    final l10n = AppLocalizations.of(context)!;

    // Summary uses full period (not paginated)
    final period = _period(all);
    final filtered = _chip(period);

    // Paginated list with chip filter applied
    final paginatedFiltered = _chip(paginated.items);

    final expenses = period.where((e) => !e.isIncome).toList();
    final incomes = period.where((e) => e.isIncome).toList();
    final totalExp = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalInc = incomes.fold(0.0, (s, e) => s + e.amount);
    final net = totalInc - totalExp;

    final catMap = <String, double>{};
    for (final e in expenses) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    }
    final cats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final usedCats = period.map((e) => e.category).toSet().toList();

    return Scaffold(
      backgroundColor: context.c.bg,
      body: Column(
        children: [
          TabHeader(
            title: l10n.statements,
            subtitle: 'Where your money went',
            trailing: HeaderIconButton(
              icon: Icons.file_download_outlined,
              tooltip: 'Export',
              onTap: _exporting ? null : () => _chooseExport(period),
              child: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kMidGreen,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
              children: [
                // ── Mode toggle ────────────────────────────────────────────────
                _ModeToggle(
                  mode: _mode,
                  onMonth: () => setState(() => _mode = _Mode.month),
                  onDateRange: _pickRange,
                ),
                const SizedBox(height: 12),

                // ── Month nav / date range display ─────────────────────────────
                if (_mode == _Mode.month)
                  MonthNav(
                    month: _month,
                    onPrev: () => _onMonthChanged(
                      DateTime(_month.year, _month.month - 1),
                    ),
                    onNext:
                        _month.month == DateTime.now().month &&
                            _month.year == DateTime.now().year
                        ? null
                        : () => _onMonthChanged(
                            DateTime(_month.year, _month.month + 1),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _month,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        _onMonthChanged(DateTime(picked.year, picked.month));
                      }
                    },
                  )
                else
                  DateRange(from: _fromDate, to: _toDate, onTap: _pickRange),

                const SizedBox(height: 14),

                // ── Summary ────────────────────────────────────────────────────
                _SummaryCard(
                  net: net,
                  income: totalInc,
                  expense: totalExp,
                  count: period.length,
                  fmt: fmt,
                ),
                const SizedBox(height: 14),

                // ── Pie chart ──────────────────────────────────────────────────
                if (cats.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionLabel(l10n.byCategory),
                      GestureDetector(
                        onTap: () =>
                            NavigationService.push(target: HeatmapScreen()),
                        child: const SectionLabel('HeatMap'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PieCard(
                    cats: cats,
                    totalExp: totalExp,
                    touchedIndex: _touchedPie,
                    onTouch: (i) => setState(() => _touchedPie = i),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Daily bar chart ────────────────────────────────────────────
                SectionLabel(l10n.dailyOverview),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Leg(kGreen, l10n.income),
                          const SizedBox(width: 12),
                          _Leg(kAccent, l10n.expense),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BarChart(expenses: period),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Chip filters ───────────────────────────────────────────────
                SectionLabel(l10n.filter),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FiChip(
                      l10n.income,
                      _showIncome,
                      kGreen,
                      () => setState(() => _showIncome = !_showIncome),
                    ),
                    FiChip(
                      l10n.expense,
                      _showExpense,
                      kAccent,
                      () => setState(() => _showExpense = !_showExpense),
                    ),
                    ...usedCats.map(
                      (cat) => FiChip(
                        CategoryLocalization.getName(l10n, cat),
                        _filterCat == cat,
                        kMidGreen,
                        () => setState(
                          () => _filterCat = _filterCat == cat ? null : cat,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Export ─────────────────────────────────────────────────────
                SectionLabel(l10n.export),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ExportTile(
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'PDF',
                        subtitle: '${filtered.length} ${l10n.transactions}',
                        color: kAccent,
                        busy: _exporting,
                        onTap: () => _export(filtered),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExportTile(
                        icon: Icons.table_chart_rounded,
                        title: 'Excel',
                        subtitle: '${filtered.length} ${l10n.transactions}',
                        color: kMidGreen,
                        busy: _exporting,
                        onTap: () =>
                            _export(filtered, format: _ExportFormat.excel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const AdSlot(),

                // ── Transactions list (paginated) ──────────────────────────────
                SectionLabel(
                  l10n.transactions,
                  trailing: Text(
                    '${filtered.length} ${l10n.items}',
                    style: TextStyle(fontSize: 11, color: context.c.textMuted),
                  ),
                ),
                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        CommonSvgWidget(
                          svgName: Assets.nodata,
                          color: AppColors.primaryColor,
                          height: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noTransaction,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Paginated rows, grouped in one card like Home
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < paginatedFiltered.length; i++) ...[
                          TransactionWidget(expense: paginatedFiltered[i]),
                          if (i != paginatedFiltered.length - 1)
                            Divider(
                              height: 1,
                              indent: 70,
                              endIndent: 16,
                              color: context.c.border,
                            ),
                        ],
                      ],
                    ),
                  ),

                  // Load more indicator
                  if (paginated.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kMidGreen,
                          ),
                        ),
                      ),
                    )
                  else if (!paginated.hasMore &&
                      paginatedFiltered.length > kPageSize)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'All ${paginatedFiltered.length} transactions shown',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.c.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _Mode mode;
  final VoidCallback onMonth;
  final VoidCallback onDateRange;
  const _ModeToggle({
    required this.mode,
    required this.onMonth,
    required this.onDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          ModeBtn(l10n.month, mode == _Mode.month, onMonth),
          ModeBtn(l10n.dataRange, mode == _Mode.dateRange, onDateRange),
        ],
      ),
    );
  }
}

class _PieCard extends StatelessWidget {
  final List<MapEntry<String, double>> cats;
  final double totalExp;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _PieCard({
    required this.cats,
    required this.totalExp,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                pieTouchData: PieTouchData(
                  touchCallback: (_, r) =>
                      onTouch(r?.touchedSection?.touchedSectionIndex ?? -1),
                ),
                sections: cats.asMap().entries.map((e) {
                  final col = kCatColors[e.key % kCatColors.length];
                  final hit = e.key == touchedIndex;
                  final pct = totalExp > 0
                      ? e.value.value / totalExp * 100
                      : 0.0;
                  return PieChartSectionData(
                    value: e.value.value,
                    color: col,
                    radius: hit ? 50 : 42,
                    showTitle: hit,
                    title: '${pct.toInt()}%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cats.asMap().entries.take(5).map((e) {
                final col = kCatColors[e.key % kCatColors.length];
                final pct = totalExp > 0
                    ? (e.value.value / totalExp * 100).toInt()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          CategoryLocalization.getName(l10n, e.value.key),
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: col,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double net, income, expense;
  final int count;
  final String Function(double) fmt;

  const _SummaryCard({
    required this.net,
    required this.income,
    required this.expense,
    required this.count,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positive = net >= 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeepGreen, kMidGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kDeepGreen.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.net,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count ${l10n.transactions}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${positive ? '+' : '-'}${fmt(net.abs())}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SumChip(
                        icon: Icons.south_west_rounded,
                        label: l10n.income,
                        value: fmt(income),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SumChip(
                        icon: Icons.north_east_rounded,
                        label: l10n.expense,
                        value: fmt(expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SumChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SumChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    onTap: busy ? null : onTap,
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: busy
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: context.c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(Icons.download_rounded, size: 18, color: color),
      ],
    ),
  );
}

class _Leg extends StatelessWidget {
  final Color color;
  final String label;
  const _Leg(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: context.c.textSub)),
    ],
  );
}

class _BarChart extends StatelessWidget {
  final List<Expense> expenses;
  const _BarChart({required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No data for this period',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ),
      );
    }

    final grouped = <DateTime, List<Expense>>{};
    for (final e in expenses) {
      final key = DateTime(e.date.year, e.date.month);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final groups = grouped.entries.map((entry) {
      final items = entry.value;
      final inc = items
          .where((e) => e.isIncome)
          .fold(0.0, (s, e) => s + e.amount);
      final exp = items
          .where((e) => !e.isIncome)
          .fold(0.0, (s, e) => s + e.amount);
      return BarChartGroupData(
        x: entry.key.month,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: inc,
            width: 7,
            color: kGreen.withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: exp,
            width: 7,
            color: kAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    final maxY = groups
        .expand((g) => g.barRods.map((r) => r.toY))
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxY == 0) return const SizedBox.shrink();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.3,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.c.border, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 1 || i > 12) return const SizedBox();
                  return Text(
                    months[i - 1],
                    style: TextStyle(fontSize: 9, color: context.c.textMuted),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
