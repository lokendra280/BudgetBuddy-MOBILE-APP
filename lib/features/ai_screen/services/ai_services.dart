import 'dart:math';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/services/expenses_service.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class AiSuggestion {
  final String emoji, title, body;
  final int color;
  const AiSuggestion({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });
}

class RecurringExpense {
  final String title, category, emoji;
  final double avgAmount;
  final int occurrences;
  final DateTime nextEstimate;
  const RecurringExpense({
    required this.title,
    required this.category,
    required this.emoji,
    required this.avgAmount,
    required this.occurrences,
    required this.nextEstimate,
  });
}

class SmartBudget {
  final double income, needsBudget, wantsBudget, savingsGoal, currentSpend;
  const SmartBudget({
    required this.income,
    required this.needsBudget,
    required this.wantsBudget,
    required this.savingsGoal,
    required this.currentSpend,
  });
  double get needsUsedPct =>
      needsBudget > 0 ? (currentSpend / needsBudget).clamp(0, 2) : 0;
  double get savingsPct => income > 0 ? (savingsGoal / income * 100) : 0;
}

class FinancialHealthScore {
  final int score;
  final String grade, headline;
  final List<ScoreFactor> factors;
  const FinancialHealthScore({
    required this.score,
    required this.grade,
    required this.headline,
    required this.factors,
  });
  Color get color {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF6366F1);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFF43F5E);
  }
}

class ScoreFactor {
  final String labelKey; // ← localization key, resolved in UI
  final String emoji;
  final String detailKey; // ← localization key for detail
  final List<String> detailArgs; // ← dynamic values for detail string
  final int score;

  const ScoreFactor({
    required this.labelKey,
    required this.emoji,
    required this.score,
    required this.detailKey,
    this.detailArgs = const [],
  });

  /// Resolve label using AppLocalizations
  String resolveLabel(AppLocalizations l) => _resolveLabel(labelKey, l);

  /// Resolve detail using AppLocalizations + dynamic args
  String resolveDetail(AppLocalizations l) =>
      _resolveDetail(detailKey, detailArgs, l);

  static String _resolveLabel(String key, AppLocalizations l) {
    switch (key) {
      case 'savingsRate':
        return l.savingsRate;
      case 'budgetControl':
        return l.budgetControl;
      case 'expenseBalance':
        return l.expenseBalance;
      case 'consistency':
        return l.consistency;
      case 'billLoad':
        return l.billLoad;
      case 'goalProgress':
        return l.goalProgress;
      default:
        return key;
    }
  }

  static String _resolveDetail(
    String key,
    List<String> args,
    AppLocalizations l,
  ) {
    try {
      switch (key) {
        case 'pctSaved':
          return '${args[0]}% ${l.saved}';
        case 'noIncomeLogged':
          return l.noIncomeLooged;
        case 'pctOfLimitUsed':
          return '${args[0]}% ${l.ofLimitUsed}';
        case 'noBudgetSet':
          return l.noBudgetSet;
        case 'topCategory':
          return '${l.top}: ${args[0]} ${args[1]}%';
        case 'noExpensesYet':
          return l.noExpensesYet;
        case 'dayStreak':
          return '${args[0]} ${l.dayStreak}';
        case 'pctOfIncomeCommitted':
          return '${args[0]}% ${l.ofIncomeCommitted}';
        case 'inBills':
          return '${args[0]}${l.perMonth} ${l.inBills}';
        case 'noActiveBills':
          return l.noActiveBills;
        case 'goalsInProgress':
          return '${args[0]} ${l.inProgress}';
        case 'noActiveGoals':
          return l.noActiveGoals;
        default:
          return key;
      }
    } catch (_) {
      // Fallback if any localization key is missing
      return key;
    }
  }
}

class BurnRate {
  final double dailySpend, monthlySpend, income;
  final int runwayDays;
  const BurnRate({
    required this.dailySpend,
    required this.monthlySpend,
    required this.income,
    required this.runwayDays,
  });
}

class ExpensePrediction {
  final double nextMonthExpense, nextMonthIncome, futureBalance;
  final List<CategoryPrediction> byCategory;
  const ExpensePrediction({
    required this.nextMonthExpense,
    required this.nextMonthIncome,
    required this.futureBalance,
    required this.byCategory,
  });
}

class CategoryPrediction {
  final String category, emoji;
  final double predicted, lastMonth;
  const CategoryPrediction({
    required this.category,
    required this.emoji,
    required this.predicted,
    required this.lastMonth,
  });
  double get changePercent =>
      lastMonth > 0 ? ((predicted - lastMonth) / lastMonth * 100) : 0;
  bool get isUp => predicted > lastMonth;
}

class SmartAlert {
  final String type, emoji, title, body;
  final int severityColor;
  const SmartAlert({
    required this.type,
    required this.emoji,
    required this.title,
    required this.body,
    required this.severityColor,
  });
}

