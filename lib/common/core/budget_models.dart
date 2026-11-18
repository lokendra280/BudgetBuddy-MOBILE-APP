import 'dart:io' show Platform;
import 'dart:math';

import 'package:intl/intl.dart';

/// The two markets these features are tuned for.
enum Country {
  us('USD', 'en_US', 'United States'),
  ca('CAD', 'en_CA', 'Canada');

  const Country(this.currencyCode, this.locale, this.label);

  final String currencyCode;
  final String locale;
  final String label;

  /// Canada for any *_CA device locale (en_CA, fr_CA), otherwise the US.
  static Country fromDevice() =>
      RegExp(r'[_-]CA\b').hasMatch(Platform.localeName)
      ? Country.ca
      : Country.us;

  /// US or Canada from the device region, or null for everyone else.
  /// Use it to show US/Canada-only features (tax, holidays) only where they apply.
  static Country? marketFromDevice() {
    final locale = Platform.localeName;
    if (RegExp(r'[_-]CA\b').hasMatch(locale)) return Country.ca;
    if (RegExp(r'[_-]US\b').hasMatch(locale)) return Country.us;
    return null;
  }

  NumberFormat get currency =>
      NumberFormat.simpleCurrency(locale: locale, name: currencyCode);
}

/// A single expense. If your app already has a transaction model, either
/// replace this class with yours or convert to/from it in your data source.
class BudgetTransaction {
  const BudgetTransaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    this.salesTax,
    this.receiptImagePath,
    this.addedBy,
    this.addedByName,
  });

  final String id;
  final String merchant;

  /// Positive = money spent. Negative = refund or income.
  final double amount;
  final DateTime date;
  final String category;
  final String? note;

  /// Sales tax read from a receipt (GST/HST/PST/QST in Canada).
  final double? salesTax;
  final String? receiptImagePath;

  /// Household sharing: who added this transaction.
  final String? addedBy;
  final String? addedByName;

  BudgetTransaction copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    String? category,
    String? note,
    double? salesTax,
    String? receiptImagePath,
  }) => BudgetTransaction(
    id: id,
    merchant: merchant ?? this.merchant,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    category: category ?? this.category,
    note: note ?? this.note,
    salesTax: salesTax ?? this.salesTax,
    receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    addedBy: addedBy,
    addedByName: addedByName,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'merchant': merchant,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    if (note != null) 'note': note,
    if (salesTax != null) 'salesTax': salesTax,
    if (receiptImagePath != null) 'receiptImagePath': receiptImagePath,
    if (addedBy != null) 'addedBy': addedBy,
    if (addedByName != null) 'addedByName': addedByName,
  };

  factory BudgetTransaction.fromMap(Map<String, dynamic> map) =>
      BudgetTransaction(
        id: map['id'] as String,
        merchant: map['merchant'] as String? ?? '',
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        category: map['category'] as String? ?? 'Other',
        note: map['note'] as String?,
        salesTax: (map['salesTax'] as num?)?.toDouble(),
        receiptImagePath: map['receiptImagePath'] as String?,
        addedBy: map['addedBy'] as String?,
        addedByName: map['addedByName'] as String?,
      );
}

/// The only thing you need to implement to plug these features into your app.
/// Back it with whatever you already use (sqflite, Hive, Isar, Drift, an API...).
abstract class BudgetDataSource {
  /// Transactions with `from <= date < to`.
  Future<List<BudgetTransaction>> getTransactions({
    required DateTime from,
    required DateTime to,
  });

  Future<void> addTransaction(BudgetTransaction transaction);

  /// The user's total monthly spending budget.
  Future<double> getMonthlyBudget();

  /// The category names your app uses (e.g. Groceries, Dining, Shopping).
  List<String> get categories;
}

// ---------------------------------------------------------------------------
// Date helpers
// ---------------------------------------------------------------------------

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
DateTime startOfNextMonth(DateTime d) => DateTime(d.year, d.month + 1);
int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
DateTime plusDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [a] to [b] (DST-safe).
int daysBetween(DateTime a, DateTime b) =>
    (startOfDay(b).difference(startOfDay(a)).inHours / 24).round();

/// Adds a positive number of months, clamping the day (Jan 31 + 1 month = Feb 28/29).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final day = min(d.day, DateTime(year, month + 1, 0).day);
  return DateTime(year, month, day, d.hour, d.minute);
}

// ---------------------------------------------------------------------------
// IDs
// ---------------------------------------------------------------------------

final _random = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_random.nextInt(1 << 32).toRadixString(36)}';

/// Stable 31-bit hash (FNV-1a). Used for notification IDs, which must stay the
/// same across app launches (String.hashCode is not guaranteed to).
int stableId(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
