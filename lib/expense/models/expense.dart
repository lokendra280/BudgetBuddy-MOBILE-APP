import 'package:hive_flutter/hive_flutter.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category;
  @HiveField(4)
  DateTime date;
  @HiveField(5)
  bool isIncome;
  @HiveField(6)
  String currency; // 'NPR','USD','INR','GBP','EUR'

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isIncome = false,
    this.currency = 'NPR',
  });
}

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  double monthlyLimit;
  @HiveField(1)
  int streakDays;
  @HiveField(2)
  String lastActiveDate;
  @HiveField(3)
  String? referralCode;
  @HiveField(4)
  int referralCount;
  @HiveField(5)
  String currency; // user's preferred currency

  Budget({
    this.monthlyLimit = 10000,
    this.streakDays = 0,
    this.lastActiveDate = '',
    this.referralCode,
    this.referralCount = 0,
    this.currency = 'NPR',
  });
}

// ── Currency config ────────────────────────────────────────────────────────
class CurrencyInfo {
  final String code, symbol, name, flag;
  const CurrencyInfo(this.code, this.symbol, this.name, this.flag);
}

const kCurrencies = [
  CurrencyInfo('NPR', 'Rs.', 'Nepali Rupee', '🇳🇵'),
  CurrencyInfo('USD', '\$', 'US Dollar', '🇺🇸'),
  CurrencyInfo('INR', '₹', 'Indian Rupee', '🇮🇳'),
  CurrencyInfo('GBP', '£', 'British Pound', '🇬🇧'),
  CurrencyInfo('EUR', '€', 'Euro', '🇪🇺'),
  CurrencyInfo('AUD', 'A\$', 'Australian Dollar', '🇦🇺'),
];

CurrencyInfo currencyOf(String code) => kCurrencies.firstWhere(
  (c) => c.code == code,
  orElse: () => kCurrencies.first,
);

const kCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Health',
  'Bills',
  'Entertainment',
  'Other',
];
const kIncomeCategories = [
  'Salary',
  'Freelance',
  'Business',
  'Investment',
  'Gift',
  'Other',
];

const kCatEmoji = {
  'Food': '🍜',
  'Transport': '🚗',
  'Shopping': '🛍',
  'Health': '💊',
  'Bills': '⚡',
  'Entertainment': '🎬',
  'Other': '📦',
  'Salary': '💼',
  'Freelance': '💻',
  'Business': '🏢',
  'Investment': '📈',
  'Gift': '🎁',
};
