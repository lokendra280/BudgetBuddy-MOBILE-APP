import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:budgetBuddy/features/ai_screen/providers/ai_providers.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── Coach header ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: gradBox(AppColors.primaryColor),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.yourAiFinancialCoach,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.personalizedTips,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                        height: 1.4,
                      ),
                    ),
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
                        Text(g.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${g.daysLeft} ${l.daysLeft} · ${(g.progress * 100).toInt()}% ${l.complete}',
                                style: TextStyle(
                                  fontSize: 10,
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
                          style: TextStyle(fontSize: 10, color: c.textMuted),
                        ),
                        Text(
                          '${fmt(g.target)} ${l.target}',
                          style: const TextStyle(
                            fontSize: 10,
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: g.onTrack ? kGreen : kAmber,
                            ),
                          ),
                          if (!g.onTrack && g.availableDailyAmount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l.availablePerDay}: ${fmt(g.availableDailyAmount)}${l.perDay} · ${l.needPerDay}: ${fmt(g.requiredDailyAmount)}${l.perDay}',
                              style: TextStyle(
                                fontSize: 10,
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
          ...tips.asMap().entries.map(
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
                            style: const TextStyle(
                              fontSize: 13,
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
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: kAmber),
                        const SizedBox(width: 4),
                        Text(
                          '${l.impact}: ',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            e.value.impact,
                            style: TextStyle(
                              fontSize: 11,
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

        const SizedBox(height: 8),

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
                          style: const TextStyle(fontSize: 16),
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${r.occurrences}× · avg ${fmt(r.avgAmount)} · next ~${DateFormat('MMM d').format(r.nextEstimate)}',
                            style: TextStyle(fontSize: 10, color: c.textMuted),
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
                      child: const Text('🔄', style: TextStyle(fontSize: 12)),
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
      style: TextStyle(
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
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
      ),
    ),
  );
}
