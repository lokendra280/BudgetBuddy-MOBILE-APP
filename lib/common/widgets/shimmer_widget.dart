import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ── Base shimmer box ──────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width, height;
  final double radius;
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final base = context.isDark
        ? const Color(0xFF1C1C2A)
        : const Color(0xFFE8E8F0);
    final highlight = context.isDark
        ? const Color(0xFF2A2A3A)
        : const Color(0xFFF4F4FA);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ── Home screen shimmer ───────────────────────────────────────────────────────
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header shimmer
          Container(
            color: c.surface,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 18,
              20,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 80, height: 10, radius: 6),
                        const SizedBox(height: 6),
                        const ShimmerBox(width: 130, height: 18, radius: 6),
                      ],
                    ),
                    const ShimmerBox(width: 40, height: 40, radius: 20),
                  ],
                ),
                const SizedBox(height: 22),
                const ShimmerBox(width: 200, height: 38, radius: 8),
                const SizedBox(height: 6),
                const ShimmerBox(width: 110, height: 10, radius: 6),
                const SizedBox(height: 16),
                const ShimmerBox(width: double.infinity, height: 5, radius: 4),
              ],
            ),
          ),
          // Content shimmer
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Metric row
                Row(
                  children: [
                    Expanded(child: _CardShimmer(height: 88)),
                    const SizedBox(width: 10),
                    Expanded(child: _CardShimmer(height: 88)),
                  ],
                ),
                const SizedBox(height: 14),
                // Chart card
                _CardShimmer(height: 180),
                const SizedBox(height: 14),
                // Insight card
                _CardShimmer(height: 60),
                const SizedBox(height: 14),
                // Section label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(width: 80, height: 14, radius: 6),
                    const ShimmerBox(width: 70, height: 12, radius: 6),
                  ],
                ),
                const SizedBox(height: 12),
                // Transaction tiles
                ...List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TileShimmer(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  final double height;
  const _CardShimmer({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.c.border),
    ),
    padding: const EdgeInsets.all(14),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 100, height: 12, radius: 6),
          const SizedBox(height: 10),
          const ShimmerBox(width: 160, height: 20, radius: 6),
        ],
      ),
    ),
  );
}

class _TileShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final base = context.isDark
        ? const Color(0xFF1C1C2A)
        : const Color(0xFFE8E8F0);
    final high = context.isDark
        ? const Color(0xFF2A2A3A)
        : const Color(0xFFF4F4FA);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: high,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 12,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Statement shimmer ─────────────────────────────────────────────────────────
class StatementsShimmer extends StatelessWidget {
  const StatementsShimmer({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: SingleChildScrollView(
      child: Column(
        children: [
          const ShimmerBox(width: 180, height: 34, radius: 20),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 60, radius: 16),
          const SizedBox(height: 14),
          const ShimmerBox(width: double.infinity, height: 160, radius: 16),
          const SizedBox(height: 14),
          const ShimmerBox(width: double.infinity, height: 130, radius: 16),
          const SizedBox(height: 14),
          ...List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TileShimmer(),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Social screen shimmer ─────────────────────────────────────────────────────
class SocialShimmer extends StatelessWidget {
  const SocialShimmer({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(width: 160, height: 14, radius: 6),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 70, radius: 16),
        const SizedBox(height: 10),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerBox(width: double.infinity, height: 52, radius: 14),
          ),
        ),
      ],
    ),
  );
}

class LeaderboardShimmer extends StatelessWidget {
  const LeaderboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // ── My Card Shimmer ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const ShimmerBox(height: 40, width: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 12, width: 100),
                  SizedBox(height: 6),
                  ShimmerBox(height: 10, width: 140),
                ],
              ),
              const Spacer(),
              const ShimmerBox(height: 14, width: 60),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List items shimmer ──
        ...List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  ShimmerBox(height: 12, width: 20),
                  SizedBox(width: 8),
                  ShimmerBox(height: 36, width: 36),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 12, width: 100),
                      SizedBox(height: 6),
                      ShimmerBox(height: 10, width: 80),
                    ],
                  ),
                  Spacer(),
                  ShimmerBox(height: 12, width: 50),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
