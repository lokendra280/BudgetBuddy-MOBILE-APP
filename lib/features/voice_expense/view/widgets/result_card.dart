import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_l10n.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_result.dart';
import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final VoiceResult result;
  final String Function(double) fmt;
  final VoiceL10n l10n;
  const ResultCard({
    super.key,
    required this.result,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.detected,
              style: TextStyle(fontSize: 11, color: context.c.textMuted),
            ),
            _Badge(
              isIncome: result.isIncome,
              label: result.isIncome ? l10n.income : l10n.expense,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Field(l10n.amount, fmt(result.amount))),
            // Expanded(child: _Field(l10n.category, result.category)),
            Expanded(child: _Field(l10n.titleField, result.title, maxLines: 2)),
            // Category display label (translated)
            Expanded(
              child: _Field(
                l10n.category,
                l10n.catDisplay[result.category.toLowerCase()] ??
                    result.category,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final bool isIncome;
  final String label;
  const _Badge({required this.isIncome, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (isIncome ? kGreen : kAccent).withOpacity(.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isIncome ? kGreen : kAccent,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label, value;
  final int maxLines;
  const _Field(this.label, this.value, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 9, color: context.c.textMuted)),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
