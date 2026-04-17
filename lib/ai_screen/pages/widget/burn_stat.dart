import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class BurnStatWidget extends StatelessWidget {
  final String label, value;
  final Color color;
  const BurnStatWidget(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    ),
  );
}