class SubscriptionItem {
  final String name, emoji, category, frequency;
  final double amount;
  final int color;
  const SubscriptionItem({
    required this.name,
    required this.emoji,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.color,
  });
  String get title => name;
  String get schedule => frequency;
  double get monthlyEquivalent => frequency == 'yearly' ? amount / 12 : amount;
}

class CoachTip {
  final String emoji, title, action, impact;
  final int impactColor;
  const CoachTip({
    required this.emoji,
    required this.title,
    required this.action,
    required this.impact,
    required this.impactColor,
  });
}

class BillHealthSummary {
  final double totalMonthlyCommitment;
  final double incomeCommitmentRatio;
  final List<BillReminder> overdueList;
  final List<BillReminder> dueSoonList;
  final List<BillReminder> largestBills;
  const BillHealthSummary({
    required this.totalMonthlyCommitment,
    required this.incomeCommitmentRatio,
    required this.overdueList,
    required this.dueSoonList,
    required this.largestBills,
  });
  bool get isCritical => incomeCommitmentRatio > 0.5;
  bool get isHigh => incomeCommitmentRatio > 0.35;
}

class GoalInsight {
  final String id, name, emoji;
  final double target, saved, progress;
  final int daysLeft;
  final double requiredDailyAmount;
  final double availableDailyAmount;
  final bool onTrack;
  final String statusMessage;
  const GoalInsight({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.progress,
    required this.daysLeft,
    required this.requiredDailyAmount,
    required this.availableDailyAmount,
    required this.onTrack,
    required this.statusMessage,
  });
}

