import 'dart:math' as math;

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:flutter/material.dart';

// Onboarding illustrations, built from the same visual pieces as the app
// (deep-green balance card, white rows, piggy mascot, streak widget) so the
// first impression matches what users get after sign-up.
//
// Each illustration is laid out on a fixed 320×340 canvas and scaled to fit,
// so it looks the same on small and large phones. `t` (0→1→0, looping)
// drives a gentle float.

const _ink = Color(0xFF0F0F1A);
const _muted = Color(0xFF8A8AA3);

double _float(double t, [double phase = 0, double amp = 6]) =>
    math.sin((t + phase) * math.pi) * amp;

class _Canvas extends StatelessWidget {
  final List<Widget> children;
  const _Canvas({required this.children});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: 320,
      height: 340,
      child: Stack(clipBehavior: Clip.none, children: children),
    ),
  );
}

BoxDecoration _whiteCard([double r = 18]) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(r),
  boxShadow: [
    BoxShadow(
      color: kDeepGreen.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ],
);

BoxDecoration _greenCard([double r = 22]) => BoxDecoration(
  borderRadius: BorderRadius.circular(r),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kDeepGreen, kMidGreen],
  ),
  boxShadow: [
    BoxShadow(
      color: kDeepGreen.withValues(alpha: 0.30),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ],
);

/// Soft mint blob behind each illustration.
class _Blob extends StatelessWidget {
  const _Blob();
  @override
  Widget build(BuildContext context) => Positioned(
    left: 30,
    top: 40,
    child: Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.22),
            AppColors.primaryColor.withValues(alpha: 0.0),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. TRACK — balance card + transactions sliding in
// ─────────────────────────────────────────────────────────────────────────────

class TrackIllustration extends StatelessWidget {
  final double t;
  const TrackIllustration({super.key, required this.t});

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const _Blob(),
      // Balance card
      Positioned(
        left: 20,
        top: 30 + _float(t, 0, 4),
        child: Container(
          width: 280,
          height: 150,
          padding: const EdgeInsets.all(18),
          decoration: _greenCard(),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Savings',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rs 24,580',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _chip(Icons.south_west_rounded, 'Rs 50,000'),
                        const SizedBox(width: 8),
                        _chip(Icons.north_east_rounded, 'Rs 25,420'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Transactions
      Positioned(
        left: 34,
        top: 196 + _float(t, 0.3, 5),
        child: const _TxnRow(
          icon: Icons.shopping_cart_rounded,
          color: Color(0xFFF97316),
          title: 'Grocery Store',
          sub: 'Today, 10:24 AM',
          amount: '- Rs 450',
        ),
      ),
      Positioned(
        left: 14,
        top: 266 + _float(t, 0.6, 5),
        child: const _TxnRow(
          icon: Icons.account_balance_wallet_rounded,
          color: kGreen,
          title: 'Salary',
          sub: 'Today, 09:00 AM',
          amount: '+ Rs 50,000',
          income: true,
        ),
      ),
      // Piggy peeking
      Positioned(
        right: 6,
        top: 150 + _float(t, 0.15, 7),
        child: const PiggyMascot(size: 74),
      ),
    ],
  );

  static Widget _chip(IconData i, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(i, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          v,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _TxnRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub, amount;
  final bool income;
  const _TxnRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.amount,
    this.income = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: _whiteCard(16),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          amount,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: income ? kGreen : _ink,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. ANALYSE — spending chart + categories + health ring
// ─────────────────────────────────────────────────────────────────────────────

class AnalyseIllustration extends StatelessWidget {
  final double t;
  const AnalyseIllustration({super.key, required this.t});

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const _Blob(),
      // Chart card
      Positioned(
        left: 20,
        top: 24 + _float(t, 0, 4),
        child: Container(
          width: 280,
          height: 176,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: _whiteCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Spending',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
              const SizedBox(height: 2),
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Rs 12,406',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.south_rounded, size: 13, color: kGreen),
                    Text(
                      '8.2%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, h) in const [
                    0.45,
                    0.6,
                    0.38,
                    0.72,
                    0.5,
                    0.88,
                  ].indexed)
                    Container(
                      width: 22,
                      // bars "breathe" a little with t
                      height:
                          80 *
                          h *
                          (0.92 + 0.08 * math.sin((t + i * 0.2) * math.pi)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: i == 5
                            ? kMidGreen
                            : AppColors.primaryColor.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Categories card
      Positioned(
        left: 12,
        top: 218 + _float(t, 0.4, 5),
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(16),
          child: const Column(
            children: [
              _CatBar('Food & Dining', 0.72, Color(0xFFF97316)),
              SizedBox(height: 8),
              _CatBar('Transport', 0.45, Color(0xFF3B82F6)),
              SizedBox(height: 8),
              _CatBar('Shopping', 0.3, Color(0xFFEC4899)),
            ],
          ),
        ),
      ),
      // Health ring
      Positioned(
        right: 14,
        top: 214 + _float(t, 0.7, 6),
        child: Container(
          width: 104,
          height: 104,
          decoration: _greenCard(22),
          child: Center(
            child: SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 0.92,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6EE7B7)),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '92',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Health',
                        style: TextStyle(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _CatBar extends StatelessWidget {
  final String label;
  final double v;
  final Color color;
  const _CatBar(this.label, this.v, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${(v * 100).round()}%',
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 5,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. GROW — big piggy, streak, savings goal, home widget
// ─────────────────────────────────────────────────────────────────────────────

class GrowIllustration extends StatelessWidget {
  final double t;
  const GrowIllustration({super.key, required this.t});

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const _Blob(),
      // Big piggy
      Positioned(
        left: 90,
        top: 46 + _float(t, 0, 8),
        child: const PiggyMascot(size: 140),
      ),
      // Streak badge
      Positioned(
        left: 196,
        top: 30 + _float(t, 0.5, 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: _whiteCard(20),
          child: const Text(
            '🔥 12 days',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ),
      ),
      // Goal card
      Positioned(
        left: 10,
        top: 206 + _float(t, 0.3, 5),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kMint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 16,
                      color: kMidGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dream Vacation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          'Rs 34,000 / 80,000',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.42 + 0.04 * t,
                  minHeight: 6,
                  backgroundColor: kMint,
                  valueColor: const AlwaysStoppedAnimation(kMidGreen),
                ),
              ),
            ],
          ),
        ),
      ),
      // Mini home-screen widget
      Positioned(
        right: 12,
        top: 196 + _float(t, 0.65, 6),
        child: Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(10),
          decoration: _greenCard(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PiggyMascot(size: 36),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔥 12',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Nice work!',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                "You're on track",
                maxLines: 1,
                style: TextStyle(
                  fontSize: 8.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
