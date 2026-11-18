import 'package:budgetbuddy/common/app_theme.dart';
import 'package:flutter/material.dart';

/// Rounded progress bar that animates to its value.
class BudgetProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const BudgetProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: context.c.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}
