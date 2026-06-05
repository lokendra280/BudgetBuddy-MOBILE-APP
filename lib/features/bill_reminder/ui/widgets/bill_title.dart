import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class BillTile extends StatelessWidget {
  final BillReminder bill;
  final String Function(double) fmt;
  final VoidCallback onEdit, onDelete, onToggle;
  const BillTile({
    required this.bill,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final days = bill.daysUntilDue;
    final overdue = bill.isOverdue;
    final dueSoon = bill.isDueSoon;
    final col = overdue
        ? kAccent
        : dueSoon
        ? kAmber
        : AppColors.primaryColor;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: col.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CommonSvgWidget(
                svgName: bill.emoji,
                height: 22,
                width: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Tag(bill.category, c.textMuted, c.border),
                    const SizedBox(width: 6),
                    _Tag(
                      bill.isRecurring ? 'Monthly' : 'One-time',
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Due date pill
                _DuePill(
                  days: days,
                  overdue: overdue,
                  dueDate: bill.computedDueDate,
                  col: col,
                ),
              ],
            ),
          ),

          // Amount + controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt(bill.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: bill.isActive ? col : c.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle active
                  GestureDetector(
                    onTap: onToggle,
                    child: CommonSvgWidget(
                      svgName: bill.isActive
                          ? Assets.notification
                          : Assets.notification,
                      height: 18,
                      color: bill.isActive ? kGreen : c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: CommonSvgWidget(
                      svgName: Assets.edit,
                      height: 18,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const CommonSvgWidget(
                      svgName: Assets.delete,
                      height: 18,
                      color: kAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color text2, bg;
  const _Tag(this.text, this.text2, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg.withOpacity(0.15),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, color: text2, fontWeight: FontWeight.w600),
    ),
  );
}

class _DuePill extends StatelessWidget {
  final int days;
  final bool overdue;
  final DateTime dueDate;
  final Color col;
  const _DuePill({
    required this.days,
    required this.overdue,
    required this.dueDate,
    required this.col,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.calendar_today_rounded, size: 10, color: col),
      const SizedBox(width: 4),
      Text(
        overdue
            ? 'Overdue!'
            : days == 0
            ? 'Due today!'
            : days == 1
            ? 'Due tomorrow'
            : 'Due in $days days · ${DateFormat('MMM d').format(dueDate)}',
        style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
