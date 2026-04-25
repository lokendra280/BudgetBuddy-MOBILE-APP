import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:expensetracker/features/ai_screen/providers/ai_providers.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(healthScoreProvider);
    final burn = ref.watch(burnRateProvider);
    final alerts = ref.watch(alertsProvider);
    final insights = ref.watch(aiSuggestionsProvider);
    final subs = ref.watch(subscriptionsProvider);
    final rec = ref.watch(recurringProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── Financial Health Score ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                score.color.withOpacity(0.2),
                score.color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Score ring
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score.score / 100,
                      strokeWidth: 8,
                      backgroundColor: c.border,
                      valueColor: AlwaysStoppedAnimation(score.color),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: score.color,
                          ),
                        ),
                        Text(
                          score.grade,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: score.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Health',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9090B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.headline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...score.factors.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(f.emoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        f.label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${f.score}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: score.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  ProgressBar(
                                    f.score / 100,
                                    score.color,
                                    height: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Burn Rate ──────────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconLabel('🔥', 'Burn Rate & Runway'),
              const SizedBox(height: 14),
              Row(
                children: [
                  StatCol('Daily Spend', fmt(burn.dailySpend), kAccent),
                  StatCol(
                    'Monthly Rate',
                    fmt(burn.monthlySpend),
                    AppColors.primaryColor,
                  ),
                  StatCol(
                    'Runway',
                    '${burn.runwayDays} days',
                    burn.runwayDays < 30
                        ? kAccent
                        : burn.runwayDays < 90
                        ? kAmber
                        : kGreen,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (burn.runwayDays < 30 ? kAccent : kGreen).withOpacity(
                    0.07,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      burn.runwayDays < 30
                          ? '⚠️'
                          : burn.runwayDays < 90
                          ? '💡'
                          : '✅',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        burn.runwayDays < 30
                            ? 'Critical: runs out in ${burn.runwayDays} days at this rate'
                            : burn.runwayDays < 90
                            ? 'Moderate: ${burn.runwayDays} day runway. Build emergency fund.'
                            : 'Healthy ${burn.runwayDays}-day runway 🎉',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: burn.runwayDays < 30
                              ? kAccent
                              : burn.runwayDays < 90
                              ? kAmber
                              : kGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Smart Alerts ───────────────────────────────────────────────────────
        if (alerts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('Smart Alerts'),
              Chip(
                label: Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kAccent,
                  ),
                ),
                backgroundColor: kAccent.withOpacity(0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(a.severityColor).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color(a.severityColor).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(a.severityColor),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            a.body,
                            style: TextStyle(
                              fontSize: 11,
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
            ),
          ),
          const SizedBox(height: 6),
        ],

        // ── AI Spending Insights ───────────────────────────────────────────────
        const SectionLabel('AI Spending Insights'),
        const SizedBox(height: 10),
        if (insights.isEmpty)
          const EmptyCard(
            '✨',
            'Add more expenses',
            'We\'ll analyse patterns once you have more data.',
          )
        else
          ...insights.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EmojiBox(s.emoji, Color(s.color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.body,
                            style: TextStyle(
                              fontSize: 11,
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
            ),
          ),

        // ── Subscriptions + Recurring ──────────────────────────────────────────
        const SizedBox(height: 8),
        const SectionLabel('Subscriptions & Recurring'),
        const SizedBox(height: 10),
        // combine subscriptions and recurring items, take up to 5 and render each as a card
        ...[...subs, ...rec].take(5).map((i) {
          final dyn = i as dynamic;
          final title = dyn.title ?? dyn.name ?? dyn.label ?? '';
          final subtitle = dyn.schedule ?? dyn.period ?? dyn.recurring ?? '';
          final emoji = (dyn.emoji ?? '💳') as String;
          final color = dyn.color != null
              ? Color(dyn.color)
              : AppColors.primaryColor.withOpacity(0.12);
          final amountVal = dyn.amount ?? dyn.price ?? dyn.cost ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  EmojiBox(emoji, color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 10, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt(amountVal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
