import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
import 'package:expensetracker/features/social/models/social_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChallengesTab extends ConsumerWidget {
  const ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // All data from providers — no static service calls
    final all = ref.watch(monthExpensesProvider);
    final budget = ref.watch(budgetProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    final exp = all.where((e) => !e.isIncome).toList();
    final total = exp.fold(0.0, (s, e) => s + e.amount);
    final limit = budget.monthlyLimit;

    // Category totals
    final catMap = <String, double>{};
    for (final e in exp)
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    final food = (catMap['Food'] ?? 0) + (catMap['Groceries'] ?? 0);
    final trans = catMap['Transport'] ?? 0;
    final ent = catMap['Entertainment'] ?? 0;

    // Weekend spending (current week Sat + Sun)
    final now = DateTime.now();
    final wStart = now.subtract(Duration(days: now.weekday - 1));
    final wkSat = ref
        .watch(expenseProvider)
        .all
        .where(
          (e) =>
              !e.isIncome &&
              e.date.isAfter(wStart.subtract(const Duration(days: 1))) &&
              (e.date.weekday == 6 || e.date.weekday == 7),
        )
        .fold(0.0, (s, e) => s + e.amount);

    final challenges = [
      CData(
        'Budget Hero 💰',
        'Stay under monthly budget',
        limit > 0 ? (total < limit ? (limit - total) / limit : 0.0) : 0.0,
        kGreen,
        '${((total / limit.clamp(1, 9999999)) * 100).toInt()}% of budget used',
      ),
      CData(
        'Food Saver 🍱',
        'Keep food under 30% of budget',
        food > 0 ? (1 - (food / (limit * 0.3)).clamp(0, 1)) : 1.0,
        AppColors.primaryColor,
        'Food: ${fmt(food)} / ${fmt(limit * 0.3)}',
      ),
      CData(
        'No-Spend Weekend 🚫',
        'Zero spend on Sat & Sun',
        wkSat == 0 ? 1.0 : 0.0,
        kAmber,
        wkSat == 0
            ? '✓ Weekend clear so far!'
            : '${fmt(wkSat)} spent this weekend',
      ),
      CData(
        'Transport Cutter 🚌',
        'Transport under 10% of budget',
        trans > 0 ? (1 - (trans / (limit * 0.1)).clamp(0, 1)) : 1.0,
        kBlue,
        'Transport: ${fmt(trans)} / ${fmt(limit * 0.1)}',
      ),
      CData(
        'Entertainment Free 🎬',
        'No entertainment this month',
        ent == 0 ? 1.0 : 0.0,
        kAccent,
        ent == 0
            ? '✓ No entertainment spend!'
            : '${fmt(ent)} spent on entertainment',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionLabel('Active Challenges'),
        const SizedBox(height: 12),
        ...challenges.map(
          (ch) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ch.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (ch.progress >= 1 ? kGreen : ch.color)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ch.progress >= 1
                              ? '✓ Done'
                              : '${(ch.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ch.progress >= 1 ? kGreen : ch.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ch.desc,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ch.progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: c.border,
                      valueColor: AlwaysStoppedAnimation(
                        ch.progress >= 1 ? kGreen : ch.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ch.hint,
                    style: TextStyle(fontSize: 10, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
