// Shared BudgetBuddy design building blocks.
//
// Use these instead of re-drawing the same green hero card / headers /
// ad slots on every screen, so the whole app stays visually consistent.
//
//   TabHeader        — big title + subtitle at the top of a bottom-nav tab
//   BrandHeroCard    — deep-green gradient card (balance, health, forecast…)
//   HeroChip         — translucent stat pill that sits inside a hero card
//   SectionHeader    — section title + optional trailing action
//   AdSlot           — banner ad with consistent spacing (collapses if none)
//   RewardUnlock     — "watch an ad to unlock for 24h" gate for extras

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/providers/remote_config_provider.dart';
import 'package:budgetbuddy/common/services/ads_service.dart';
import 'package:budgetbuddy/features/home/ui/widgets/home_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────

class TabHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDark
              ? [kDeepGreen.withValues(alpha: 0.30), context.c.bg]
              : [kMint, context.c.bg],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        bottom == null ? 12 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back arrow when this page was pushed (e.g. Statements from Home).
              if (ModalRoute.of(context)?.canPop ?? false) ...[
                HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.t.h1),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: context.t.bodySub),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ],
      ),
    );
  }
}

/// Round icon button used in [TabHeader.trailing].
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Widget? child;
  const HeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.child,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: Material(
      color: context.c.card,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: child ?? Icon(icon, size: 21, color: kMidGreen)),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class BrandHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final List<Color>? colors;

  const BrandHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colors ?? const [kDeepGreen, kMidGreen];
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cs,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.first.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -36, top: -46, child: _glass(140, 0.07)),
          Positioned(right: 50, bottom: -60, child: _glass(110, 0.05)),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Widget _glass(double s, double a) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: a),
    ),
  );
}

/// Text styles for content on a [BrandHeroCard].
extension HeroText on BuildContext {
  TextStyle get heroLabel => t.caption.copyWith(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 11,
  );
  TextStyle get heroValue => t.h1.copyWith(color: Colors.white);
  TextStyle get heroBody =>
      t.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85));
}

class HeroChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  const HeroChip({
    super.key,
    this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.heroLabel, maxLines: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: context.t.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.t.h4)),
        if (trailing != null) trailing!,
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: context.t.buttonSmall.colored(
                      AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

/// A banner ad placed between content sections. Takes no space when no ad is
/// loaded or ads are disabled via remote config.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key});

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.only(top: 4), child: HomeBannerAd());
}

// ─────────────────────────────────────────────────────────────────────────────

/// Gates "extra" content behind a rewarded ad, unlocked for 24 hours.
///
/// UX rules:
///  • core features are never gated — only extras (more predictions, more tips)
///  • if rewarded ads are off or no ad is ready, it simply unlocks
///  • one ad unlocks the feature for 24h, so users aren't nagged repeatedly
class RewardUnlock {
  RewardUnlock._();

  static const _window = Duration(hours: 24);
  static String _key(String feature) => 'reward_unlock_$feature';

  static Future<bool> isUnlocked(String feature) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_key(feature));
      if (ms == null) return false;
      return DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(ms),
          ) <
          _window;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _grant(String feature) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(feature), DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Shows a rewarded ad (or unlocks directly when none is available) and
  /// calls [onUnlocked] afterwards.
  static void unlock(
    WidgetRef ref,
    String feature, {
    required VoidCallback onUnlocked,
  }) {
    Future<void> grant() async {
      await _grant(feature);
      onUnlocked();
    }

    if (!ref.read(rewardedAdsEnabledProvider)) {
      grant();
      return;
    }
    ref
        .read(adServiceProvider)
        .showRewarded(onRewarded: grant, onNotAvailable: grant);
  }
}

/// Shows [lockedPreview] + an unlock button until the user watches an ad,
/// then shows [child] for 24 hours.
class RewardGate extends ConsumerStatefulWidget {
  final String feature;
  final String title;
  final String subtitle;
  final Widget child;

  const RewardGate({
    super.key,
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  ConsumerState<RewardGate> createState() => _RewardGateState();
}

class _RewardGateState extends ConsumerState<RewardGate> {
  bool? _unlocked;

  @override
  void initState() {
    super.initState();
    ref.read(adServiceProvider).preloadRewarded();
    RewardUnlock.isUnlocked(widget.feature).then((v) {
      if (mounted) setState(() => _unlocked = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == null) return const SizedBox.shrink();
    if (_unlocked! || !ref.watch(rewardedAdsEnabledProvider)) {
      return widget.child;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? kMidGreen.withValues(alpha: 0.18) : kMint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kMidGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kMidGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: context.t.labelLarge),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: context.t.labelMuted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => RewardUnlock.unlock(
              ref,
              widget.feature,
              onUnlocked: () {
                if (mounted) setState(() => _unlocked = true);
              },
            ),
            style: FilledButton.styleFrom(
              backgroundColor: kMidGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
            label: Text(
              'Unlock',
              style: context.t.buttonSmall.colored(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
