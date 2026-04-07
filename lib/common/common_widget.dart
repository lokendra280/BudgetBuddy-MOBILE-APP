import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/services/ads_service.dart';
import 'package:expensetracker/common/services/premium_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

// ── AppCard ───────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
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
            style: TextStyle(
              fontSize: 10,
              color: context.c.textMuted,
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
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : c.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? kPrimary : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.textSub,
          ),
        ),
      ),
    );
  }
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                kCatEmoji[e.category] ?? '📦',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
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
                  style: TextStyle(fontSize: 11, color: context.c.textMuted),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style:
          style ??
          TextStyle(
            color: context.isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 14,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        prefixIcon: prefix,
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
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
              style: TextStyle(fontSize: 11, color: context.c.textMuted),
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
            backgroundColor: context.c.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── WeekCompareBar ────────────────────────────────────────────────────────────
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
        _Bar('Last week', lastWeek, lastWeek / max, context.c.textMuted),
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
            backgroundColor: context.c.border,
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
        Text(label, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      ],
    ),
  );
}

// ── ShareCard ─────────────────────────────────────────────────────────────────
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
          style: TextStyle(fontSize: 12, color: Colors.white60),
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
      ],
    ),
  );
}

// ── BannerAdWidget ────────────────────────────────────────────────────────────
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdService.createBanner().adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PremiumService.isPremium || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.border)),
      ),
      child: AdWidget(ad: _ad!),
    );
  }
}

// ── PremiumBadge ──────────────────────────────────────────────────────────────
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⭐', style: TextStyle(fontSize: 11)),
        SizedBox(width: 4),
        Text(
          'PRO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ── LockedInsightCard ─────────────────────────────────────────────────────────
class LockedInsightCard extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onUnlock;
  final bool unlocked;
  const LockedInsightCard({
    super.key,
    required this.title,
    required this.content,
    required this.onUnlock,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    if (PremiumService.isPremium || unlocked) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionLabel(title), const SizedBox(height: 14), content],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 14),
          Stack(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  context.c.card.withOpacity(0.85),
                  BlendMode.srcOver,
                ),
                child: content,
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.bg.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.c.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔒', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        const Text(
                          'Advanced Insight',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Watch a short ad to unlock',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 160,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                AdService.showRewarded(onRewarded: onUnlock),
                            icon: const Icon(
                              Icons.play_circle_outline,
                              size: 16,
                            ),
                            label: const Text(
                              'Watch Ad',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── PremiumFeatureRow ─────────────────────────────────────────────────────────
class PremiumFeatureRow extends StatelessWidget {
  final String emoji, label;
  const PremiumFeatureRow(this.emoji, this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}
