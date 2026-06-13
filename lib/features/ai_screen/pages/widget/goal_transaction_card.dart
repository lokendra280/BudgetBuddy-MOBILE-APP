import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_transaction.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalTransactionCard extends ConsumerWidget {
  final GoalTransaction t;

  const GoalTransactionCard(this.t);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = ref.read(symbolProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // _Icon(),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.amount >= 0 ? "Added to Goal" : "Withdrawal",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a dd MMM').format(t.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            "$sym${t.amount.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
