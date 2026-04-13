import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/shimmer_widget.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/expense/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

enum _FilterMode { month, dateRange }

class StatementsScreen extends StatefulWidget {
  const StatementsScreen({super.key});
  @override
  State<StatementsScreen> createState() => _State();
}

class _State extends State<StatementsScreen> {
  _FilterMode _filterMode = _FilterMode.month;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _filterCat;
  bool _showIncome = true;
  bool _showExpense = true;
  int _touchedPie = -1;
  bool _isLoading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // ── Date range picker ─────────────────────────────────────────────────────
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimary,
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
      _filterMode = _FilterMode.dateRange;
    });
  }

  // ── Get expenses for current filter ────────────────────────────────────────
  List<Expense> _getFiltered(List<Expense> all) {
    return all.where((e) {
      if (!_showIncome && e.isIncome) return false;
      if (!_showExpense && !e.isIncome) return false;
      if (_filterCat != null && e.category != _filterCat) return false;
      return true;
    }).toList();
  }

  List<Expense> _getPeriodExpenses(List<Expense> all) {
    if (_filterMode == _FilterMode.dateRange &&
        _fromDate != null &&
        _toDate != null) {
      final end = _toDate!.add(const Duration(days: 1));
      return all
          .where((e) => e.date.isAfter(_fromDate!) && e.date.isBefore(end))
          .toList();
    }
    return ExpenseService.forMonth(_month);
  }

  Future<void> _exportPdf(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final from = _filterMode == _FilterMode.dateRange && _fromDate != null
          ? _fromDate!
          : DateTime(_month.year, _month.month, 1);
      final to = _filterMode == _FilterMode.dateRange && _toDate != null
          ? _toDate!
          : DateTime(_month.year, _month.month + 1, 0);
      await PdfService.exportStatement(expenses: expenses, from: from, to: to);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: kAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.c.bg,
    appBar: AppBar(
      backgroundColor: context.c.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Statements',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      actions: [
        // PDF export button
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimary,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: kAccent),
            tooltip: 'Export as PDF',
            onPressed: _exporting
                ? null
                : () {
                    final allExpenses = ExpenseService.all;
                    final period = _getPeriodExpenses(allExpenses);
                    _exportPdf(period);
                  },
          ),
        ),
      ],
    ),
    body: _isLoading
        ? const StatementsShimmer()
        : ValueListenableBuilder(
            valueListenable: Hive.box<Expense>('expenses').listenable(),
            builder: (_, __, ___) {
              final allExpenses = ExpenseService.all;
              final period = _getPeriodExpenses(allExpenses);
              final expenses = period.where((e) => !e.isIncome).toList();
              final incomes = period.where((e) => e.isIncome).toList();
              final totalExp = ExpenseService.totalFor(expenses);
              final totalInc = ExpenseService.totalFor(incomes);
              final net = totalInc - totalExp;
              final catMap = ExpenseService.byCategory(expenses);
              final cats = catMap.entries.toList();
              final usedCats = period.map((e) => e.category).toSet().toList();
              final filtered = _getFiltered(period);

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
                children: [
                  // ── Filter mode toggle ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.border),
                    ),
                    child: Row(
                      children: [
                        _FModeBtn(
                          'Month',
                          _filterMode == _FilterMode.month,
                          () => setState(() => _filterMode = _FilterMode.month),
                        ),
                        _FModeBtn(
                          'Date Range',
                          _filterMode == _FilterMode.dateRange,
                          _pickDateRange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Month navigator OR date range display ───────────────────
                  if (_filterMode == _FilterMode.month)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month - 1,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: _month,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDatePickerMode: DatePickerMode.year,
                            );
                            if (p != null)
                              setState(
                                () => _month = DateTime(p.year, p.month),
                              );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kPrimary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              DateFormat('MMMM yyyy').format(_month),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed:
                              _month.month == DateTime.now().month &&
                                  _month.year == DateTime.now().year
                              ? null
                              : () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month + 1,
                                  ),
                                ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kPrimary.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.date_range_rounded,
                              color: kPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fromDate != null && _toDate != null
                                  ? '${DateFormat('MMM d, yyyy').format(_fromDate!)} → ${DateFormat('MMM d, yyyy').format(_toDate!)}'
                                  : 'Tap to select date range',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              color: kPrimary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── Summary row ─────────────────────────────────────────────
                  AppCard(
                    child: Row(
                      children: [
                        _SumCol('Income', totalInc, kGreen),
                        Container(
                          width: 1,
                          height: 40,
                          color: context.c.border,
                        ),
                        _SumCol('Expense', totalExp, kAccent),
                        Container(
                          width: 1,
                          height: 40,
                          color: context.c.border,
                        ),
                        _SumCol(
                          'Net',
                          net,
                          net >= 0 ? kGreen : kAccent,
                          prefix: net >= 0 ? '+' : '',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Pie chart ───────────────────────────────────────────────
                  if (cats.isNotEmpty) ...[
                    const SectionLabel('By Category'),
                    const SizedBox(height: 10),
                    AppCard(
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
                                  touchCallback: (_, r) => setState(
                                    () => _touchedPie =
                                        r
                                            ?.touchedSection
                                            ?.touchedSectionIndex ??
                                        -1,
                                  ),
                                ),
                                sections: cats.asMap().entries.map((e) {
                                  final col =
                                      kCatColors[e.key % kCatColors.length];
                                  final hit = e.key == _touchedPie;
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
                                final col =
                                    kCatColors[e.key % kCatColors.length];
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
                                          e.value.key,
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
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Bar chart ───────────────────────────────────────────────
                  const SectionLabel('Daily overview'),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Leg(kGreen, 'Income'),
                            const SizedBox(width: 12),
                            _Leg(kAccent, 'Expense'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _BarChart(expenses: period),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Filters ─────────────────────────────────────────────────
                  const SectionLabel('Filter'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FChip(
                        'Income',
                        _showIncome,
                        kGreen,
                        () => setState(() => _showIncome = !_showIncome),
                      ),
                      _FChip(
                        'Expense',
                        _showExpense,
                        kAccent,
                        () => setState(() => _showExpense = !_showExpense),
                      ),
                      ...usedCats.map(
                        (cat) => _FChip(
                          cat,
                          _filterCat == cat,
                          kPrimary,
                          () => setState(
                            () => _filterCat = _filterCat == cat ? null : cat,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Export button ───────────────────────────────────────────
                  AppCard(
                    onTap: () => _exportPdf(filtered),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: kAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Export as PDF',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Bank-style statement · ${filtered.length} transactions',
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
                            : const Icon(
                                Icons.download_rounded,
                                color: kAccent,
                                size: 20,
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Transactions ────────────────────────────────────────────
                  SectionLabel(
                    'Transactions',
                    trailing: Text(
                      '${filtered.length} items',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (filtered.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Text('📭', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions for this period',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...filtered.map((e) {
                    final isInc = e.isIncome;
                    final cidx = (isInc ? kIncomeCategories : kCategories)
                        .indexOf(e.category);
                    final col = isInc
                        ? kGreen
                        : kCatColors[cidx < 0 ? 0 : cidx % kCatColors.length];
                    final sym = currencyOf(e.currency).symbol;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: col.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  kCatEmoji[e.category] ?? '📦',
                                  style: const TextStyle(fontSize: 17),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.category} · ${DateFormat('MMM d, yyyy').format(e.date)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isInc ? '+' : '-'}$sym${e.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: col,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: col.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isInc ? 'Income' : 'Expense',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: col,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _FModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FModeBtn(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.c.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _SumCol extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;
  const _SumCol(this.label, this.amount, this.color, {this.prefix = ''});
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
          '$prefix${ExpenseService.fmt(amount.abs())}',
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

class _FChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FChip(this.label, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.12) : context.c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color : context.c.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : context.c.textMuted,
        ),
      ),
    ),
  );
}

class _BarChart extends StatelessWidget {
  final List<Expense> expenses;
  const _BarChart({required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty)
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No data for this period',
            style: TextStyle(fontSize: 12, color: context.c.textMuted),
          ),
        ),
      );

    // Group by day (or week if range > 31 days)
    final days = expenses.map((e) => e.date.day).toSet().toList()..sort();
    if (days.isEmpty) return const SizedBox.shrink();

    final groups = days.map((d) {
      final inc = expenses
          .where((e) => e.date.day == d && e.isIncome)
          .fold(0.0, (s, e) => s + e.amount);
      final exp = expenses
          .where((e) => e.date.day == d && !e.isIncome)
          .fold(0.0, (s, e) => s + e.amount);
      return BarChartGroupData(
        x: d,
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
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: context.c.textMuted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
