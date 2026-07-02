// lib/features/bill_reminder/services/emi_cycle_service.dart

import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';

class EmiCycleService {
  EmiCycleService._();

  static DateTime dueDateFor(EmiLoan loan, int year, int month) {
    final normalizedYear = year + (month - 1) ~/ 12;
    final normalizedMonth = (month - 1) % 12 + 1;
    final lastDay = DateTime(normalizedYear, normalizedMonth + 1, 0).day;
    final d = loan.dayOfMonth > lastDay ? lastDay : loan.dayOfMonth;
    return DateTime(normalizedYear, normalizedMonth, d);
  }

  static bool paidForCurrentCycle(EmiLoan loan) {
    final now = DateTime.now();
    final cycleStart = dueDateFor(loan, now.year, now.month - 1);
    return loan.payments.any(
      (p) =>
          !p.isExtraPayment &&
          p.date.isAfter(cycleStart) &&
          !p.date.isAfter(now),
    );
  }

  static bool showPaymentReminder(EmiLoan loan) {
    if (!loan.isActive) return false;
    if (!paidForCurrentCycle(loan)) return true;

    final now = DateTime.now();
    final nextDue = dueDateFor(loan, now.year, now.month + 1);
    return !now.isBefore(nextDue.subtract(const Duration(days: 7)));
  }
}
