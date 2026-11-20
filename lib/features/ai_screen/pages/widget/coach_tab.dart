import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetbuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CoachTab extends ConsumerWidget {
  const CoachTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tips = ref.watch(coachTipsProvider);
    final rec = ref.watch(recurringProvider);
    final goalInsights = ref.watch(goalInsightsProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        // ── Coach header ─────────────────────────────────────────────────────
        BrandHeroCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(child: PiggyMascot(size: 44)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.yourAiFinancialCoach,
                      style: context.t.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(l.personalizedTips, style: context.heroBody),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Goal Tracker ─────────────────────────────────────────────────────
        if (goalInsights.isNotEmpty) ...[
          SectionLabel(l.goalTracker),
          const SizedBox(height: 12),
          ...goalInsights.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          g.emoji,
                          style: AppTypography.h2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${g.daysLeft} ${l.daysLeft} · ${(g.progress * 100).toInt()}% ${l.complete}',
                                style: AppTypography.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _GoalStatusBadge(g.onTrack, l),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(
                      g.progress,
                      g.onTrack ? kGreen : kAmber,
                      height: 8,
                      clip: 4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${fmt(g.saved)} ${l.saved}',
                          style: AppTypography.caption.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                        Text(
                          '${fmt(g.target)} ${l.target}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (g.onTrack ? kGreen : kAmber).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (g.onTrack ? kGreen : kAmber).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.statusMessage,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: g.onTrack ? kGreen : kAmber,
                            ),
                          ),
                          if (!g.onTrack && g.availableDailyAmount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l.availablePerDay}: ${fmt(g.availableDailyAmount)}${l.perDay} · ${l.needPerDay}: ${fmt(g.requiredDailyAmount)}${l.perDay}',
                              style: AppTypography.caption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Personalised Tips ────────────────────────────────────────────────
        SectionLabel(l.personalAdvice),
        const SizedBox(height: 12),

        if (tips.isEmpty)
          EmptyCard('🌱', l.keepTracking, l.addMoreDataUnlock)
        else
          ...tips
              .asMap()
              .entries
              .take(2)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            EmojiBox(
                              e.value.emoji,
                              Color(e.value.impactColor).withOpacity(0.12),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value.title,
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _TipBadge(e.key + 1, l),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  e.value.action,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: kAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${l.impact}: ',
                              style: AppTypography.labelSmall.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value.impact,
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Color(e.value.impactColor),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        if (tips.asMap().entries.length > 2)
          RewardGate(
            feature: 'coach_tips',
            title: '+${tips.asMap().entries.length - 2} more personalised tips',
            subtitle: 'Watch a short ad · unlocked for 24h',
            child: Column(
              children: tips
                  .asMap()
                  .entries
                  .skip(2)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                EmojiBox(
                                  e.value.emoji,
                                  Color(e.value.impactColor).withOpacity(0.12),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    e.value.title,
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _TipBadge(e.key + 1, l),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: c.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 14,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      e.value.action,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 14,
                                  color: kAmber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${l.impact}: ',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.impact,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Color(e.value.impactColor),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 8),

        const AdSlot(),

        // ── Recurring Expenses ───────────────────────────────────────────────
        SectionLabel(l.recurringExpenses),
        const SizedBox(height: 10),

        if (rec.isEmpty)
          EmptyCard(Assets.refresh, l.noRecurringDetected, l.repeatedExpenses)
        else
          ...rec.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          r.emoji,
                          style: AppTypography.h4.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${r.occurrences}× · avg ${fmt(r.avgAmount)} · next ~${DateFormat('MMM d').format(r.nextEstimate)}',
                            style: AppTypography.caption.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔄',
                        style: AppTypography.labelSmall.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _GoalStatusBadge extends StatelessWidget {
  final bool onTrack;
  final AppLocalizations l;
  const _GoalStatusBadge(this.onTrack, this.l);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (onTrack ? kGreen : kAmber).withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      onTrack ? '✅ ${l.onTrack}' : '⚠️ ${l.atRisk}',
      style: AppTypography.caption.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: onTrack ? kGreen : kAmber,
      ),
    ),
  );
}

class _TipBadge extends StatelessWidget {
  final int number;
  final AppLocalizations l;
  const _TipBadge(this.number, this.l);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'Tip $number',
      style: AppTypography.caption.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
      ),
    ),
  );
}
