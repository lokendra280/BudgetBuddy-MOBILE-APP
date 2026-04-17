import 'package:expensetracker/ai_screen/pages/widget/burn_stat.dart';
import 'package:expensetracker/ai_screen/services/ai_services.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverViewTab extends StatelessWidget {
  const OverViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final score = AiService.healthScore();
    final burn = AiService.burnRate();
    final alerts = AiService.alerts();
    final insights = AiService.suggestions();

    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // ── Financial Health Score ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                score.color.withOpacity(0.15),
                score.color.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: score.color.withOpacity(0.3)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(score.color),
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

              // Details
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: f.score / 100,
                                      minHeight: 4,
                                      backgroundColor: c.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        score.color,
                                      ),
                                    ),
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

        // ── Burn Rate ───────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text('🔥', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Burn Rate & Runway',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  BurnStatWidget(
                    'Daily Spend',
                    ExpenseService.fmt(burn.dailySpend),
                    kAccent,
                  ),
                  BurnStatWidget(
                    'Monthly Rate',
                    ExpenseService.fmt(burn.monthlySpend),
                    AppColors.primaryColor,
                  ),
                  BurnStatWidget(
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
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Alerts ───────────────────────────────────────────────
        if (alerts.isNotEmpty) ...[
          const SectionLabel('Smart Alerts'),
          const SizedBox(height: 10),

          ...alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(a.severityColor).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a.title)),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── Subscriptions ─────────────────────────────────────────
        const SectionLabel('Subscriptions & Recurring'),
        const SizedBox(height: 10),

        ...() {
          final subs = AiService.detectSubscriptions();
          final rec = AiService.detectRecurring();

          final all = [
            ...subs.map((s) => (s.name, s.emoji, s.amount, 'Sub')),
            ...rec
                .where((r) => !subs.any((s) => s.name == r.title))
                .map(
                  (r) => (
                    r.title,
                    r.emoji,
                    r.avgAmount,
                    '~${DateFormat('MMM d').format(r.nextEstimate)}',
                  ),
                ),
          ];

          if (all.isEmpty) {
            return [AppCard(child: Text('No recurring expenses'))];
          }

          return all.map((item) => AppCard(child: Text(item.$1)));
        }(),
      ],
    );
  }
}
