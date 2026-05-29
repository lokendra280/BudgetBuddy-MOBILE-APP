import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_l10n.dart';
import 'package:flutter/material.dart';

class ExamplesBox extends StatelessWidget {
  final VoiceL10n l10n;
  const ExamplesBox({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.c.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exTitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...l10n.examples.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $e',
              style: TextStyle(fontSize: 12, color: context.c.textMuted),
            ),
          ),
        ),
      ],
    ),
  );
}
