import 'package:hive_flutter/hive_flutter.dart';
part 'emi_loan.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EMI / Loan Model  ·  typeId: 4
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 6)
class EmiLoan extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title; // "Home Loan", "Car EMI"
  @HiveField(2)
  String lenderName; // "HDFC Bank"
  @HiveField(3)
  double principalAmount;
  @HiveField(4)
  double emiAmount; // fixed monthly EMI
  @HiveField(5)
  double interestRate; // annual % (0 = interest-free)
  @HiveField(6)
  int tenureMonths;
  @HiveField(7)
  DateTime startDate;
  @HiveField(8)
  int dayOfMonth; // due day 1–28
  @HiveField(9)
  String currency;
  @HiveField(10)
  String category; // Home / Car / Personal …
  @HiveField(11)
  String emoji;
  @HiveField(12)
  bool isActive;
  @HiveField(13)
  List<EmiPayment> payments;
  @HiveField(14)
  double totalExtraPayments;
  @HiveField(15)
  int remindDaysBefore;
  @HiveField(16)
  bool remindersEnabled;
  @HiveField(17)
  String notes;
  @HiveField(18)
  bool synced;
  @HiveField(19)
  DateTime updatedAt;

  EmiLoan({
    required this.id,
    required this.title,
    required this.lenderName,
    required this.principalAmount,
    required this.emiAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.startDate,
    required this.dayOfMonth,
    this.currency = 'NPR',
    this.category = 'Personal',
    this.emoji = '🏦',
    this.isActive = true,
    this.payments = const [],
    this.totalExtraPayments = 0,
    this.remindDaysBefore = 3,
    this.remindersEnabled = true,
    this.notes = '',
    this.synced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // ── Totals ─────────────────────────────────────────────────────────────────
  double get totalPayable => emiAmount * tenureMonths;
  double get totalInterest => totalPayable - principalAmount;

  // ── Progress ───────────────────────────────────────────────────────────────
  int get emisPaid => payments.where((p) => !p.isExtraPayment).length;
  int get emisRemaining => (tenureMonths - emisPaid).clamp(0, tenureMonths);
  double get progressRatio => (emisPaid / tenureMonths).clamp(0.0, 1.0);

  int get monthsElapsed {
    final now = DateTime.now();
    return ((now.year - startDate.year) * 12 + (now.month - startDate.month))
        .clamp(0, tenureMonths);
  }

  // ── Balance ────────────────────────────────────────────────────────────────
  double get remainingBalance {
    if (interestRate <= 0) {
      final paid = payments.fold(0.0, (s, p) => s + p.amount);
      return (principalAmount - paid).clamp(0, principalAmount);
    }
    final r = interestRate / 12 / 100;
    final n = emisPaid;
    final pow = _pow(1 + r, n);
    final outstanding = principalAmount * pow - emiAmount * (pow - 1) / r;
    return (outstanding - totalExtraPayments).clamp(0, principalAmount);
  }

  double get interestPaidSoFar {
    final principalPaid = principalAmount - remainingBalance;
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    return (totalPaid - principalPaid).clamp(0, totalInterest);
  }

  // ── Dates ──────────────────────────────────────────────────────────────────
  DateTime get estimatedEndDate =>
      DateTime(startDate.year, startDate.month + tenureMonths);

  DateTime get nextDueDate {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, dayOfMonth.clamp(1, 28));
    return thisMonth.isBefore(now)
        ? DateTime(now.year, now.month + 1, dayOfMonth.clamp(1, 28))
        : thisMonth;
  }

  int get daysUntilDue =>
      nextDueDate.difference(DateTime.now()).inDays.clamp(0, 999);

  bool get isOverdue {
    if (payments.isNotEmpty) {
      final last = payments.last.date;
      if (last.month == DateTime.now().month &&
          last.year == DateTime.now().year)
        return false;
    }
    return DateTime.now().isAfter(nextDueDate);
  }

  bool get isDueSoon => daysUntilDue <= remindDaysBefore && !isOverdue;

  // ── Missed payments ────────────────────────────────────────────────────────
  int get missedPayments {
    int missed = 0;
    for (int i = 0; i < monthsElapsed; i++) {
      final m = DateTime(startDate.year, startDate.month + i);
      final paid = payments.any(
        (p) => p.date.month == m.month && p.date.year == m.year,
      );
      if (!paid) missed++;
    }
    return missed;
  }

  // ── Early payoff simulation ────────────────────────────────────────────────
  EarlyPayoffResult simulateEarlyPayoff(double extraPerMonth) {
    if (extraPerMonth <= 0)
      return const EarlyPayoffResult(monthsSaved: 0, interestSaved: 0);
    final r = interestRate > 0 ? interestRate / 12 / 100 : 0.0;
    var balance = remainingBalance;
    int months = 0;
    double totalInt = 0;
    while (balance > 0 && months < 600) {
      final interest = r > 0 ? balance * r : 0.0;
      totalInt += interest;
      balance -= (emiAmount + extraPerMonth - interest);
      months++;
    }
    final normalInt = r > 0
        ? calcRemainingInterest()
        : emiAmount * emisRemaining - remainingBalance;
    return EarlyPayoffResult(
      monthsSaved: (emisRemaining - months).clamp(0, emisRemaining),
      interestSaved: (normalInt - totalInt).clamp(0, normalInt),
    );
  }

  double _calcRemainingInterest() => calcRemainingInterest();

  double calcRemainingInterest() {
    final r = interestRate / 12 / 100;
    var balance = remainingBalance;
    double totalInt = 0;
    int months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * r;
      totalInt += interest;
      balance -= (emiAmount - interest);
      months++;
    }
    return totalInt;
  }

  // ── Amortisation schedule ──────────────────────────────────────────────────
  List<AmortisationEntry> get amortisationSchedule {
    final entries = <AmortisationEntry>[];
    final r = interestRate > 0 ? interestRate / 12 / 100 : 0.0;
    double balance = principalAmount;
    for (int i = 0; i < tenureMonths; i++) {
      final interest = balance * r;
      final double principal = (emiAmount - interest)
          .clamp(0, balance)
          .toDouble();
      balance = (balance - principal)
          .clamp(0, principalAmount.toDouble())
          .toDouble();
      entries.add(
        AmortisationEntry(
          month: i + 1,
          date: DateTime(startDate.year, startDate.month + i, dayOfMonth),
          emiAmount: emiAmount,
          principal: principal,
          interest: interest,
          balance: balance,
        ),
      );
    }
    return entries;
  }
}

// ── EmiPayment ────────────────────────────────────────────────────────────────

@HiveType(typeId: 5)
class EmiPayment extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  double amount;
  @HiveField(3)
  bool isExtraPayment;
  @HiveField(4)
  String note;

  EmiPayment({
    required this.id,
    required this.date,
    required this.amount,
    this.isExtraPayment = false,
    this.note = '',
  });
}

// ── Value objects ─────────────────────────────────────────────────────────────

class EarlyPayoffResult {
  final int monthsSaved;
  final double interestSaved;
  const EarlyPayoffResult({
    required this.monthsSaved,
    required this.interestSaved,
  });
}

class AmortisationEntry {
  final int month;
  final DateTime date;
  final double emiAmount, principal, interest, balance;
  const AmortisationEntry({
    required this.month,
    required this.date,
    required this.emiAmount,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────
double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) r *= base;
  return r;
}

// ── Constants ─────────────────────────────────────────────────────────────────
const kLoanCategories = [
  'Home',
  'Car',
  'Personal',
  'Education',
  'Business',
  'Other',
];
const kLoanEmojis = {
  'Home': '🏠',
  'Car': '🚗',
  'Personal': '👤',
  'Education': '🎓',
  'Business': '💼',
  'Other': '🏦',
};
