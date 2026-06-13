import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'bill_reminder.g.dart';

@HiveType(typeId: 3)
class BillReminder extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category;
  @HiveField(4)
  int dayOfMonth;
  @HiveField(5)
  bool isActive;
  @HiveField(6)
  String currency;
  @HiveField(7)
  int remindDaysBefore;
  @HiveField(8)
  bool isRecurring;
  @HiveField(9)
  DateTime? nextDueDate;
  @HiveField(10)
  String emoji;

  // ── NEW: Payment tracking ──────────────────────────────────────────────────
  @HiveField(11)
  bool isPaid; // paid this cycle?
  @HiveField(12)
  DateTime? lastPaidAt; // when was it last paid
  @HiveField(13)
  List<DateTime> paymentHistory; // all past payment dates
  @HiveField(14)
  String notes; // user notes, e.g. "pay via PhonePe"

  // ── NEW: Supabase sync ────────────────────────────────────────────────────
  @HiveField(15)
  bool synced; // has this been pushed to Supabase?
  @HiveField(16)
  DateTime updatedAt; // last local update timestamp

  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dayOfMonth,
    this.isActive = true,
    this.currency = 'NPR',
    this.remindDaysBefore = 3,
    this.isRecurring = true,
    this.nextDueDate,
    this.emoji = '📋',
    this.isPaid = false,
    this.lastPaidAt,
    this.paymentHistory = const [],
    this.notes = '',
    this.synced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // ── Due date logic ─────────────────────────────────────────────────────────
  DateTime get computedDueDate {
    if (!isRecurring && nextDueDate != null) return nextDueDate!;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, dayOfMonth.clamp(1, 28));
    return thisMonth.isBefore(now)
        ? DateTime(now.year, now.month + 1, dayOfMonth.clamp(1, 28))
        : thisMonth;
  }

  int get daysUntilDue =>
      computedDueDate.difference(DateTime.now()).inDays.clamp(0, 999);
  bool get isOverdue => !isPaid && DateTime.now().isAfter(computedDueDate);
  bool get isDueSoon => !isPaid && daysUntilDue <= remindDaysBefore;

  // ── Payment rate (for AI) ─────────────────────────────────────────────────
  // % of months this bill was paid on time (within the due date)
  double get onTimeRate {
    if (paymentHistory.isEmpty) return 1.0;
    int onTime = 0;
    for (final pd in paymentHistory) {
      // Payment is on time if paid on or before the due day of that month
      final dueDay = DateTime(pd.year, pd.month, dayOfMonth.clamp(1, 28));
      if (!pd.isAfter(dueDay)) onTime++;
    }
    return onTime / paymentHistory.length;
  }

  // Average days late (for AI risk scoring)
  double get avgDaysLate {
    if (paymentHistory.isEmpty) return 0;
    double totalLate = 0;
    for (final pd in paymentHistory) {
      final dueDay = DateTime(pd.year, pd.month, dayOfMonth.clamp(1, 28));
      final late = pd.difference(dueDay).inDays;
      if (late > 0) totalLate += late;
    }
    return totalLate / paymentHistory.length;
  }

  // Months consistently paid (streak)
  int get paymentStreak {
    if (paymentHistory.isEmpty) return 0;
    final sorted = [...paymentHistory]..sort();
    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = sorted.length - 1; i >= 0; i--) {
      final pd = sorted[i];
      final due = DateTime(pd.year, pd.month, dayOfMonth.clamp(1, 28));
      if (pd.month == check.month &&
          pd.year == check.year &&
          !pd.isAfter(due.add(const Duration(days: 5)))) {
        streak++;
        check = DateTime(check.year, check.month - 1, 1);
      } else
        break;
    }
    return streak;
  }

  // Convert to Supabase row
  Map<String, dynamic> toSupabaseRow(String userId) => {
    'id': id,
    'user_id': userId,
    'title': title,
    'amount': amount,
    'category': category,
    'day_of_month': dayOfMonth,
    'is_active': isActive,
    'currency': currency,
    'remind_days_before': remindDaysBefore,
    'is_recurring': isRecurring,
    'next_due_date': nextDueDate?.toIso8601String(),
    'emoji': emoji,
    'is_paid': isPaid,
    'last_paid_at': lastPaidAt?.toIso8601String(),
    'payment_history': paymentHistory.map((d) => d.toIso8601String()).toList(),
    'notes': notes,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory BillReminder.fromSupabaseRow(Map<String, dynamic> r) => BillReminder(
    id: r['id'] as String,
    title: r['title'] as String,
    amount: (r['amount'] as num).toDouble(),
    category: r['category'] as String,
    dayOfMonth: r['day_of_month'] as int,
    isActive: r['is_active'] as bool? ?? true,
    currency: r['currency'] as String? ?? 'NPR',
    remindDaysBefore: r['remind_days_before'] as int? ?? 3,
    isRecurring: r['is_recurring'] as bool? ?? true,
    nextDueDate: r['next_due_date'] != null
        ? DateTime.tryParse(r['next_due_date'] as String)
        : null,
    emoji: r['emoji'] as String? ?? '📋',
    isPaid: r['is_paid'] as bool? ?? false,
    lastPaidAt: r['last_paid_at'] != null
        ? DateTime.tryParse(r['last_paid_at'] as String)
        : null,
    paymentHistory: ((r['payment_history'] as List?)?.cast<String>() ?? [])
        .map((s) => DateTime.tryParse(s) ?? DateTime.now())
        .toList(),
    notes: r['notes'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
    synced: true,
  );
}

const kBillCategories = [
  'Bills',
  'Loan / EMI',
  'Subscription',
  'Rent',
  'Insurance',
  'Other',
];
const kBillEmojis = {
  'Bills': Assets.loan,
  'Loan / EMI': Assets.loan,
  'Subscription': Assets.subscription,
  'Rent': Assets.rent,
  'Insurance': Assets.insurance,
};
