import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmiTile — card for each loan in the list
// ─────────────────────────────────────────────────────────────────────────────

class EmiTile extends StatelessWidget {
  final EmiLoan loan;
  final String Function(double) fmt;
  final VoidCallback onTap, onEdit, onDelete, onToggle, onPay;

  const EmiTile({
    super.key,
    required this.loan,
    required this.fmt,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = loan.isOverdue
        ? kAccent
        : loan.isDueSoon
        ? kAmber
        : AppColors.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: icon + title + amount ──────────────────────────────
            Row(
              children: [
                _EmojiAvatar(emoji: loan.emoji, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.title,
                        style: context.t.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(loan.lenderName, style: context.t.labelMuted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt(loan.emiAmount),
                      style: AppTypography.amount.colored(color),
                    ),
                    Text('/mo', style: context.t.captionMuted),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress bar ───────────────────────────────────────────────
            _ProgressBar(ratio: loan.progressRatio, color: color),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loan.emisPaid} of ${loan.tenureMonths} EMIs paid',
                  style: context.t.captionMuted,
                ),
                Text(
                  fmt(loan.remainingBalance) + ' left',
                  style: AppTypography.caption.colored(color),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Row 2: due pill + action buttons ──────────────────────────
            Row(
              children: [
                _DuePill(loan: loan, color: color),
                const Spacer(),
                _ActionButton(
                  icon: Icons.payments_rounded,
                  color: AppColors.primaryColor,
                  tooltip: 'Pay',
                  onTap: onPay,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.edit_rounded,
                  color: c.textMuted,
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_rounded,
                  color: kAccent,
                  tooltip: 'Delete',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  final Color color;
  const _EmojiAvatar({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
  );
}

class _ProgressBar extends StatelessWidget {
  final double ratio;
  final Color color;
  const _ProgressBar({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: ratio,
      minHeight: 6,
      backgroundColor: context.c.border,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );
}

class _DuePill extends StatelessWidget {
  final EmiLoan loan;
  final Color color;
  const _DuePill({required this.loan, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = loan.isOverdue
        ? 'Overdue!'
        : loan.daysUntilDue == 0
        ? 'Due today!'
        : loan.daysUntilDue == 1
        ? 'Due tomorrow'
        : 'Due in ${loan.daysUntilDue}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.colored(color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    ),
  );
}
