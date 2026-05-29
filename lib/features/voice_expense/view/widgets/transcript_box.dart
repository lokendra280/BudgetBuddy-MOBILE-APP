import 'package:budgetBuddy/common/app_theme.dart';
import 'package:flutter/material.dart';

class TranscriptBox extends StatelessWidget {
  final String text;
  const TranscriptBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.c.border),
    ),
    child: Text(
      '"$text"',
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    ),
  );
}
