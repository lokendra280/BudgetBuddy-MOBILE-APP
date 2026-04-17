import 'dart:math';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
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
  final int score; // 0–100
  final String grade; // A+ / A / B / C / D
  final String headline;
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
  final String label, emoji;
  final int score; // 0–100
  final String detail;
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

class SavingsGoal {
  final String id, name, emoji;
  final double target, saved, dailySuggestion;
  final int daysLeft;
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.dailySuggestion,
    required this.daysLeft,
  });
  double get progress => target > 0 ? (saved / target).clamp(0, 1) : 0;
}

class SmartAlert {
  final String type, emoji, title, body;
  final int severityColor; // hex
  const SmartAlert({
    required this.type,
    required this.emoji,
    required this.title,
    required this.body,
    required this.severityColor,
  });
}

class SubscriptionItem {
  final String name, emoji, category;
  final double amount;
  final String frequency; // monthly / yearly
  const SubscriptionItem({
    required this.name,
    required this.emoji,
    required this.category,
    required this.amount,
    required this.frequency,
  });
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

// ─────────────────────────────────────────────────────────────────────────────
// GOALS BOX  (persisted in Hive — typeId 2)
// ─────────────────────────────────────────────────────────────────────────────
@HiveType(typeId: 2)
class GoalEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String emoji;
  @HiveField(3)
  double target;
  @HiveField(4)
  double saved;
  @HiveField(5)
  int daysLeft;
  GoalEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.daysLeft,
  });
}

class GoalEntryAdapter extends TypeAdapter<GoalEntry> {
  @override
  final int typeId = 2;
  @override
  GoalEntry read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) r.readByte(): r.read(),
    };
    return GoalEntry(
      id: f[0] as String? ?? '',
      name: f[1] as String? ?? '',
      emoji: f[2] as String? ?? '🎯',
      target: (f[3] as num?)?.toDouble() ?? 0,
      saved: (f[4] as num?)?.toDouble() ?? 0,
      daysLeft: f[5] as int? ?? 30,
    );
  }

  @override
  void write(BinaryWriter w, GoalEntry o) {
    w
      ..writeByte(6)
      ..writeByte(0)
      ..write(o.id)
      ..writeByte(1)
      ..write(o.name)
      ..writeByte(2)
      ..write(o.emoji)
      ..writeByte(3)
      ..write(o.target)
      ..writeByte(4)
      ..write(o.saved)
      ..writeByte(5)
      ..write(o.daysLeft);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object o) => o is GoalEntryAdapter && typeId == o.typeId;
}

// ignore: non_constant_identifier_names
Color get kAiGreen => const Color(0xFF10B981);
// ignore: non_constant_identifier_names
Color get kAiAmber => const Color(0xFFF59E0B);
// ignore: non_constant_identifier_names
Color get kAiRed => const Color(0xFFF43F5E);
// ignore: non_constant_identifier_names
Color get kAiPurple => const Color(0xFF6366F1);

