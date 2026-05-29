import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/forecast/providers/forecast_provider.dart';
import 'package:budgetBuddy/features/insights/providers/insights_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InsightsFeedScreen extends ConsumerStatefulWidget {
  const InsightsFeedScreen({super.key});
  @override
  ConsumerState<InsightsFeedScreen> createState() => _State();
}

class _State extends ConsumerState<InsightsFeedScreen> {
  bool _forecastUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(insightsFeedProvider);
    final forecast = ref.watch(forecastProvider);
    final patterns = ref.watch(spendingPatternsProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daily Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
        children: [
          // ── Insight cards feed ──────────────────────────────────────────────
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightCard(card: card, fmt: fmt),
            ),
          ),

          const SizedBox(height: 6),
          const SectionLabel('Spending Patterns'),
          const SizedBox(height: 10),

          // ── Pattern cards ──────────────────────────────────────────────────
          if (patterns.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Add more expenses to detect patterns',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ...patterns.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.description,
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
          const SectionLabel('Next Month Forecast'),
          const SizedBox(height: 10),

          // ── Forecast — rewarded ad gate ────────────────────────────────────
          _forecastUnlocked
              ? AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔮', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fmt(forecast.predicted),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'predicted next month',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(forecast.confidence * 100).toInt()}% confidence',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        forecast.message,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      _ProgressRow(
                        '3-month avg',
                        forecast.avg3Month,
                        forecast.avg3Month,
                        fmt,
                      ),
                      const SizedBox(height: 6),
                      _ProgressRow(
                        'Predicted',
                        forecast.predicted,
                        forecast.avg3Month,
                        fmt,
                      ),
                    ],
                  ),
                )
              : _RewardedGate(
                  label: 'Unlock Expense Forecast',
                  subtitle: 'Watch a short ad to see next month\'s prediction',
                  onUnlock: () => ref
                      .read(adServiceProvider)
                      .showRewarded(
                        onRewarded: () =>
                            setState(() => _forecastUnlocked = true),
                      ),
                ),

          const SizedBox(height: 14),

          // ── Salary detection ───────────────────────────────────────────────
          Consumer(
            builder: (ctx, ref, _) {
              final incomes = ref.watch(salaryDetectionProvider);
              if (incomes.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Detected Income Sources'),
                  const SizedBox(height: 10),
                  ...incomes.map(
                    (inc) => Padding(
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
                                color: kGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '💰',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inc.source,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Detected income',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${fmt(inc.amount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightCard card;
  final String Function(double) fmt;
  const _InsightCard({required this.card, required this.fmt});

  static const _colors = {
    'alert': kAccent,
    'warn': kAmber,
    'good': kGreen,
    'info': AppColors.primaryColor,
    'forecast': AppColors.primaryColor,
    'pattern': kBlue,
  };

  @override
  Widget build(BuildContext context) {
    final col = _colors[card.type] ?? AppColors.primaryColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(card.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: col,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.c.textSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (card.value != null && card.value!.abs() > 0)
            Text(
              fmt(card.value!.abs()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: col,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value, max;
  final String Function(double) fmt;
  const _ProgressRow(this.label, this.value, this.max, this.fmt);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: context.c.textMuted),
          ),
          Text(
            fmt(value),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 3),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0,
          minHeight: 5,
          backgroundColor: context.c.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
        ),
      ),
    ],
  );
}

// Rewarded ad gate widget
class _RewardedGate extends StatelessWidget {
  final String label, subtitle;
  final VoidCallback onUnlock;
  const _RewardedGate({
    required this.label,
    required this.subtitle,
    required this.onUnlock,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Text('🔒', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: context.c.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onUnlock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Watch Ad & Unlock',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
