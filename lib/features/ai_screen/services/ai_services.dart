import 'dart:math';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/services/expenses_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// ── Data models ───────────────────────────────────────────────────

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
  final String label, emoji, detail;
  final int score;
  const ScoreFactor({
    required this.label,
    required this.emoji,
    required this.score,
    required this.detail,
  });
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

// ── Colors ────────────────────────────────────────────────────────
Color get kAiGreen => const Color(0xFF10B981);
Color get kAiAmber => const Color(0xFFF59E0B);
Color get kAiRed => const Color(0xFFF43F5E);
Color get kAiPurple => const Color(0xFF6366F1);

// ── AI Service ────────────────────────────────────────────────────
class AiService {
  // 1. Smart Budget
  static SmartBudget smartBudget() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final effectiveIncome = income > 0
        ? income
        : ExpenseService.budget.monthlyLimit;
    return SmartBudget(
      income: effectiveIncome,
      needsBudget: effectiveIncome * 0.50,
      wantsBudget: effectiveIncome * 0.30,
      savingsGoal: effectiveIncome * 0.20,
      currentSpend: spent,
    );
  }

  // 2. Health Score
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
        ? (1 - (spent / budget.monthlyLimit)).clamp(0.0, 1.0) * 25
        : 12.0;
    double controlScore = 25;
    if (cats.isNotEmpty && spent > 0) {
      final topPct = cats.values.first / spent;
      controlScore = topPct > 0.6
          ? 5
          : topPct > 0.4
          ? 15
          : 25;
    }
    final streakScore = (budget.streakDays / 30 * 25).clamp(0.0, 25.0);
    final total = (savingsScore + budgetScore + controlScore + streakScore)
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
          label: 'Savings Rate',
          emoji: Assets.saving,
          score: savingsScore.round().clamp(0, 25) * 4,
          detail: income > 0
              ? '${((income - spent) / income * 100).clamp(0, 100).toInt()}% saved'
              : 'No income logged',
        ),
        ScoreFactor(
          label: 'Budget Control',
          emoji: Assets.goal,
          score: budgetScore.round().clamp(0, 25) * 4,
          detail: budget.monthlyLimit > 0
              ? '${(spent / budget.monthlyLimit * 100).toInt()}% of limit used'
              : 'No budget set',
        ),
        ScoreFactor(
          label: 'Expense Balance',
          emoji: Assets.balance,
          score: controlScore.round().clamp(0, 25) * 4,
          detail: cats.isNotEmpty
              ? 'Top: ${cats.keys.first} ${(cats.values.first / (spent > 0 ? spent : 1) * 100).toInt()}%'
              : 'No expenses yet',
        ),
        ScoreFactor(
          label: 'Consistency',
          emoji: Assets.strike,
          score: streakScore.round().clamp(0, 25) * 4,
          detail: '${budget.streakDays} day streak',
        ),
      ],
    );
  }

  // 3. Burn Rate
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

  // 4. Prediction
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
    final predictedExp = valid.isEmpty
        ? 0.0
        : valid.length == 1
        ? valid[0]
        : valid.length == 2
        ? (valid[0] * 0.4 + valid[1] * 0.6)
        : (prev2Exp * 0.2 + lastExp * 0.5 + thisExp * 0.3);
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

  // 5. Alerts
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

    return alerts.take(4).toList();
  }

  // 6. Auto category
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

  // 7. Subscriptions
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

  // 8. Income history
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

  // 9. Suggestions
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
    final budget = ExpenseService.budget;
    final results = <AiSuggestion>[];
    if (cats.isEmpty) return results;

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
              '${(total / budget.monthlyLimit * 100).toInt()}% of budget used. '
              'Move ${ExpenseService.fmt(budget.monthlyLimit * 0.1)} to savings.',
          color: 0xFF34D399,
        ),
      );

    return results.take(5).toList();
  }

  // 10. Coach tips
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
              'Reduce discretionary spend by '
              '${ExpenseService.fmt((income * 0.2 - (income - spent)).clamp(0, income))}',
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

    final subs = detectSubscriptions();
    if (subs.isNotEmpty) {
      final total = subs.fold(0.0, (s, sub) => s + sub.monthlyEquivalent);
      tips.add(
        CoachTip(
          emoji: '📱',
          title: 'Review ${subs.length} subscriptions',
          action:
              'Check if all ${subs.length} recurring payments are necessary',
          impact: 'Potential savings: ${ExpenseService.fmt(total * 0.5)}/mo',
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

    return tips.take(4).toList();
  }

  // 11. Recurring detection
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
