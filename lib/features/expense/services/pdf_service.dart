import 'dart:io';
import 'package:expensetracker/features/expense/services/expenses_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';

class PdfService {
  // ── Generate and share/print PDF statement ────────────────────────────────
  static Future<void> exportStatement({
    required List<Expense> expenses,
    required DateTime from,
    required DateTime to,
    bool share = true,
  }) async {
    final pdf = pw.Document();
    final sym = ExpenseService.symbol;
    final totalExp = ExpenseService.expenseFor(expenses);
    final totalInc = ExpenseService.incomeFor(expenses);
    final net = totalInc - totalExp;
    final fmt = DateFormat('MMM d, yyyy');
    final fmtFull = DateFormat('MMM d, yyyy  hh:mm a');
    final catTotals = ExpenseService.byCategory(
      expenses.where((e) => !e.isIncome).toList(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(ctx, sym, from, to, fmt),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          // ── Summary cards ─────────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                _SummaryCell(
                  'Total Income',
                  '$sym${totalInc.toStringAsFixed(2)}',
                  PdfColors.green700,
                ),
                _VDivider(),
                _SummaryCell(
                  'Total Expense',
                  '$sym${totalExp.toStringAsFixed(2)}',
                  PdfColors.red700,
                ),
                _VDivider(),
                _SummaryCell(
                  'Net Balance',
                  '${net >= 0 ? '+' : ''}$sym${net.abs().toStringAsFixed(2)}',
                  net >= 0 ? PdfColors.green700 : PdfColors.red700,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Category breakdown ─────────────────────────────────────────────
          if (catTotals.isNotEmpty) ...[
            _SectionTitle('Spending by Category'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                  children: [_TH('Category'), _TH('Amount'), _TH('% of Total')],
                ),
                ...catTotals.entries.map(
                  (e) => pw.TableRow(
                    children: [
                      _TD(e.key),
                      _TD('$sym${e.value.toStringAsFixed(2)}'),
                      _TD(
                        '${totalExp > 0 ? ((e.value / totalExp) * 100).toStringAsFixed(1) : "0.0"}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Transaction list ───────────────────────────────────────────────
          _SectionTitle('All Transactions (${expenses.length})'),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
                children: [
                  _TH('Description'),
                  _TH('Date & Time'),
                  _TH('Category'),
                  _TH('Amount'),
                ],
              ),
              // Data rows — alternating background
              ...expenses.asMap().entries.map((e) {
                final exp = e.value;
                final isInc = exp.isIncome;
                final amtStr =
                    '${isInc ? '+' : '-'}${currencyOf(exp.currency).symbol}${exp.amount.toStringAsFixed(2)}';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key.isEven ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _TD(exp.title, bold: false),
                    _TD(fmtFull.format(exp.date)),
                    _TD(exp.category),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: pw.Text(
                        amtStr,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: isInc ? PdfColors.green700 : PdfColors.red700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    if (share) {
      final dir = await getTemporaryDirectory();
      final name =
          'BudgetBuddy_Statement_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject:
            'BudgetBuddy Statement — ${fmt.format(from)} to ${fmt.format(to)}',
      );
    } else {
      // Print directly
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  static pw.Widget _header(
    pw.Context ctx,
    String sym,
    DateTime from,
    DateTime to,
    DateFormat fmt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BudgetBuddy',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.Text(
                  'Personal Finance Statement',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Statement Period',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  '${fmt.format(from)} → ${fmt.format(to)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated: ${fmt.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColors.indigo200, thickness: 1.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) => pw.Column(
    children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SpendSense — Personal Finance Tracker',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _SummaryCell(String label, String value, PdfColor valueColor) =>
    pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );

pw.Widget _VDivider() =>
    pw.Container(width: 1, height: 50, color: PdfColors.grey300);

pw.Widget _SectionTitle(String text) => pw.Text(
  text,
  style: pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.indigo700,
  ),
);

pw.Widget _TH(String t) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  child: pw.Text(
    t,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.indigo800,
    ),
  ),
);

pw.Widget _TD(String t, {bool bold = false}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  child: pw.Text(
    t,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: bold ? pw.FontWeight.bold : null,
    ),
    maxLines: 2,
  ),
);
