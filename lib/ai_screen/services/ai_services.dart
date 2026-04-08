// ── Fully local AI logic — no API key, works offline ─────────────────────────
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';

class AiService {
  // ── Spending suggestions based on patterns ──────────────────────────────────
  static List<AiSuggestion> suggestions() {
    final expenses = ExpenseService.forMonth(DateTime.now());
    final cats = ExpenseService.byCategory(expenses);
    final total = ExpenseService.totalFor(expenses);
    final budget = ExpenseService.budget;
    final results = <AiSuggestion>[];

    if (cats.isEmpty) return results;

    // Rule 1: Top category > 40% of total
    final top = cats.entries.first;
    if (total > 0 && top.value / total > 0.4) {
      results.add(
        AiSuggestion(
          emoji: '⚠️',
          title:
              '${top.key} is ${(top.value / total * 100).toInt()}% of spending',
          body:
              'Try setting a ₹${(top.value * 0.8).toStringAsFixed(0)} limit for ${top.key} next month.',
          color: 0xFFFF6B81,
        ),
      );
    }

    // Rule 2: Over budget
    if (total > budget.monthlyLimit) {
      final over = total - budget.monthlyLimit;
      results.add(
        AiSuggestion(
          emoji: '🚨',
          title: 'Over budget by ₹${over.toStringAsFixed(0)}',
          body:
              'You\'ve exceeded your ₹${budget.monthlyLimit.toStringAsFixed(0)} limit. Cut back on ${top.key}.',
          color: 0xFFFF6B81,
        ),
      );
    }

    // Rule 3: Frequent small Food expenses
    final foodExpenses = expenses
        .where((e) => e.category == 'Food' && e.amount < 200)
        .toList();
    if (foodExpenses.length > 10) {
      final smallFoodTotal = foodExpenses.fold(0.0, (s, e) => s + e.amount);
      results.add(
        AiSuggestion(
          emoji: '☕',
          title: '${foodExpenses.length} small food purchases',
          body:
              'Small snacks adding up to ₹${smallFoodTotal.toStringAsFixed(0)}. Cooking more could save big.',
          color: 0xFFFBBF24,
        ),
      );
    }

    // Rule 4: Good month (under 70% budget)
    final pct = total / budget.monthlyLimit;
    if (pct < 0.7 && total > 0) {
      results.add(
        AiSuggestion(
          emoji: '🎉',
          title: 'Great spending month!',
          body:
              'You\'ve only used ${(pct * 100).toInt()}% of your budget. Keep it up!',
          color: 0xFF34D399,
        ),
      );
    }

    return results.take(3).toList();
  }

  // ── Recurring expense detection ─────────────────────────────────────────────
  static List<RecurringExpense> detectRecurring() {
    final all = ExpenseService.all;
    if (all.length < 4) return [];

    // Group by normalised title
    final Map<String, List<Expense>> groups = {};
    for (final e in all) {
      final key = e.title.toLowerCase().trim();
      groups[key] = [...(groups[key] ?? []), e];
    }

    final results = <RecurringExpense>[];
    groups.forEach((key, list) {
      if (list.length >= 2) {
        list.sort((a, b) => a.date.compareTo(b.date));
        // Check if amounts are similar (within 20%)
        final avg = list.fold(0.0, (s, e) => s + e.amount) / list.length;
        final similar = list.every((e) => (e.amount - avg).abs() / avg < 0.2);
        if (similar) {
          // Estimate next date
          final daysBetween = list.last.date.difference(list.first.date).inDays;
          final avgInterval = list.length > 1
              ? daysBetween ~/ (list.length - 1)
              : 30;
          final nextDate = list.last.date.add(Duration(days: avgInterval));

          results.add(
            RecurringExpense(
              title: list.first.title,
              category: list.first.category,
              avgAmount: avg,
              occurrences: list.length,
              nextEstimate: nextDate,
              emoji: _emoji(list.first.category),
            ),
          );
        }
      }
    });

    return results.take(5).toList();
  }

  static String _emoji(String cat) {
    const m = {
      'Food': '🍜',
      'Transport': '🚗',
      'Shopping': '🛍',
      'Health': '💊',
      'Bills': '⚡',
      'Entertainment': '🎬',
      'Other': '📦',
    };
    return m[cat] ?? '📦';
  }
}

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
