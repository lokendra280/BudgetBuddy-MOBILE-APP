import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/button.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/localization/category_localization.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/common/widgets/custom_appbar.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/expense/services/pdf_service.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/button.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/date_range.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/fi_chip.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/transcation_widget.dart';
import 'package:budgetBuddy/features/heatmap/ui/pages/heatmap_screen.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { month, dateRange }

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
  Future<void> _export(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      _showSnack('No transactions to export');
      return;
    }
    ref
        .read(adServiceProvider)
        .showRewarded(
          onRewarded: () async {
            await _doExport(expenses);
            ref.read(adServiceProvider).preloadRewarded();
          },
          onNotAvailable: () =>
              _showSnack('Ad not ready, please try again in a moment'),
        );
  }

  Future<void> _doExport(List<Expense> expenses) async {
    setState(() => _exporting = true);
    try {
      final from = _mode == _Mode.dateRange && _fromDate != null
          ? _fromDate!
          : DateTime(_month.year, _month.month, 1);
      final to = _mode == _Mode.dateRange && _toDate != null
          ? _toDate!
          : DateTime(_month.year, _month.month + 1, 0);
      await PdfService.exportStatement(expenses: expenses, from: from, to: to);
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
      appBar: CustomAppBar(
        appElevation: 0,
        backgroundColor: context.c.surface,
        showBackButton: false,
        title: l10n.statements,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : CommonSvgWidget(
                      svgName: Assets.pdf,
                      color: kAccent,
                      height: 30,
                      width: 30,
                    ),
              tooltip: 'Export as PDF',
              onPressed: _exporting ? null : () => _export(period),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
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
              onPrev: () =>
                  _onMonthChanged(DateTime(_month.year, _month.month - 1)),
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
          AppCard(
            child: Row(
              children: [
                _SumCol(l10n.income, totalInc, kGreen, fmt: fmt),
                Container(width: 1, height: 40, color: context.c.border),
                _SumCol(l10n.expense, totalExp, kAccent, fmt: fmt),
                Container(width: 1, height: 40, color: context.c.border),
                _SumCol(
                  l10n.net,
                  net.abs(),
                  net >= 0 ? kGreen : kAccent,
                  fmt: fmt,
                  prefix: net >= 0 ? '+' : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Pie chart ──────────────────────────────────────────────────
          if (cats.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel(l10n.byCategory),
                GestureDetector(
                  onTap: () => NavigationService.push(target: HeatmapScreen()),
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
                  AppColors.primaryColor,
                  () => setState(
                    () => _filterCat = _filterCat == cat ? null : cat,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Export card ────────────────────────────────────────────────
          AppCard(
            onTap: () => _export(filtered),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CommonSvgWidget(
                    svgName: Assets.pdf,
                    color: kAccent,
                    height: 20,
                    width: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.export,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l10n.bankStyle} · ${filtered.length} ${l10n.transactions}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kAccent,
                        ),
                      )
                    : CommonSvgWidget(
                        svgName: Assets.download,
                        color: kAccent,
                        height: 30,
                        width: 30,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 14),

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
                    style: TextStyle(fontSize: 13, color: context.c.textMuted),
                  ),
                ],
              ),
            )
          else ...[
            // Paginated rows
            ...paginatedFiltered.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionWidget(expense: e),
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
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              )
            else if (!paginated.hasMore && paginatedFiltered.length > kPageSize)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'All ${paginatedFiltered.length} transactions shown',
                    style: TextStyle(fontSize: 12, color: context.c.textMuted),
                  ),
                ),
              ),
          ],
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

class _SumCol extends StatelessWidget {
  final String label, prefix;
  final double amount;
  final Color color;
  final String Function(double) fmt;

  const _SumCol(
    this.label,
    this.amount,
    this.color, {
    required this.fmt,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.c.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix${fmt(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
