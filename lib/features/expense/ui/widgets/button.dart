import 'dart:ui';

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ModeBtn(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? kMidGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.c.textMuted,
          ),
        ),
      ),
    ),
  );
}

class MonthNav extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev, onTap;
  final VoidCallback? onNext;
  const MonthNav({
    required this.month,
    required this.onPrev,
    required this.onTap,
    this.onNext,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left_rounded),
        onPressed: onPrev,
      ),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.isDark ? kMidGreen.withOpacity(0.2) : kMint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kMidGreen.withOpacity(0.2)),
          ),
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.isDark ? Colors.white : kMidGreen,
            ),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right_rounded),
        onPressed: onNext,
      ),
    ],
  );
}
