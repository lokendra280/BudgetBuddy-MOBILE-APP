import 'package:budgetBuddy/common/widgets/custom_appbar.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_transaction.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/goal_transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalTransactionPage extends StatelessWidget {
  final List<GoalTransaction> transactions;

  const GoalTransactionPage({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(transactions);

    return Scaffold(
      appBar: CustomAppBar(title: "Goal Transactions"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          final date = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(date: date),
              const SizedBox(height: 8),
              ...items.map((t) => GoalTransactionCard(t)),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<GoalTransaction>> _groupByDate(List<GoalTransaction> list) {
    final map = <String, List<GoalTransaction>>{};

    for (final t in list) {
      final key = DateFormat('dd MMM yyyy').format(t.date);

      map.putIfAbsent(key, () => []);
      map[key]!.add(t);
    }

    return map;
  }
}

class _DateHeader extends StatelessWidget {
  final String date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
