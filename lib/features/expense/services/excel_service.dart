import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart' show Rect;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';

/// Builds an .xlsx statement and opens the share sheet.
///
/// Written directly with `archive` (an .xlsx is a zip of XML parts) instead
/// of the `excel` package, which is incompatible with archive 4.x that the
/// rest of the app depends on.
///
/// Sheets:
///   • "Statement"   — summary block + one row per transaction
///   • "By Category" — expense totals per category, sorted high → low
class ExcelService {
  ExcelService._();

  /// [categoryName] maps a category key to its display (localized) name.
  /// [shareOrigin] is required for the share popover on iPad.
  static Future<void> exportStatement({
    required List<Expense> expenses,
    required DateTime from,
    required DateTime to,
    required String Function(String) categoryName,
    Rect? shareOrigin,
  }) async {
    final bytes = buildStatement(
      expenses: expenses,
      from: from,
      to: to,
      categoryName: categoryName,
    );

    final dir = await getTemporaryDirectory();
    final f = DateFormat('yyyyMMdd');
    final dFmt = DateFormat('MMM d, yyyy');
    final file = File(
      '${dir.path}/BudgetBuddy_Statement_${f.format(from)}_${f.format(to)}.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject:
          'BudgetBuddy Statement — ${dFmt.format(from)} to ${dFmt.format(to)}',
      sharePositionOrigin: shareOrigin,
    );
  }

  /// Pure function: returns the .xlsx bytes (handy for tests).
  static List<int> buildStatement({
    required List<Expense> expenses,
    required DateTime from,
    required DateTime to,
    required String Function(String) categoryName,
  }) {
    final rows = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
    final dFmt = DateFormat('MMM d, yyyy');

    final income = rows
        .where((e) => e.isIncome)
        .fold(0.0, (s, e) => s + e.amount);
    final expense = rows
        .where((e) => !e.isIncome)
        .fold(0.0, (s, e) => s + e.amount);

    // ── Sheet 1: Statement ───────────────────────────────────────────────
    final st = _SheetBuilder([14, 9, 30, 20, 11, 15, 10]);
    st.row(0, [_C.text('BudgetBuddy Statement', _S.title)]);
    st.row(1, [
      _C.text('Period', _S.label),
      _C.text('${dFmt.format(from)} – ${dFmt.format(to)}'),
    ]);
    st.row(2, [_C.text('Total income', _S.label), _C.num(income, _S.income)]);
    st.row(3, [
      _C.text('Total expense', _S.label),
      _C.num(expense, _S.expense),
    ]);
    st.row(4, [_C.text('Net', _S.label), _C.num(income - expense, _S.moneyBold)]);
    st.row(5, [
      _C.text('Transactions', _S.label),
      _C.num(rows.length.toDouble()),
    ]);

    const headerRow = 7;
    st.row(headerRow, [
      for (final h in const [
        'Date',
        'Time',
        'Title',
        'Category',
        'Type',
        'Amount',
        'Currency',
      ])
        _C.text(h, _S.header),
    ]);

    for (var i = 0; i < rows.length; i++) {
      final e = rows[i];
      final stripe = i.isOdd ? _S.stripe : _S.none;
      st.row(headerRow + 1 + i, [
        _C.text(DateFormat('yyyy-MM-dd').format(e.date), stripe),
        _C.text(DateFormat('HH:mm').format(e.date), stripe),
        _C.text(e.title, stripe),
        _C.text(categoryName(e.category), stripe),
        _C.text(e.isIncome ? 'Income' : 'Expense', stripe),
        // Expenses negative so the column can be summed directly.
        _C.num(
          e.isIncome ? e.amount : -e.amount,
          e.isIncome ? _S.income : _S.expense,
        ),
        _C.text(e.currency, stripe),
      ]);
    }

    // ── Sheet 2: By Category ─────────────────────────────────────────────
    final byCat = <String, double>{};
    final countCat = <String, int>{};
    for (final e in rows.where((e) => !e.isIncome)) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
      countCat[e.category] = (countCat[e.category] ?? 0) + 1;
    }
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cs = _SheetBuilder([24, 14, 16, 12]);
    cs.row(0, [
      for (final h in const ['Category', 'Transactions', 'Amount', '% of spend'])
        _C.text(h, _S.header),
    ]);
    for (var i = 0; i < cats.length; i++) {
      cs.row(i + 1, [
        _C.text(categoryName(cats[i].key)),
        _C.num((countCat[cats[i].key] ?? 0).toDouble()),
        _C.num(cats[i].value, _S.money),
        _C.num(expense > 0 ? cats[i].value / expense : 0, _S.percent),
      ]);
    }
    cs.row(cats.length + 1, [
      _C.text('Total', _S.label),
      null,
      _C.num(expense, _S.moneyBold),
    ]);

