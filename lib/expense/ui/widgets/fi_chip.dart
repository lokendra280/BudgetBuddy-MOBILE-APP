import 'dart:ui';

import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class FiChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const FiChip(this.label, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.12) : context.c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color : context.c.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : context.c.textMuted,
        ),
      ),
    ),
  );
}