class CashFlowForecast {
  final double projectedIncome;
  final double projectedExpenses;
  final double upcomingBillsTotal;
  final double goalsRequiredThisMonth;
  final double projectedSurplus;
  final List<String> warnings;
  const CashFlowForecast({
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.upcomingBillsTotal,
    required this.goalsRequiredThisMonth,
    required this.projectedSurplus,
    required this.warnings,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Colors
// ─────────────────────────────────────────────────────────────────────────────

Color get kAiGreen => const Color(0xFF10B981);
Color get kAiAmber => const Color(0xFFF59E0B);
Color get kAiRed => const Color(0xFFF43F5E);
Color get kAiPurple => const Color(0xFF6366F1);

// ─────────────────────────────────────────────────────────────────────────────
// AiService
// ─────────────────────────────────────────────────────────────────────────────

class AiService {
  AiService._();

  static List<BillReminder> get _bills => HiveStorage.allBillReminders();
  static List<GoalEntry> get _goals => HiveStorage.allGoals();

  // ── 1. Smart Budget ────────────────────────────────────────────────────────
  static SmartBudget smartBudget() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final effectiveIncome = income > 0
        ? income
        : ExpenseService.budget.monthlyLimit;
    final billsThisMonth = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    final disposable = (effectiveIncome - billsThisMonth).clamp(
      0.0,
      effectiveIncome,
    );
    return SmartBudget(
      income: effectiveIncome,
      needsBudget: disposable * 0.50 + billsThisMonth,
      wantsBudget: disposable * 0.30,
      savingsGoal: disposable * 0.20,
      currentSpend: spent,
    );
  }

  // ── 2. Health Score ────────────────────────────────────────────────────────
  static FinancialHealthScore healthScore() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final budget = ExpenseService.budget;
    final cats = ExpenseService.byCategory(
      month.where((e) => !e.isIncome).toList(),
    );

    final savingsScore = income > 0
        ? ((income - spent) / income).clamp(0.0, 1.0) * 25
        : 0.0;
    final budgetScore = budget.monthlyLimit > 0
        ? (1 - (spent / budget.monthlyLimit)).clamp(0.0, 1.0) * 20
        : 10.0;
    double controlScore = 15;
    if (cats.isNotEmpty && spent > 0) {
      final topPct = cats.values.first / spent;
      controlScore = topPct > 0.6
          ? 3
          : topPct > 0.4
          ? 9
          : 15;
    }
    final streakScore = (budget.streakDays / 30 * 15).clamp(0.0, 15.0);
    final billsMonthly = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    double billScore = 15;
    if (income > 0 && billsMonthly > 0) {
      final ratio = billsMonthly / income;
      billScore = ratio > 0.6
          ? 0
          : ratio > 0.45
          ? 5
          : ratio > 0.3
          ? 10
          : 15;
    }
    final activeGoals = _goals.where(
      (g) => g.daysLeft > 0 && g.saved < g.target,
    );
    double goalScore = 10;
    if (activeGoals.isNotEmpty) {
      final avgProgress =
          activeGoals.fold(
            0.0,
            (s, g) => s + (g.target > 0 ? g.saved / g.target : 0),
          ) /
          activeGoals.length;
      goalScore = (avgProgress * 10).clamp(0.0, 10.0);
    }

    final total =
        (savingsScore +
                budgetScore +
                controlScore +
                streakScore +
                billScore +
                goalScore)
            .round()
            .clamp(0, 100);

    final grade = total >= 90
        ? 'A+'
        : total >= 80
        ? 'A'
        : total >= 70
        ? 'B'
        : total >= 50
        ? 'C'
        : 'D';
    final headline = total >= 80
        ? 'Excellent financial health! 🏆'
        : total >= 60
        ? 'Good — keep improving 👍'
        : total >= 40
        ? 'Needs attention'
        : 'Take action now 🚨';

    return FinancialHealthScore(
      score: total,
      grade: grade,
      headline: headline,
      factors: [
        ScoreFactor(
          labelKey: 'savingsRate',
          emoji: Assets.saving,
          score: (savingsScore / 25 * 100).round().clamp(0, 100),
          detailKey: income > 0 ? 'pctSaved' : 'noIncomeLogged',
          detailArgs: income > 0
              ? ['${((income - spent) / income * 100).clamp(0, 100).toInt()}']
              : [],
        ),
        ScoreFactor(
          labelKey: 'budgetControl',
          emoji: Assets.goal,
          score: (budgetScore / 20 * 100).round().clamp(0, 100),
          detailKey: budget.monthlyLimit > 0 ? 'pctOfLimitUsed' : 'noBudgetSet',
          detailArgs: budget.monthlyLimit > 0
              ? ['${(spent / budget.monthlyLimit * 100).toInt()}']
              : [],
        ),
        ScoreFactor(
          labelKey: 'expenseBalance',
          emoji: Assets.balance,
          score: (controlScore / 15 * 100).round().clamp(0, 100),
          detailKey: cats.isNotEmpty ? 'topCategory' : 'noExpensesYet',
          detailArgs: cats.isNotEmpty
              ? [
                  cats.keys.first,
                  '${(cats.values.first / (spent > 0 ? spent : 1) * 100).toInt()}',
                ]
              : [],
        ),
        ScoreFactor(
          labelKey: 'consistency',
          emoji: Assets.strike,
          score: (streakScore / 15 * 100).round().clamp(0, 100),
          detailKey: 'dayStreak',
          detailArgs: ['${budget.streakDays}'],
        ),
        ScoreFactor(
          labelKey: 'billLoad',
          emoji: Assets.balance,
          score: (billScore / 15 * 100).round().clamp(0, 100),
          detailKey: income > 0
              ? 'pctOfIncomeCommitted'
              : billsMonthly > 0
              ? 'inBills'
              : 'noActiveBills',
          detailArgs: income > 0
              ? ['${(billsMonthly / income * 100).toInt()}']
              : billsMonthly > 0
              ? [ExpenseService.fmt(billsMonthly)]
              : [],
        ),
        ScoreFactor(
          labelKey: 'goalProgress',
          emoji: Assets.goal,
          score: (goalScore / 10 * 100).round().clamp(0, 100),
          detailKey: activeGoals.isEmpty ? 'noActiveGoals' : 'goalsInProgress',
          detailArgs: activeGoals.isEmpty ? [] : ['${activeGoals.length}'],
        ),
      ],
    );
  }

  // ── 3. Burn Rate ───────────────────────────────────────────────────────────
  static BurnRate burnRate() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final spent = ExpenseService.expenseFor(month);
    final income = ExpenseService.incomeFor(month);
    final balance = ExpenseService.budget.monthlyLimit;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day.clamp(1, daysInMonth);
    final dailySpend = spent / daysPassed;
    return BurnRate(
      dailySpend: dailySpend,
      monthlySpend: dailySpend * daysInMonth,
      income: income,
      runwayDays: (dailySpend > 0 ? (balance / dailySpend).round() : 999).clamp(
        0,
        999,
      ),
    );
  }

  // ── 4. Prediction ──────────────────────────────────────────────────────────
  static ExpensePrediction predict() {
    final now = DateTime.now();
    final thisM = ExpenseService.forMonth(now);
    final lastM = ExpenseService.forMonth(DateTime(now.year, now.month - 1));
    final prev2M = ExpenseService.forMonth(DateTime(now.year, now.month - 2));
    final thisExp = ExpenseService.expenseFor(thisM);
    final lastExp = ExpenseService.expenseFor(lastM);
    final prev2Exp = ExpenseService.expenseFor(prev2M);
    final thisInc = ExpenseService.incomeFor(thisM);
    final lastInc = ExpenseService.incomeFor(lastM);
    final valid = [
      if (prev2Exp > 0) prev2Exp,
      if (lastExp > 0) lastExp,
      if (thisExp > 0) thisExp,
    ];
    var predictedExp = valid.isEmpty
        ? 0.0
        : valid.length == 1
        ? valid[0]
        : valid.length == 2
        ? (valid[0] * 0.4 + valid[1] * 0.6)
        : (prev2Exp * 0.2 + lastExp * 0.5 + thisExp * 0.3);
    final recurringBillsTotal = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    if (recurringBillsTotal > 0 && predictedExp < recurringBillsTotal) {
      predictedExp = max(predictedExp, recurringBillsTotal);
    }
    final predictedInc = lastInc > 0 ? lastInc : thisInc;
    final thisCats = ExpenseService.byCategory(
      thisM.where((e) => !e.isIncome).toList(),
    );
    final lastCats = ExpenseService.byCategory(
      lastM.where((e) => !e.isIncome).toList(),
    );
    final catPredictions = {...thisCats.keys, ...lastCats.keys}.map((cat) {
      final t = thisCats[cat] ?? 0.0;
      final l = lastCats[cat] ?? 0.0;
      final predicted = l > 0 && t > 0 ? (l * 0.5 + t * 0.5) : (l > 0 ? l : t);
      return CategoryPrediction(
        category: cat,
        emoji: _catEmoji(cat),
        predicted: predicted,
        lastMonth: l > 0 ? l : t,
      );
    }).toList()..sort((a, b) => b.predicted.compareTo(a.predicted));
    return ExpensePrediction(
      nextMonthExpense: predictedExp,
      nextMonthIncome: predictedInc,
      futureBalance: predictedInc - predictedExp,
      byCategory: catPredictions.take(6).toList(),
    );
  }

