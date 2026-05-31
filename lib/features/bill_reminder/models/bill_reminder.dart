import 'package:hive_flutter/hive_flutter.dart';
part 'bill_reminder.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BILL REMINDER MODEL — stored in Hive box 'bill_reminders'
// ─────────────────────────────────────────────────────────────────────────────
@HiveType(typeId: 3)
class BillReminder extends HiveObject {
  @HiveField(0) String   id;
  @HiveField(1) String   title;        // "Netflix", "Rent", "Home Loan EMI"
  @HiveField(2) double   amount;
  @HiveField(3) String   category;     // Bills / Loan / Subscription / Other
  @HiveField(4) int      dayOfMonth;   // 1-31 — day the bill is due each month
  @HiveField(5) bool     isActive;
  @HiveField(6) String   currency;
  @HiveField(7) int      remindDaysBefore; // notify X days before due date
  @HiveField(8) bool     isRecurring;  // monthly=true, one-time=false
  @HiveField(9) DateTime? nextDueDate; // for one-time bills
  @HiveField(10) String  emoji;

  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dayOfMonth,
    this.isActive          = true,
    this.currency          = 'NPR',
    this.remindDaysBefore  = 3,
    this.isRecurring       = true,
    this.nextDueDate,
    this.emoji             = '📋',
  });

  // Next due date calculation
  DateTime get computedDueDate {
    if (!isRecurring && nextDueDate != null) return nextDueDate!;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, dayOfMonth.clamp(1, 28));
    return thisMonth.isBefore(now)
        ? DateTime(now.year, now.month + 1, dayOfMonth.clamp(1, 28))
        : thisMonth;
  }

  int get daysUntilDue {
    final diff = computedDueDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isOverdue => daysUntilDue == 0 &&
      DateTime.now().isAfter(computedDueDate);

  bool get isDueSoon => daysUntilDue <= remindDaysBefore;
}

// Category + emoji helpers
const kBillCategories = ['Bills', 'Loan / EMI', 'Subscription', 'Rent', 'Insurance', 'Other'];
const kBillEmojis     = {'Bills':'⚡','Loan / EMI':'🏦','Subscription':'📺',
    'Rent':'🏠','Insurance':'🛡️','Other':'📋'};