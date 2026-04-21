import 'dart:math' as math;

import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard/ui/widgets/glass_widget.dart';
import 'package:flutter/material.dart';

class GrowIllustrationWidget extends StatelessWidget {
  final double t;
  const GrowIllustrationWidget({required this.t});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final f1 = math.sin(t * math.pi) * 7;
    final f2 = math.sin(t * math.pi + math.pi) * 6;

    return Stack(
      children: [
        // ── Trophy + Streak row ───────────────────────────────────────────────
        Positioned(
          top: size.height * 0.12 + f1,
          left: 20,
          right: 20,
          child: Row(
            children: [
              // Trophy card
              Expanded(
                child: GlassWidget(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🏆', style: TextStyle(fontSize: 28)),
                      SizedBox(height: 5),
                      Text(
                        'Top Saver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'This month',
                        style: TextStyle(fontSize: 9, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryColor, Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 26)),
                    SizedBox(height: 4),
                    Text(
                      '14 day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'streak',
                      style: TextStyle(fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Savings goal card ─────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.30 + f2,
          left: 20,
          right: 20,
          child: GlassWidget(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.4),
                        ),
                      ),
                      child: const Center(
                        child: Text('✈️', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thailand Trip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '45 days left · Save Rs. 720/day',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: 0.68 + t * 0.04,
                    minHeight: 9,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${((0.68 + t * 0.04) * 100).toInt()}% saved',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    Text(
                      'Rs.68K / Rs.1L',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        size: 13,
                        color: AppColors.secondaryColor,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Save Rs. 720/day to hit your goal',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Leaderboard card ──────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.54 + f1 * 0.6,
          left: 20,
          right: 20,
          child: GlassWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏅  Leaderboard',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  ('🥇', 'Aarav S.', 'Rs. 12K', false),
                  ('🥈', 'You', 'Rs. 15K', true),
                  ('🥉', 'Priya M.', 'Rs. 18K', false),
                ].map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text(e.$1, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          e.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: e.$4
                                ? AppColors.secondaryColor
                                : Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          e.$3,
                          style: TextStyle(
                            fontSize: 10,
                            color: e.$4
                                ? AppColors.secondaryColor
                                : Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
