import 'dart:ui';

import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard/ui/widgets/cat_icons.dart';
import 'package:expensetracker/common/onboard/ui/widgets/glass_widget.dart';
import 'package:flutter/material.dart';

class ExpenseRow extends StatelessWidget {
  final String emoji, title, sub, amount;
  final Color catColor, amtColor;
  const ExpenseRow({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.amount,
    required this.catColor,
    required this.amtColor,
  });
  @override
  Widget build(BuildContext context) => GlassWidget(
    child: Row(
      children: [
        CatIcon(emoji, catColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(sub, style: TextStyle(fontSize: 10, color: AppColors.white)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: amtColor,
          ),
        ),
      ],
    ),
  );
}
