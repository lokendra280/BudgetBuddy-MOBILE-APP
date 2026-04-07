import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── AppCard ───────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: child,
    ),
  );
}

// ── MetricCard ────────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── CategoryPill ──────────────────────────────────────────────────────────────
class CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const CategoryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? kPrimary : kCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? kPrimary : kBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : kTextSub,
        ),
      ),
    ),
  );
}

// ── ExpenseTile ───────────────────────────────────────────────────────────────
class ExpenseTile extends StatelessWidget {
  final Expense e;
  final Color color;
  final VoidCallback onDelete;
  const ExpenseTile({
    super.key,
    required this.e,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(e.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => onDelete(),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: kAccent, size: 20),
    ),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          _CatIcon(category: e.category, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.category} · ${DateFormat('MMM d').format(e.date)}',
                  style: const TextStyle(fontSize: 11, color: kTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${e.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CatIcon extends StatelessWidget {
  final String category;
  final Color color;
  const _CatIcon({required this.category, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        kCatEmoji[category] ?? '📦',
        style: const TextStyle(fontSize: 17),
      ),
    ),
  );
}

// ── SectionLabel ──────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

// ── AppButton ─────────────────────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
  );
}

// ── InputField ────────────────────────────────────────────────────────────────
class InputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final Widget? prefix;
  final TextStyle? style;
  const InputField({
    super.key,
    required this.hint,
    required this.controller,
    this.keyboard,
    this.prefix,
    this.style,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboard,
    style: style ?? const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    ),
  );
}

// ── StreakBadge ───────────────────────────────────────────────────────────────
class StreakBadge extends StatelessWidget {
  final int days;
  const StreakBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: kAmber.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kAmber.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$days day streak',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kAmber,
          ),
        ),
      ],
    ),
  );
}

// ── BudgetBar ─────────────────────────────────────────────────────────────────
class BudgetBar extends StatelessWidget {
  final double percent;
  const BudgetBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent > 0.85
        ? kAccent
        : percent > 0.6
        ? kAmber
        : kGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget used',
              style: const TextStyle(fontSize: 11, color: kTextMuted),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: kBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── WeekCompare ───────────────────────────────────────────────────────────────
class WeekCompareBar extends StatelessWidget {
  final double thisWeek, lastWeek;
  const WeekCompareBar({
    super.key,
    required this.thisWeek,
    required this.lastWeek,
  });

  @override
  Widget build(BuildContext context) {
    final max = [thisWeek, lastWeek, 1.0].reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        _Bar('This week', thisWeek, thisWeek / max, kPrimary),
        const SizedBox(width: 12),
        _Bar('Last week', lastWeek, lastWeek / max, kTextMuted),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value, frac;
  final Color color;
  const _Bar(this.label, this.value, this.frac, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: kBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
      ],
    ),
  );
}

// ── ShareCard (for screenshot) ────────────────────────────────────────────────
class ShareCard extends StatelessWidget {
  final double total, saved;
  final String topCat, message;
  final int streak;
  const ShareCard({
    super.key,
    required this.total,
    required this.saved,
    required this.topCat,
    required this.message,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 340,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1035), Color(0xFF0D0D1E)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kPrimary.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💸', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text(
              'SpendSense',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
            const Spacer(),
            StreakBadge(days: streak),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '₹${total.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const Text(
          'spent this month',
          style: TextStyle(fontSize: 12, color: kTextMuted),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _ShareStat('Top spend', topCat),
            const SizedBox(width: 12),
            _ShareStat('Saved', '₹${saved.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Track yours at SpendSense 📊',
            style: TextStyle(fontSize: 10, color: kTextMuted),
          ),
        ),
      ],
    ),
  );
}

class _ShareStat extends StatelessWidget {
  final String label, value;
  const _ShareStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