// ─────────────────────────────────────────────────────────────────────────────
// AI SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class AiService {
  // ── 1. SMART BUDGETING (50/30/20 rule adjusted by income) ───────────────
  static SmartBudget smartBudget() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);

    // If no income logged, estimate from budget limit
    final effectiveIncome = income > 0
        ? income
        : ExpenseService.budget.monthlyLimit;

    return SmartBudget(
      income: effectiveIncome,
      needsBudget: effectiveIncome * 0.50, // 50% needs (rent, food, bills)
      wantsBudget:
          effectiveIncome * 0.30, // 30% wants (entertainment, shopping)
      savingsGoal: effectiveIncome * 0.20, // 20% savings
      currentSpend: spent,
    );
  }

  // ── 2. FINANCIAL HEALTH SCORE (0-100) ────────────────────────────────────
  static FinancialHealthScore healthScore() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final income = ExpenseService.incomeFor(month);
    final spent = ExpenseService.expenseFor(month);
    final budget = ExpenseService.budget;
    final all = ExpenseService.all;

    // Factor 1: Savings rate (income - spend) / income  → 0-25pts
    double savingsScore = 0;
    if (income > 0) {
      final savingsRate = ((income - spent) / income).clamp(0.0, 1.0);
      savingsScore = savingsRate * 25;
    }

    // Factor 2: Budget adherence (spent vs limit) → 0-25pts
    double budgetScore = 0;
    if (budget.monthlyLimit > 0) {
      final adherence = (1 - (spent / budget.monthlyLimit)).clamp(0.0, 1.0);
      budgetScore = adherence * 25;
    } else {
      budgetScore = 12; // neutral
    }

    // Factor 3: Expense control (no category > 40% of total) → 0-25pts
    final cats = ExpenseService.byCategory(
      month.where((e) => !e.isIncome).toList(),
    );
    double controlScore = 25;
    if (cats.isNotEmpty && spent > 0) {
      final topPct = cats.values.first / spent;
      controlScore = topPct > 0.6
          ? 5
          : topPct > 0.4
          ? 15
          : 25;
    }

    // Factor 4: Streak / consistency → 0-25pts
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
        ? 'Needs attention ⚠️'
        : 'Take action now 🚨';

    return FinancialHealthScore(
      score: total,
      grade: grade,
      headline: headline,
      factors: [
        ScoreFactor(
          label: 'Savings Rate',
          emoji: '💰',
          score: savingsScore.round().clamp(0, 25) * 4,
          detail: income > 0
              ? '${((income - spent) / income * 100).clamp(0, 100).toInt()}% saved'
              : 'No income logged',
        ),
        ScoreFactor(
          label: 'Budget Control',
          emoji: '🎯',
          score: budgetScore.round().clamp(0, 25) * 4,
          detail: budget.monthlyLimit > 0
              ? '${(spent / budget.monthlyLimit * 100).toInt()}% of limit used'
              : 'No budget set',
        ),
        ScoreFactor(
          label: 'Expense Balance',
          emoji: '⚖️',
          score: controlScore.round().clamp(0, 25) * 4,
          detail: cats.isNotEmpty
              ? 'Top: ${cats.keys.first} ${(cats.values.first / (spent > 0 ? spent : 1) * 100).toInt()}%'
              : 'No expenses yet',
        ),
        ScoreFactor(
          label: 'Consistency',
          emoji: '🔥',
          score: streakScore.round().clamp(0, 25) * 4,
          detail: '${budget.streakDays} day streak',
        ),
      ],
    );
  }

  // ── 3. BURN RATE & RUNWAY ─────────────────────────────────────────────────
  static BurnRate burnRate() {
    final now = DateTime.now();
    final month = ExpenseService.forMonth(now);
    final spent = ExpenseService.expenseFor(month);
    final income = ExpenseService.incomeFor(month);
    final balance =
        ExpenseService.budget.monthlyLimit; // use budget as proxy for balance

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day.clamp(1, daysInMonth);
    final dailySpend = spent / daysPassed;
    final projectedMonthly = dailySpend * daysInMonth;

    // Runway = current balance / daily spend
    final runway = dailySpend > 0 ? (balance / dailySpend).round() : 999;

    return BurnRate(
      dailySpend: dailySpend,
      monthlySpend: projectedMonthly,
      income: income,
      runwayDays: runway.clamp(0, 999),
    );
  }

  // ── 4. EXPENSE PREDICTION (next month estimate) ───────────────────────────
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

    // Weighted average: 50% last month, 30% this month, 20% 2 months ago
    final validMonths = [
      if (prev2Exp > 0) prev2Exp,
      if (lastExp > 0) lastExp,
      if (thisExp > 0) thisExp,
    ];
    final predictedExp = validMonths.isEmpty
        ? 0.0
        : validMonths.length == 1
        ? validMonths[0]
        : validMonths.length == 2
        ? (validMonths[0] * 0.4 + validMonths[1] * 0.6)
        : (prev2Exp * 0.2 + lastExp * 0.5 + thisExp * 0.3);

    final predictedInc = lastInc > 0 ? lastInc : (thisInc > 0 ? thisInc : 0.0);
    final futureBalance = predictedInc - predictedExp;

    // Per-category prediction
    final thisCats = ExpenseService.byCategory(
      thisM.where((e) => !e.isIncome).toList(),
    );
    final lastCats = ExpenseService.byCategory(
      lastM.where((e) => !e.isIncome).toList(),
    );
    final allCats = {...thisCats.keys, ...lastCats.keys};

    final catPredictions = allCats.map((cat) {
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
      futureBalance: futureBalance,
      byCategory: catPredictions.take(6).toList(),
    );
  }

  // ── 5. SAVINGS GOALS (from Hive box) ─────────────────────────────────────
  static List<SavingsGoal> goals() {
    if (!Hive.isBoxOpen('goals')) return [];
    final box = Hive.box<GoalEntry>('goals');
    final b = smartBudget();
    final dailySavingsAvailable = b.income > 0
        ? (b.income - b.currentSpend).clamp(0, b.income) / 30
        : 0.0;

    return box.values.map((g) {
      final remaining = (g.target - g.saved).clamp(0, g.target);
      final dailySuggest = g.daysLeft > 0 ? remaining / g.daysLeft : 0.0;
      return SavingsGoal(
        id: g.id,
        name: g.name,
        emoji: g.emoji,
        target: g.target,
        saved: g.saved,
        dailySuggestion: dailySuggest,
        daysLeft: g.daysLeft,
      );
    }).toList();
  }

  static Future<void> addGoal(
    String name,
    String emoji,
    double target,
    int daysLeft,
  ) async {
    final box = Hive.box<GoalEntry>('goals');
    await box.add(
      GoalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        emoji: emoji,
        target: target,
        saved: 0,
        daysLeft: daysLeft,
      ),
    );
  }

  static Future<void> addToGoal(String id, double amount) async {
    final box = Hive.box<GoalEntry>('goals');
    for (final g in box.values) {
      if (g.id == id) {
        g.saved = (g.saved + amount).clamp(0, g.target);
        await g.save();
        break;
      }
    }
  }

  static Future<void> deleteGoal(String id) async {
    final box = Hive.box<GoalEntry>('goals');
    final idx = box.values.toList().indexWhere((g) => g.id == id);
    if (idx >= 0) await box.deleteAt(idx);
  }

  // ── 6. SMART ALERTS ──────────────────────────────────────────────────────
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
    final all = ExpenseService.all;

    // Over budget alert
    if (budget.monthlyLimit > 0 && spent > budget.monthlyLimit * 0.9) {
      final pct = (spent / budget.monthlyLimit * 100).toInt();
      alerts.add(
        SmartAlert(
          type: 'overspend',
          emoji: '🚨',
          title: 'Budget ${pct >= 100 ? "Exceeded!" : "Warning: ${pct}%"}',
          body: pct >= 100
              ? 'You\'ve exceeded your limit by ${ExpenseService.fmt(spent - budget.monthlyLimit)}'
              : 'Only ${ExpenseService.fmt(budget.monthlyLimit - spent)} remaining this month',
          severityColor: pct >= 100 ? 0xFFF43F5E : 0xFFF59E0B,
        ),
      );
    }

    // Low savings alert
    if (income > 0 && spent > income * 0.85) {
      alerts.add(
        SmartAlert(
          type: 'low_savings',
          emoji: '⚠️',
          title: 'Low Savings This Month',
          body:
              'Spending ${(spent / income * 100).toInt()}% of income. Target: save at least 20%.',
          severityColor: 0xFFF59E0B,
        ),
      );
    }

    // Unusual spending spike in a category
    final lastCats = ExpenseService.byCategory(
      ExpenseService.forMonth(
        DateTime(now.year, now.month - 1),
      ).where((e) => !e.isIncome).toList(),
    );
    for (final entry in cats.entries) {
      final lastAmt = lastCats[entry.key] ?? 0;
      if (lastAmt > 0 && entry.value > lastAmt * 1.5) {
        alerts.add(
          SmartAlert(
            type: 'unusual',
            emoji: '📈',
            title:
                '${entry.key} up ${((entry.value - lastAmt) / lastAmt * 100).toInt()}%',
            body:
                '${ExpenseService.fmt(entry.value)} vs ${ExpenseService.fmt(lastAmt)} last month.',
            severityColor: 0xFF6366F1,
          ),
        );
      }
    }

    // Positive alert — saved money
    if (income > 0 && spent < income * 0.7) {
      alerts.add(
        SmartAlert(
          type: 'positive',
          emoji: '🎉',
          title: 'Excellent Savings Rate!',
          body:
              'Saving ${((income - spent) / income * 100).toInt()}% of income this month.',
          severityColor: 0xFF10B981,
        ),
      );
    }

    return alerts.take(4).toList();
  }

  // ── 7. AUTO CATEGORIZATION hint ───────────────────────────────────────────
  static String autoCategory(String title) {
    final t = title.toLowerCase();
    if (_match(t, [
      'uber',
      'bolt',
      'rapido',
      'taxi',
      'bus',
      'metro',
      'petrol',
      'fuel',
      'diesel',
      'parking',
    ]))
      return 'Transport';
    if (_match(t, [
      'mcdonald',
      'kfc',
      'pizza',
      'burger',
      'sushi',
      'cafe',
      'coffee',
      'restaurant',
      'dining',
      'lunch',
      'dinner',
      'breakfast',
      'food',
      'snack',
      'boba',
      'tea',
    ]))
      return 'Food';
    if (_match(t, [
      'netflix',
      'spotify',
      'youtube',
      'amazon prime',
      'hotstar',
      'disney',
      'subscription',
      'prime',
    ]))
      return 'Entertainment';
    if (_match(t, [
      'gym',
      'doctor',
      'hospital',
      'pharmacy',
      'medicine',
      'clinic',
      'health',
      'wellness',
    ]))
      return 'Health';
    if (_match(t, [
      'electricity',
      'wifi',
      'internet',
      'water',
      'gas',
      'rent',
      'emi',
      'loan',
      'insurance',
    ]))
      return 'Bills';
    if (_match(t, [
      'amazon',
      'flipkart',
      'myntra',
      'zara',
      'h&m',
      'shopping',
      'mall',
      'purchase',
      'buy',
    ]))
      return 'Shopping';
    if (_match(t, [
      'school',
      'college',
      'course',
      'udemy',
      'book',
      'tuition',
      'study',
    ]))
      return 'Education';
    if (_match(t, [
      'flight',
      'hotel',
      'airbnb',
      'travel',
      'holiday',
      'trip',
      'booking',
    ]))
      return 'Travel';
    if (_match(t, [
      'salary',
      'payroll',
      'income',
      'freelance',
      'payment received',
      'transfer',
    ]))
      return 'Salary';
    return 'Other';
  }

  static bool _match(String t, List<String> keywords) =>
      keywords.any((k) => t.contains(k));

  // ── 8. SUBSCRIPTION TRACKER ──────────────────────────────────────────────
  static List<SubscriptionItem> detectSubscriptions() {
    final recurring = detectRecurring();
    final subs = <SubscriptionItem>[];
    final subKeywords = [
      'netflix',
      'spotify',
      'youtube',
      'prime',
      'hotstar',
      'disney',
      'hulu',
      'gym',
      'insurance',
      'internet',
      'wifi',
      'electricity',
      'cloud',
      'storage',
      'office',
      'adobe',
    ];

    for (final r in recurring) {
      final t = r.title.toLowerCase();
      if (subKeywords.any((k) => t.contains(k)) || r.occurrences >= 3) {
        subs.add(
          SubscriptionItem(
            name: r.title,
            emoji: _catEmoji(r.category),
            category: r.category,
            amount: r.avgAmount,
            frequency: r.occurrences >= 12 ? 'monthly' : 'monthly',
          ),
        );
      }
    }
    return subs;
  }

  // ── 9. INCOME GROWTH TRACKER ─────────────────────────────────────────────
  static Map<String, double> incomeHistory() {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final inc = ExpenseService.incomeFor(ExpenseService.forMonth(m));
      final key = DateFormat('MMM yy').format(m);
      result[key] = inc;
    }
    return result;
  }

  static double incomeGrowthPercent() {
    final now = DateTime.now();
    final thisI = ExpenseService.incomeFor(ExpenseService.forMonth(now));
    final lastI = ExpenseService.incomeFor(
      ExpenseService.forMonth(DateTime(now.year, now.month - 1)),
    );
    if (lastI <= 0) return 0;
    return ((thisI - lastI) / lastI * 100);
  }

  // ── 10. AI SPENDING INSIGHTS (pattern-based) ─────────────────────────────
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

    // Category spike detection
    for (final entry in cats.entries.take(3)) {
      final last = lastCats[entry.key] ?? 0;
      if (last > 0 && entry.value > last * 1.2) {
        results.add(
          AiSuggestion(
            emoji: '📈',
            title:
                '${entry.key} up ${((entry.value - last) / last * 100).toInt()}%',
            body:
                '${ExpenseService.fmt(entry.value)} this month vs ${ExpenseService.fmt(last)} last month.',
            color: 0xFFF59E0B,
          ),
        );
      } else if (last > 0 && entry.value < last * 0.9) {
        results.add(
          AiSuggestion(
            emoji: '📉',
            title:
                '${entry.key} down ${((last - entry.value) / last * 100).toInt()}%',
            body:
                'Saved ${ExpenseService.fmt(last - entry.value)} on ${entry.key} vs last month. 🎉',
            color: 0xFF10B981,
          ),
        );
      }
    }

    // Top category warning
    if (cats.isNotEmpty && total > 0 && cats.values.first / total > 0.4) {
      final top = cats.entries.first;
      results.add(
        AiSuggestion(
          emoji: '⚠️',
          title:
              '${top.key} is ${(top.value / total * 100).toInt()}% of spending',
          body:
              'Try setting a limit of ${ExpenseService.fmt(top.value * 0.8)} for ${top.key} next month.',
          color: 0xFFFF6B81,
        ),
      );
    }

    // Good month
    if (budget.monthlyLimit > 0 &&
        total < budget.monthlyLimit * 0.7 &&
        total > 0) {
      results.add(
        AiSuggestion(
          emoji: '🎉',
          title: 'Great spending month!',
          body:
              'Only ${(total / budget.monthlyLimit * 100).toInt()}% of budget used. Consider moving ${ExpenseService.fmt(budget.monthlyLimit * 0.1)} to savings.',
          color: 0xFF34D399,
        ),
      );
    }

    return results.take(5).toList();
  }

  // ── 11. FINANCIAL COACH TIPS ─────────────────────────────────────────────
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

    // Tip: Reduce top category
    if (cats.isNotEmpty && spent > 0 && cats.values.first / spent > 0.35) {
      final cat = cats.entries.first;
      final saving = cat.value * 0.1;
      tips.add(
        CoachTip(
          emoji: '✂️',
          title: 'Cut ${cat.key} by 10%',
          action:
              'Set a ${ExpenseService.fmt(cat.value * 0.9)} limit for ${cat.key}',
          impact: 'Save ${ExpenseService.fmt(saving)} per month',
          impactColor: 0xFF10B981,
        ),
      );
    }

    // Tip: Increase savings rate
    if (income > 0) {
      final savingsRate = ((income - spent) / income * 100).clamp(0, 100);
      if (savingsRate < 20) {
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
      }
    }

    // Tip: Set a budget
    if (budget.monthlyLimit <= 0 || budget.monthlyLimit == 10000) {
      tips.add(
        CoachTip(
          emoji: '🎯',
          title: 'Set a realistic budget',
          action: 'Go to Settings → Budget and set your monthly limit',
          impact: 'Track progress and get alerts when overspending',
          impactColor: 0xFFF59E0B,
        ),
      );
    }

    // Tip: Check subscriptions
    final subs = detectSubscriptions();
    if (subs.isNotEmpty) {
      final subsTotal = subs.fold(0.0, (s, sub) => s + sub.monthlyEquivalent);
      tips.add(
        CoachTip(
          emoji: '📱',
          title: 'Review ${subs.length} subscriptions',
          action:
              'Check if all ${subs.length} recurring payments are necessary',
          impact:
              'Potential savings: ${ExpenseService.fmt(subsTotal * 0.5)}/mo if you cut half',
          impactColor: 0xFFF59E0B,
        ),
      );
    }

    // Tip: Emergency fund
    final burnRateData = burnRate();
    if (burnRateData.runwayDays < 90) {
      tips.add(
        CoachTip(
          emoji: '🛡️',
          title: 'Build 3-month emergency fund',
          action:
              'Save ${ExpenseService.fmt(burnRateData.monthlySpend)} per month for 3 months',
          impact:
              'Target: ${ExpenseService.fmt(burnRateData.monthlySpend * 3)} buffer',
          impactColor: 0xFF6366F1,
        ),
      );
    }

    return tips.take(4).toList();
  }

  // ── 12. RECURRING EXPENSE DETECTION ─────────────────────────────────────
  static List<RecurringExpense> detectRecurring() {
    final all = ExpenseService.all;
    if (all.length < 3) return [];

    final groups = <String, List<Expense>>{};
    for (final e in all.where((e) => !e.isIncome)) {
      final key = e.title.toLowerCase().trim();
      groups[key] = [...(groups[key] ?? []), e];
    }

    final results = <RecurringExpense>[];
    groups.forEach((key, list) {
      if (list.length < 2) return;
      list.sort((a, b) => a.date.compareTo(b.date));
      final avg = list.fold(0.0, (s, e) => s + e.amount) / list.length;
      final similar = list.every(
        (e) => avg == 0 || (e.amount - avg).abs() / avg < 0.25,
      );
      if (!similar) return;
      final daysBetween = list.last.date.difference(list.first.date).inDays;
      final avgInterval = list.length > 1
          ? (daysBetween / (list.length - 1)).round()
          : 30;
      final nextDate = list.last.date.add(Duration(days: avgInterval));
      results.add(
        RecurringExpense(
          title: list.first.title,
          category: list.first.category,
          avgAmount: avg,
          occurrences: list.length,
          nextEstimate: nextDate,
          emoji: _catEmoji(list.first.category),
        ),
      );
    });

    return results.take(5).toList();
  }

  static String _catEmoji(String cat) {
    const m = {
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
    };
    return m[cat] ?? '📦';
  }
}