  // ── 5. Alerts ──────────────────────────────────────────────────────────────
  static List<SmartAlert> alerts() {
    final alerts = <SmartAlert>[];
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final spent = ExpenseService.expenseFor(month);
    final income = ExpenseService.incomeFor(month);
    final budget = ExpenseService.budget;
    final cats = ExpenseService.byCategory(
      month.where((e) => !e.isIncome).toList(),
    );
    final lastCats = ExpenseService.byCategory(
      ExpenseService.forMonth(
        DateTime(now.year, now.month - 1),
      ).where((e) => !e.isIncome).toList(),
    );

    if (budget.monthlyLimit > 0 && spent > budget.monthlyLimit * 0.9) {
      final pct = (spent / budget.monthlyLimit * 100).toInt();
      alerts.add(
        SmartAlert(
          type: 'overspend',
          emoji: '🚨',
          title: 'Budget ${pct >= 100 ? "Exceeded!" : "Warning: ${pct}%"}',
          body: pct >= 100
              ? 'Exceeded by ${ExpenseService.fmt(spent - budget.monthlyLimit)}'
              : '${ExpenseService.fmt(budget.monthlyLimit - spent)} remaining',
          severityColor: pct >= 100 ? 0xFFF43F5E : 0xFFF59E0B,
        ),
      );
    }
    if (income > 0 && spent > income * 0.85)
      alerts.add(
        SmartAlert(
          type: 'low_savings',
          emoji: '⚠️',
          title: 'Low Savings This Month',
          body:
              'Spending ${(spent / income * 100).toInt()}% of income. Target: save 20%.',
          severityColor: 0xFFF59E0B,
        ),
      );
    for (final e in cats.entries) {
      final last = lastCats[e.key] ?? 0;
      if (last > 0 && e.value > last * 1.5)
        alerts.add(
          SmartAlert(
            type: 'unusual',
            emoji: '📈',
            title: '${e.key} up ${((e.value - last) / last * 100).toInt()}%',
            body:
                '${ExpenseService.fmt(e.value)} vs ${ExpenseService.fmt(last)} last month.',
            severityColor: 0xFF6366F1,
          ),
        );
    }
    if (income > 0 && spent < income * 0.7)
      alerts.add(
        SmartAlert(
          type: 'positive',
          emoji: '🎉',
          title: 'Excellent Savings Rate!',
          body:
              'Saving ${((income - spent) / income * 100).toInt()}% of income.',
          severityColor: 0xFF10B981,
        ),
      );
    final overdueBills = _bills
        .where((b) => b.isActive && b.isOverdue)
        .toList();
    if (overdueBills.isNotEmpty) {
      final total = overdueBills.fold(0.0, (s, b) => s + b.amount);
      alerts.add(
        SmartAlert(
          type: 'overdue_bills',
          emoji: '🔴',
          title:
              '${overdueBills.length} Bill${overdueBills.length > 1 ? "s" : ""} Overdue!',
          body:
              '${overdueBills.map((b) => b.title).take(2).join(', ')}${overdueBills.length > 2 ? " & more" : ""} · Total: ${ExpenseService.fmt(total)}',
          severityColor: 0xFFF43F5E,
        ),
      );
    }
    final dueSoon = _bills.where((b) => b.isActive && b.isDueSoon).toList();
    if (dueSoon.isNotEmpty) {
      final total = dueSoon.fold(0.0, (s, b) => s + b.amount);
      alerts.add(
        SmartAlert(
          type: 'due_soon',
          emoji: '⏰',
          title:
              '${dueSoon.length} Bill${dueSoon.length > 1 ? "s" : ""} Due Soon',
          body:
              '${dueSoon.map((b) => b.title).take(2).join(', ')}${dueSoon.length > 2 ? " & more" : ""} · ${ExpenseService.fmt(total)} needed',
          severityColor: 0xFFF59E0B,
        ),
      );
    }
    final billsMonthly = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    if (income > 0 && billsMonthly / income > 0.5)
      alerts.add(
        SmartAlert(
          type: 'high_bills',
          emoji: '💸',
          title:
              'Bills Consuming ${(billsMonthly / income * 100).toInt()}% of Income',
          body:
              '${ExpenseService.fmt(billsMonthly)}/mo in committed bills. Review and cut where possible.',
          severityColor: 0xFFF43F5E,
        ),
      );
    for (final g in _goals) {
      if (g.daysLeft <= 0 || g.saved >= g.target) continue;
      final remaining = g.target - g.saved;
      final requiredPerDay = g.daysLeft > 0 ? remaining / g.daysLeft : 0.0;
      final available = income > 0
          ? (income - spent - billsMonthly).clamp(0.0, income) / 30
          : 0.0;
      if (requiredPerDay > available * 1.5 && available > 0)
        alerts.add(
          SmartAlert(
            type: 'goal_at_risk',
            emoji: '🎯',
            title: '${g.emoji} "${g.name}" Goal at Risk',
            body:
                'Needs ${ExpenseService.fmt(requiredPerDay)}/day but only ${ExpenseService.fmt(available)}/day available. ${g.daysLeft} days left.',
            severityColor: 0xFFf59e0b,
          ),
        );
    }
    alerts.sort((a, b) {
      int priority(int color) => color == 0xFFF43F5E
          ? 0
          : color == 0xFFF59E0B
          ? 1
          : 2;
      return priority(a.severityColor).compareTo(priority(b.severityColor));
    });
    return alerts.take(6).toList();
  }

