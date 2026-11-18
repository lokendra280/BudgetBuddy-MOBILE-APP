import 'dart:io';

import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/services/excel_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildStatement produces a non-empty xlsx zip', () {
    final bytes = ExcelService.buildStatement(
      expenses: [
        Expense(id: '1', title: 'Salary', amount: 1200, category: 'Salary', date: DateTime(2026, 11, 1, 9), isIncome: true),
        Expense(id: '2', title: 'Groceries & <stuff>', amount: 45.2, category: 'Food', date: DateTime(2026, 11, 2, 10, 24)),
        Expense(id: '3', title: 'Uber', amount: 12.4, category: 'Transport', date: DateTime(2026, 11, 3, 21, 15)),
      ],
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 30),
      categoryName: (c) => c,
    );
    expect(bytes.length, greaterThan(500));
    // PK zip signature
    expect(bytes.sublist(0, 2), [0x50, 0x4B]);
    final out = Platform.environment['XLSX_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
