import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BillAlertStrip  — updated to use AppTypography
// Works for both BillReminder and EmiLoan (both expose .title, .daysUntilDue,
// .emoji, .isOverdue via duck-typed dynamic list).
// ─────────────────────────────────────────────────────────────────────────────

class BillAlertStrip extends StatelessWidget {
  final List<dynamic> overdue;
  final List<dynamic> dueSoon;
  final String Function(double) fmt;
  final VoidCallback onTap;

  const BillAlertStrip({
    super.key,
    required this.overdue,
    required this.dueSoon,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = overdue.isNotEmpty;
    final color = isOverdue ? kAccent : kAmber;
    final bills = isOverdue ? overdue : dueSoon;
    final count = bills.length;

    final message = count == 1
        ? isOverdue
              ? '${bills[0].title} is overdue — pay now!'
              : '${bills[0].title} due in ${bills[0].daysUntilDue}d'
        : isOverdue
        ? '$count bills overdue — tap to review'
        : '$count bills due soon — tap to review';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withOpacity(0.1),
        child: Row(
          children: [
            Icon(
              isOverdue ? Icons.error_rounded : Icons.alarm_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            CommonSvgWidget(svgName: bills[0].emoji, color: color, height: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.labelLarge.colored(color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