  // ── 6. Auto category ───────────────────────────────────────────────────────
  static String autoCategory(String title) {
    final t = title.toLowerCase();
    if (_match(t, ['uber', 'bolt', 'taxi', 'bus', 'petrol', 'fuel', 'parking']))
      return 'Transport';
    if (_match(t, [
      'restaurant',
      'cafe',
      'coffee',
      'lunch',
      'dinner',
      'food',
      'snack',
    ]))
      return 'Food';
    if (_match(t, [
      'netflix',
      'spotify',
      'youtube',
      'prime',
      'hotstar',
      'disney',
    ]))
      return 'Entertainment';
    if (_match(t, [
      'gym',
      'doctor',
      'hospital',
      'pharmacy',
      'medicine',
      'health',
    ]))
      return 'Health';
    if (_match(t, [
      'electricity',
      'wifi',
      'internet',
      'water',
      'rent',
      'emi',
      'loan',
    ]))
      return 'Bills';
    if (_match(t, ['amazon', 'flipkart', 'shopping', 'mall', 'purchase']))
      return 'Shopping';
    if (_match(t, ['school', 'college', 'course', 'udemy', 'book', 'tuition']))
      return 'Education';
    if (_match(t, ['flight', 'hotel', 'airbnb', 'travel', 'trip']))
      return 'Travel';
    if (_match(t, ['salary', 'payroll', 'income', 'freelance']))
      return 'Salary';
    return 'Other';
  }

  static bool _match(String t, List<String> kw) => kw.any(t.contains);

  // ── 7. Subscriptions ───────────────────────────────────────────────────────
  static List<SubscriptionItem> detectSubscriptions() {
    const subKw = [
      'netflix',
      'spotify',
      'youtube',
      'prime',
      'hotstar',
      'gym',
      'insurance',
      'internet',
      'wifi',
      'electricity',
      'adobe',
    ];
    return detectRecurring()
        .where(
          (r) =>
              subKw.any(r.title.toLowerCase().contains) || r.occurrences >= 3,
        )
        .map(
          (r) => SubscriptionItem(
            name: r.title,
            emoji: _catEmoji(r.category),
            category: r.category,
            amount: r.avgAmount,
            frequency: 'monthly',
            color: Random(r.title.hashCode).nextInt(0xFFFFFF) + 0xFF000000,
          ),
        )
        .toList();
  }

  // ── 8. Income history ──────────────────────────────────────────────────────
  static Map<String, double> incomeHistory() {
    final now = DateTime.now();
    return {
      for (int i = 5; i >= 0; i--)
        DateFormat(
          'MMM yy',
        ).format(DateTime(now.year, now.month - i)): ExpenseService.incomeFor(
          ExpenseService.forMonth(DateTime(now.year, now.month - i)),
        ),
    };
  }

  static double incomeGrowthPercent() {
    final now = DateTime.now();
    final thisI = ExpenseService.incomeFor(ExpenseService.forMonth(now));
    final lastI = ExpenseService.incomeFor(
      ExpenseService.forMonth(DateTime(now.year, now.month - 1)),
    );
    return lastI <= 0 ? 0 : (thisI - lastI) / lastI * 100;
  }

