import 'package:expensetracker/ai_screen/services/ai_services.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = AiService.suggestions();
    final recurring = AiService.detectRecurring();
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
          'AI Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── AI header ──────────────────────────────────────────────────────
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, Color(0xFF9D8FFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Analysis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Based on your spending patterns',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Suggestions ────────────────────────────────────────────────────
          SectionLabel('Spending Suggestions'),
          const SizedBox(height: 12),

          if (suggestions.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    'Add more expenses',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'ll analyse your patterns once you log more.',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(s.color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            s.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
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

          const SizedBox(height: 20),

          // ── Recurring ──────────────────────────────────────────────────────
          SectionLabel('Recurring Expenses'),
          const SizedBox(height: 12),

          if (recurring.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    'No recurring detected yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We look for repeated expenses with similar amounts.',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...recurring.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            r.emoji,
                            style: const TextStyle(fontSize: 18),
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
                            const SizedBox(height: 2),
                            Text(
                              '${r.occurrences}x · avg ₹${r.avgAmount.toStringAsFixed(0)} · next ~${DateFormat('MMM d').format(r.nextEstimate)}',
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('🔄', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
