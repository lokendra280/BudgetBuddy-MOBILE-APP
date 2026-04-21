import 'dart:math' as math;

import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/onboard/ui/widgets/fact_bar_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/glass_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/mini_stat_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/ring_painter.dart';
import 'package:flutter/material.dart';

class AnalyseIllustration extends StatelessWidget {
  final double t;
  const AnalyseIllustration({required this.t});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final f1 = math.sin(t * math.pi) * 7;
    final f2 = math.sin(t * math.pi + math.pi) * 5;

    return Stack(
      children: [
        // ── Health score card ─────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.12 + f1,
          left: 20,
          right: 20,
          child: GlassWidget(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Score ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            painter: RingPainter(value: 0.78 + t * 0.02),
                            size: const Size(72, 72),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '78',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(0.55),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Health',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Good — keep improving 👍',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FactBarWidget(
                            'Savings',
                            0.72,
                            AppColors.primaryColor,
                          ),
                          const SizedBox(height: 5),
                          FactBarWidget(
                            'Budget',
                            0.85,
                            AppColors.secondaryColor,
                          ),
                          const SizedBox(height: 5),
                          FactBarWidget('Streak', 0.90, AppColors.yellow),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Burn rate card ────────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.40 + f2,
          left: 20,
          right: 20,
          child: GlassWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥  Burn Rate',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFB923C),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MiniStat('Rs. 890', 'Daily', kAccent),
                    Divider(),
                    MiniStat('26.7K', 'Monthly', kGreen),
                    Divider(),
                    MiniStat('47', 'Runway', kBlue),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── AI insight card ───────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.52 + f1 * 0.7,
          left: 20,
          right: 20,
          child: GlassWidget(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CommonSvgWidget(
                      svgName: Assets.ai,
                      width: 16,
                      height: 16,
                      color: AppColors.primaryColor,
                    ),
                    // child: Text('🤖', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Insight',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Food spending up ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                            const TextSpan(
                              text: '23%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kAccent,
                              ),
                            ),
                            TextSpan(
                              text: ' this month',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                          ],
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
    );
  }
}
