/// Shared micro-widgets used across all AI screen tabs.
/// Import this single file in each tab instead of re-declaring widgets.
library;

import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

// ── Progress bar ─────────────────────────────────────────────────────────────
class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final double clip;
  const ProgressBar(
    this.value,
    this.color, {
    super.key,
    this.height = 6,
    this.clip = 4,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(clip),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      backgroundColor: context.c.border,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );
}

// ── 40×40 emoji container ─────────────────────────────────────────────────────
class EmojiBox extends StatelessWidget {
  final String emoji;
  final Color bg;
  final double size, iconSize;
  const EmojiBox(
    this.emoji,
    this.bg, {
    super.key,
    this.size = 40,
    this.iconSize = 18,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Center(
      child: Text(emoji, style: TextStyle(fontSize: iconSize)),
    ),
  );
}

// ── Icon + title row (optional subtitle) ─────────────────────────────────────
class IconLabel extends StatelessWidget {
  final String emoji, title;
  final String? sub;
  const IconLabel(this.emoji, this.title, {super.key, this.sub});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (sub != null)
              Text(
                sub!,
                style: TextStyle(fontSize: 11, color: context.c.textMuted),
              ),
          ],
        ),
      ),
    ],
  );
}

// ── Centered empty-state card ─────────────────────────────────────────────────
class EmptyCard extends StatelessWidget {
  final String emoji, title, sub;
  const EmptyCard(this.emoji, this.title, this.sub, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    alignment: Alignment.center,
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: TextStyle(fontSize: 12, color: context.c.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ── Stat column (burn rate) ───────────────────────────────────────────────────
class StatCol extends StatelessWidget {
  final String l, v;
  final Color c;
  const StatCol(this.l, this.v, this.c, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c),
        ),
        const SizedBox(height: 3),
        Text(l, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    ),
  );
}

// ── Budget 50/30/20 progress row ─────────────────────────────────────────────
class BudgetBar extends StatelessWidget {
  final String label, hint, sym;
  final double budget, spent;
  final Color color;
  const BudgetBar(
    this.label,
    this.budget,
    this.spent,
    this.color,
    this.sym,
    this.hint, {
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '$sym${spent.toStringAsFixed(0)} / $sym${budget.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ProgressBar(pct, pct > 1 ? kAccent : color, height: 8, clip: 5),
        const SizedBox(height: 3),
        Text(hint, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    );
  }
}

// ── Income stat column (this month card) ─────────────────────────────────────
class IncomeStat extends StatelessWidget {
  final String l, v;
  final Color c;
  const IncomeStat(this.l, this.v, this.c, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c),
        ),
        const SizedBox(height: 3),
        Text(l, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    ),
  );
}

// ── Predict stat column ───────────────────────────────────────────────────────
class PredStat extends StatelessWidget {
  final String l, v;
  final Color c;
  final String prefix;
  const PredStat(this.l, this.v, this.c, {super.key, this.prefix = ''});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$prefix$v',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c),
      ),
      Text(l, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
    ],
  );
}

// ── Gradient container decoration ────────────────────────────────────────────
BoxDecoration gradBox(Color color) => BoxDecoration(
  gradient: LinearGradient(
    colors: [color.withOpacity(0.14), color.withOpacity(0.03)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: color.withOpacity(0.25)),
);
