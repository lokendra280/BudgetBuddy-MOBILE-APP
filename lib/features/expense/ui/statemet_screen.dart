import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/localization/category_localization.dart';
import 'package:expensetracker/common/widgets/shimmer_widget.dart';
import 'package:expensetracker/features/expense/models/expense.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
import 'package:expensetracker/features/expense/services/pdf_service.dart';
import 'package:expensetracker/features/expense/ui/widgets/button.dart';
import 'package:expensetracker/features/expense/ui/widgets/date_range.dart';
import 'package:expensetracker/features/expense/ui/widgets/fi_chip.dart';
import 'package:expensetracker/features/expense/ui/widgets/transcation_widget.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { month, dateRange }

class StatementsScreen extends ConsumerStatefulWidget {
  const StatementsScreen({super.key});
  @override
  ConsumerState<StatementsScreen> createState() => _State();
}

class _State extends ConsumerState<StatementsScreen> {
  // ── Local UI state ─────────────────────────────────────────────────────────
  _Mode _mode = _Mode.month;
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

  // ── Period filter ──────────────────────────────────────────────────────────
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
      final from = _mode == _Mode.dateRange && _fromDate != null
          ? _fromDate!
          : DateTime(_month.year, _month.month, 1);
      final to = _mode == _Mode.dateRange && _toDate != null
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
  Widget build(BuildContext context) {
    // ── Read from providers ─────────────────────────────────────────────────
    final all = ref
        .watch(expenseProvider)
        .all; // reactive: rebuilds on any expense change
    final fmt = ref.watch(fmtProvider); // currency-aware formatter
    final sym = ref.watch(symbolProvider); // currency symbol

    // ── Derived lists ───────────────────────────────────────────────────────
    final period = _period(all);
    final filtered = _chip(period);
    final expenses = period.where((e) => !e.isIncome).toList();
    final incomes = period.where((e) => e.isIncome).toList();
    final totalExp = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalInc = incomes.fold(0.0, (s, e) => s + e.amount);
    final net = totalInc - totalExp;
    // Category map (expenses only, sorted by amount desc)
    final catMap = <String, double>{};
    for (final e in expenses)
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    final cats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final usedCats = period.map((e) => e.category).toSet().toList();

    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: context.c.surface,

        title: Text(
          AppLocalizations.of(context)!.statements,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
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
      body: _isLoading
          ? const StatementsShimmer()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              children: [
                // ── Mode toggle ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.c.border),
                  ),
                  child: Row(
                    children: [
                      ModeBtn(
                        AppLocalizations.of(context)!.month,
                        _mode == _Mode.month,
                        () => setState(() => _mode = _Mode.month),
                      ),
                      ModeBtn(
                        AppLocalizations.of(context)!.dataRange,
                        _mode == _Mode.dateRange,
                        _pickRange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Month navigator / Date range display ──────────────────────
                if (_mode == _Mode.month)
                  MonthNav(
                    month: _month,
                    onPrev: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    onNext:
                        _month.month == DateTime.now().month &&
                            _month.year == DateTime.now().year
                        ? null
                        : () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month + 1,
                            ),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _month,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null)
                        setState(
                          () => _month = DateTime(picked.year, picked.month),
                        );
                    },
                  )
                else
                  DateRange(from: _fromDate, to: _toDate, onTap: _pickRange),

                const SizedBox(height: 14),

                // ── Summary: Income / Expense / Net ──────────────────────────
                AppCard(
                  child: Row(
                    children: [
                      _SumCol(
                        AppLocalizations.of(context)!.income,
                        totalInc,
                        kGreen,
                        fmt: fmt,
                      ),
                      Container(width: 1, height: 40, color: context.c.border),
                      _SumCol(
                        AppLocalizations.of(context)!.expense,
                        totalExp,
                        kAccent,
                        fmt: fmt,
                      ),
                      Container(width: 1, height: 40, color: context.c.border),
                      _SumCol(
                        AppLocalizations.of(context)!.net,
                        net.abs(),
                        net >= 0 ? kGreen : kAccent,
                        fmt: fmt,
                        prefix: net >= 0 ? '+' : '-',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Pie chart ─────────────────────────────────────────────────
                if (cats.isNotEmpty) ...[
                  SectionLabel(AppLocalizations.of(context)!.byCategory),
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
                                      r?.touchedSection?.touchedSectionIndex ??
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
                                        CategoryLocalization.getName(
                                          AppLocalizations.of(context)!,
                                          e.value.key,
                                        ),
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

                // ── Daily bar chart ───────────────────────────────────────────
                SectionLabel(AppLocalizations.of(context)!.dailyOverview),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Leg(kGreen, AppLocalizations.of(context)!.income),
                          const SizedBox(width: 12),
                          _Leg(kAccent, AppLocalizations.of(context)!.expense),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BarChart(expenses: period),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Chip filters ──────────────────────────────────────────────
                SectionLabel(AppLocalizations.of(context)!.filter),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FiChip(
                      AppLocalizations.of(context)!.income,
                      _showIncome,
                      kGreen,
                      () => setState(() => _showIncome = !_showIncome),
                    ),
                    FiChip(
                      AppLocalizations.of(context)!.expense,
                      _showExpense,
                      kAccent,
                      () => setState(() => _showExpense = !_showExpense),
                    ),
                    ...usedCats.map(
                      (cat) => FiChip(
                        CategoryLocalization.getName(
                          AppLocalizations.of(context)!,
                          cat,
                        ),
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

                // ── Export card ───────────────────────────────────────────────
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
                              AppLocalizations.of(context)!.export,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.bankStyle} · ${filtered.length} ${AppLocalizations.of(context)!.transactions}',
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

                // ── Transactions list ─────────────────────────────────────────
                SectionLabel(
                  AppLocalizations.of(context)!.transactions,
                  trailing: Text(
                    '${filtered.length} ${AppLocalizations.of(context)!.items}',
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
                          AppLocalizations.of(context)!.noTransaction,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                ...filtered.map((e) => TransactionWidget(expense: e)),
              ],
            ),
    );
  }
}

// Summary column (Income / Expense / Net)
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

// Legend dot
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

// ─────────────────────────────────────────────────────────────────────────────
// DAILY BAR CHART — pure StatelessWidget, receives list from parent
// ─────────────────────────────────────────────────────────────────────────────
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

    final days = expenses.map((e) => e.date.day).toSet().toList()..sort();

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