    return _zip({
      'Statement': st.xml(),
      'By Category': cs.xml(),
    });
  }

  // ── Package the parts ──────────────────────────────────────────────────
  static List<int> _zip(Map<String, String> sheets) {
    final names = sheets.keys.toList();
    final archive = Archive();
    void add(String path, String content) =>
        archive.addFile(ArchiveFile.bytes(path, utf8.encode(content)));

    add('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[for (var i = 0; i < names.length; i++) '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join('\n')}
</Types>''');

    add('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');

    add('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
${[for (var i = 0; i < names.length; i++) '<sheet name="${_esc(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join('\n')}
</sheets>
</workbook>''');

    add('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[for (var i = 0; i < names.length; i++) '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'].join('\n')}
<Relationship Id="rId${names.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''');

    add('xl/styles.xml', _stylesXml);

    for (var i = 0; i < names.length; i++) {
      add('xl/worksheets/sheet${i + 1}.xml', sheets[names[i]]!);
    }

    return ZipEncoder().encode(archive);
  }

  // Font / fill / cellXfs indices line up with the _S constants below.
  static const _stylesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="7">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="16"/><color rgb="FF0E4A30"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FF606080"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
<font><sz val="11"/><color rgb="FF10B981"/><name val="Calibri"/></font>
<font><sz val="11"/><color rgb="FFF43F5E"/><name val="Calibri"/></font>
</fonts>
<fills count="4">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF0E4A30"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFE3F4EA"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="10">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center"/></xf>
<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
<xf numFmtId="4" fontId="4" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>
<xf numFmtId="4" fontId="5" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>
<xf numFmtId="4" fontId="6" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>
<xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/>
<xf numFmtId="10" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
}

// Style ids → index into <cellXfs>.
abstract final class _S {
  static const none = 0;
  static const title = 1;
  static const label = 2;
  static const header = 3;
  static const money = 4;
  static const moneyBold = 5;
  static const income = 6;
  static const expense = 7;
  static const stripe = 8;
  static const percent = 9;
}

class _C {
  final String? text;
  final double? number;
  final int style;
  const _C.text(String this.text, [this.style = _S.none]) : number = null;
  const _C.num(double this.number, [this.style = _S.none]) : text = null;
}

class _SheetBuilder {
  final List<double> widths;
  final _rows = <int, List<_C?>>{};
  _SheetBuilder(this.widths);

  void row(int index, List<_C?> cells) => _rows[index] = cells;

  String xml() {
    final b = StringBuffer()
      ..write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<cols>',
      );
    for (var i = 0; i < widths.length; i++) {
      b.write(
        '<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>',
      );
    }
    b.write('</cols><sheetData>');

    final keys = _rows.keys.toList()..sort();
    for (final r in keys) {
      b.write('<row r="${r + 1}">');
      final cells = _rows[r]!;
      for (var c = 0; c < cells.length; c++) {
        final cell = cells[c];
        if (cell == null) continue;
        final ref = '${_col(c)}${r + 1}';
        final s = cell.style == _S.none ? '' : ' s="${cell.style}"';
        if (cell.number != null) {
          final v = cell.number!;
          b.write('<c r="$ref"$s><v>${v.isFinite ? v : 0}</v></c>');
        } else {
          b.write(
            '<c r="$ref"$s t="inlineStr"><is><t xml:space="preserve">'
            '${_esc(cell.text!)}</t></is></c>',
          );
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  static String _col(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final m = (n - 1) % 26;
      s = String.fromCharCode(65 + m) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // strip control chars that are illegal in XML 1.0
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