  // ── 9. Suggestions ─────────────────────────────────────────────────────────
  static List<AiSuggestion> suggestions() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final lastM = ExpenseService.forMonth(DateTime(now.year, now.month - 1));
    final cats = ExpenseService.byCategory(
      month.where((e) => !e.isIncome).toList(),
    );
    final lastCats = ExpenseService.byCategory(
      lastM.where((e) => !e.isIncome).toList(),
    );
    final total = ExpenseService.expenseFor(month);
    final income = ExpenseService.incomeFor(month);
    final budget = ExpenseService.budget;
    final results = <AiSuggestion>[];
    for (final e in cats.entries.take(3)) {
      final last = lastCats[e.key] ?? 0;
      if (last > 0 && e.value > last * 1.2)
        results.add(
          AiSuggestion(
            emoji: '📈',
            title: '${e.key} up ${((e.value - last) / last * 100).toInt()}%',
            body:
                '${ExpenseService.fmt(e.value)} vs ${ExpenseService.fmt(last)} last month.',
            color: 0xFFF59E0B,
          ),
        );
      else if (last > 0 && e.value < last * 0.9)
        results.add(
          AiSuggestion(
            emoji: '📉',
            title: '${e.key} down ${((last - e.value) / last * 100).toInt()}%',
            body: 'Saved ${ExpenseService.fmt(last - e.value)} on ${e.key} 🎉',
            color: 0xFF10B981,
          ),
        );
    }
    if (cats.isNotEmpty && total > 0 && cats.values.first / total > 0.4) {
      final top = cats.entries.first;
      results.add(
        AiSuggestion(
          emoji: '⚠️',
          title:
              '${top.key} is ${(top.value / total * 100).toInt()}% of spending',
          body:
              'Try limiting ${top.key} to ${ExpenseService.fmt(top.value * 0.8)} next month.',
          color: 0xFFFF6B81,
        ),
      );
    }
    if (budget.monthlyLimit > 0 &&
        total < budget.monthlyLimit * 0.7 &&
        total > 0)
      results.add(
        AiSuggestion(
          emoji: '🎉',
          title: 'Great spending month!',
          body:
              '${(total / budget.monthlyLimit * 100).toInt()}% of budget used. Move ${ExpenseService.fmt(budget.monthlyLimit * 0.1)} to savings.',
          color: 0xFF34D399,
        ),
      );
    final billsMonthly = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    if (income > 0 && billsMonthly > income * 0.4)
      results.add(
        AiSuggestion(
          emoji: '💡',
          title: 'Bills at ${(billsMonthly / income * 100).toInt()}% of income',
          body:
              'Monthly bills total ${ExpenseService.fmt(billsMonthly)}. Consider renegotiating subscriptions or utilities.',
          color: 0xFFF59E0B,
        ),
      );
    final surplus = income > 0
        ? (income - total - billsMonthly).clamp(0.0, income)
        : 0.0;
    for (final g in _goals.take(2)) {
      if (g.saved >= g.target || g.daysLeft <= 0) continue;
      final remaining = g.target - g.saved;
      final requiredPerMonth = g.daysLeft > 0
          ? (remaining / g.daysLeft * 30)
          : remaining;
      if (surplus > 0 && requiredPerMonth <= surplus)
        results.add(
          AiSuggestion(
            emoji: g.emoji,
            title: '"${g.name}" on track!',
            body:
                'Save ${ExpenseService.fmt(requiredPerMonth)}/mo to hit your goal in ${g.daysLeft} days.',
            color: 0xFF10B981,
          ),
        );
      else if (surplus > 0 && requiredPerMonth > surplus)
        results.add(
          AiSuggestion(
            emoji: g.emoji,
            title:
                '"${g.name}" needs ${ExpenseService.fmt(requiredPerMonth - surplus)} more/mo',
            body:
                'Current surplus is ${ExpenseService.fmt(surplus)}/mo. Reduce spending to stay on track.',
            color: 0xFFF59E0B,
          ),
        );
    }
    return results.take(6).toList();
  }

  // ── 10. Coach tips ─────────────────────────────────────────────────────────
  static List<CoachTip> coachTips() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final cats = ExpenseService.byCategory(
      month.where((e) => !e.isIncome).toList(),
    );
    final budget = ExpenseService.budget;
    final tips = <CoachTip>[];
    if (cats.isNotEmpty && spent > 0 && cats.values.first / spent > 0.35) {
      final cat = cats.entries.first;
      tips.add(
        CoachTip(
          emoji: '✂️',
          title: 'Cut ${cat.key} by 10%',
          action:
              'Set a ${ExpenseService.fmt(cat.value * 0.9)} limit for ${cat.key}',
          impact: 'Save ${ExpenseService.fmt(cat.value * 0.1)} per month',
          impactColor: 0xFF10B981,
        ),
      );
    }
    if (income > 0 && ((income - spent) / income * 100).clamp(0, 100) < 20)
      tips.add(
        CoachTip(
          emoji: '💰',
          title: 'Boost savings to 20%',
          action:
              'Reduce discretionary spend by ${ExpenseService.fmt((income * 0.2 - (income - spent)).clamp(0, income))}',
          impact: 'Reach ${ExpenseService.fmt(income * 0.2)} savings/month',
          impactColor: 0xFF6366F1,
        ),
      );
    if (budget.monthlyLimit <= 0 || budget.monthlyLimit == 10000)
      tips.add(
        CoachTip(
          emoji: '🎯',
          title: 'Set a realistic budget',
          action: 'Go to Settings → Budget and set your monthly limit',
          impact: 'Track progress and get alerts when overspending',
          impactColor: 0xFFF59E0B,
        ),
      );
    final billsMonthly = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    if (income > 0 && billsMonthly / income > 0.35)
      tips.add(
        CoachTip(
          emoji: '📋',
          title: 'Review your bill commitments',
          action:
              'Bills are ${(billsMonthly / income * 100).toInt()}% of income. Aim for under 35%.',
          impact:
              'Freeing ${ExpenseService.fmt(billsMonthly * 0.1)} could go to goals or savings',
          impactColor: 0xFF6366F1,
        ),
      );
    final overdueBills = _bills
        .where((b) => b.isActive && b.isOverdue)
        .toList();
    if (overdueBills.isNotEmpty)
      tips.add(
        CoachTip(
          emoji: '🔴',
          title: 'Pay overdue bills immediately',
          action:
              'Clear ${overdueBills.map((b) => b.title).take(2).join(', ')} to avoid penalties',
          impact: 'Avoids late fees and protects credit score',
          impactColor: 0xFFF43F5E,
        ),
      );
    final activeGoals = _goals
        .where((g) => g.daysLeft > 0 && g.saved < g.target)
        .toList();
    if (activeGoals.isEmpty)
      tips.add(
        CoachTip(
          emoji: '🎯',
          title: 'Create your first savings goal',
          action: 'Go to Goals tab and set a target (e.g. Emergency Fund)',
          impact: 'Goals increase savings rate by an average of 23%',
          impactColor: 0xFF10B981,
        ),
      );
    else {
      final nearestGoal = activeGoals.reduce(
        (a, b) =>
            (a.target > 0 ? a.saved / a.target : 0) >
                (b.target > 0 ? b.saved / b.target : 0)
            ? a
            : b,
      );
      final pct = nearestGoal.target > 0
          ? (nearestGoal.saved / nearestGoal.target * 100).toInt()
          : 0;
      if (pct >= 70)
        tips.add(
          CoachTip(
            emoji: nearestGoal.emoji,
            title: '"${nearestGoal.name}" is $pct% complete!',
            action:
                'Top up ${ExpenseService.fmt(nearestGoal.target - nearestGoal.saved)} to complete it',
            impact: 'Only ${nearestGoal.daysLeft} days left — finish strong!',
            impactColor: 0xFF10B981,
          ),
        );
    }
    final subs = detectSubscriptions();
    if (subs.isNotEmpty) {
      final subTotal = subs.fold(0.0, (s, sub) => s + sub.monthlyEquivalent);
      tips.add(
        CoachTip(
          emoji: '📱',
          title: 'Review ${subs.length} subscriptions',
          action:
              'Check if all ${subs.length} recurring payments are necessary',
          impact: 'Potential savings: ${ExpenseService.fmt(subTotal * 0.5)}/mo',
          impactColor: 0xFFF59E0B,
        ),
      );
    }
    final br = burnRate();
    if (br.runwayDays < 90)
      tips.add(
        CoachTip(
          emoji: '🛡️',
          title: 'Build 3-month emergency fund',
          action:
              'Save ${ExpenseService.fmt(br.monthlySpend)} per month for 3 months',
          impact: 'Target: ${ExpenseService.fmt(br.monthlySpend * 3)} buffer',
          impactColor: 0xFF6366F1,
        ),
      );
    return tips.take(5).toList();
  }

  // ── 11. Recurring detection ────────────────────────────────────────────────
  static List<RecurringExpense> detectRecurring() {
    final all = ExpenseService.all;
    if (all.length < 3) return [];
    final groups = <String, List<Expense>>{};
    for (final e in all.where((e) => !e.isIncome))
      groups.update(
        e.title.toLowerCase().trim(),
        (l) => [...l, e],
        ifAbsent: () => [e],
      );
    final results = <RecurringExpense>[];
    groups.forEach((_, list) {
      if (list.length < 2) return;
      list.sort((a, b) => a.date.compareTo(b.date));
      final avg = list.fold(0.0, (s, e) => s + e.amount) / list.length;
      if (!list.every((e) => avg == 0 || (e.amount - avg).abs() / avg < 0.25))
        return;
      final days = list.last.date.difference(list.first.date).inDays;
      final interval = list.length > 1
          ? (days / (list.length - 1)).round()
          : 30;
      results.add(
        RecurringExpense(
          title: list.first.title,
          category: list.first.category,
          avgAmount: avg,
          occurrences: list.length,
          nextEstimate: list.last.date.add(Duration(days: interval)),
          emoji: _catEmoji(list.first.category),
        ),
      );
    });
    return results.take(5).toList();
  }

  // ── 12. Bill Health Summary ────────────────────────────────────────────────
  static BillHealthSummary billHealthSummary() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final activeBills = _bills.where((b) => b.isActive).toList();
    final recurringBills = activeBills.where((b) => b.isRecurring).toList();
    final total = recurringBills.fold(0.0, (s, b) => s + b.amount);
    final ratio = income > 0 ? total / income : 0.0;
    final overdue = activeBills.where((b) => b.isOverdue).toList();
    final dueSoon = activeBills.where((b) => b.isDueSoon).toList();
    final largest = [...recurringBills]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return BillHealthSummary(
      totalMonthlyCommitment: total,
      incomeCommitmentRatio: ratio,
      overdueList: overdue,
      dueSoonList: dueSoon,
      largestBills: largest.take(3).toList(),
    );
  }

  // ── 13. Goal Insights ──────────────────────────────────────────────────────
  static List<GoalInsight> goalInsights() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final billsMonthly = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    final availableMonthly = (income - spent - billsMonthly).clamp(0.0, income);
    final availableDaily = availableMonthly / 30;
    return _goals.map((g) {
      final progress = g.target > 0
          ? (g.saved / g.target).clamp(0.0, 1.0)
          : 0.0;
      final remaining = g.target - g.saved;
      final requiredDaily = g.daysLeft > 0 ? remaining / g.daysLeft : 0.0;
      final onTrack = availableDaily >= requiredDaily;
      String statusMessage;
      if (g.saved >= g.target) {
        statusMessage = '🎉 Goal completed!';
      } else if (g.daysLeft <= 0) {
        statusMessage = '⌛ Deadline passed — reset or extend your goal';
      } else if (onTrack) {
        statusMessage =
            '✅ On track — save ${ExpenseService.fmt(requiredDaily)}/day';
      } else {
        final shortfall = requiredDaily - availableDaily;
        statusMessage =
            '⚠️ Behind — need ${ExpenseService.fmt(shortfall)}/day more';
      }
      return GoalInsight(
        id: g.id,
        name: g.name,
        emoji: g.emoji,
        target: g.target,
        saved: g.saved,
        progress: progress,
        daysLeft: g.daysLeft,
        requiredDailyAmount: requiredDaily,
        availableDailyAmount: availableDaily,
        onTrack: onTrack,
        statusMessage: statusMessage,
      );
    }).toList();
  }

  // ── 14. Cash Flow Forecast ─────────────────────────────────────────────────
  static CashFlowForecast cashFlowForecast() {
    final pred = predict();
    final warnings = <String>[];
    final upcomingBills = _bills
        .where((b) => b.isActive && b.isRecurring)
        .fold(0.0, (s, b) => s + b.amount);
    final goalsNeeded = _goals
        .where((g) => g.daysLeft > 0 && g.saved < g.target)
        .fold(0.0, (s, g) {
          final remaining = g.target - g.saved;
          return s + (g.daysLeft > 0 ? (remaining / g.daysLeft * 30) : 0);
        });
    final projected = pred.nextMonthIncome;
    final projectedExp = pred.nextMonthExpense;
    final surplus = projected - projectedExp - goalsNeeded;
    if (upcomingBills > projected * 0.5)
      warnings.add(
        'Bills will consume ${(upcomingBills / projected * 100).toInt()}% of projected income',
      );
    if (goalsNeeded > 0 && surplus < 0)
      warnings.add(
        'Goals require ${ExpenseService.fmt(goalsNeeded)}/mo but surplus is ${ExpenseService.fmt(surplus.abs())} short',
      );
    if (pred.futureBalance < 0)
      warnings.add(
        'Projected to overspend by ${ExpenseService.fmt(pred.futureBalance.abs())} next month',
      );
    final overdueBills = _bills.where((b) => b.isActive && b.isOverdue);
    if (overdueBills.isNotEmpty)
      warnings.add(
        '${overdueBills.length} overdue bill${overdueBills.length > 1 ? "s" : ""} need immediate attention',
      );
    return CashFlowForecast(
      projectedIncome: projected,
      projectedExpenses: projectedExp,
      upcomingBillsTotal: upcomingBills,
      goalsRequiredThisMonth: goalsNeeded,
      projectedSurplus: surplus,
      warnings: warnings,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _catEmoji(String cat) =>
      const {
        'Food': '🍜',
        'Transport': '🚗',
        'Shopping': '🛍',
        'Health': '💊',
        'Bills': '⚡',
        'Entertainment': '🎬',
        'Education': '📚',
        'Travel': '✈️',
        'Groceries': '🛒',
        'Other': '📦',
        'Salary': '💼',
        'Freelance': '💻',
        'Business': '🏢',
        'Investment': '📈',
        'Gift': '🎁',
      }[cat] ??
      '📦';
}
