// score_animation_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AwesomeScoreWidget extends StatefulWidget {
  final dynamic score;
  const AwesomeScoreWidget({super.key, required this.score});

  @override
  State<AwesomeScoreWidget> createState() => _AwesomeScoreWidgetState();
}

class _AwesomeScoreWidgetState extends State<AwesomeScoreWidget>
    with TickerProviderStateMixin {
  // Ring fill
  late final AnimationController _ringCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _ringAnim = CurvedAnimation(
    parent: _ringCtrl,
    curve: Curves.easeOutCubic,
  );

  // Pulse glow that breathes after ring completes
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _pulseAnim = CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.easeInOut,
  );

  // Score number count-up
  late final AnimationController _countCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<int> _countAnim = IntTween(
    begin: 0,
    end: widget.score.score,
  ).animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic));

  // Grade pop scale
  late final AnimationController _gradeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _gradeScale = CurvedAnimation(
    parent: _gradeCtrl,
    curve: Curves.easeOutBack,
  );

  // Particle burst
  late final AnimationController _particleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Shimmer sweep on the ring
  late final AnimationController _shimmerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    // 1. Ring fills + count-up simultaneously
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _countCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _shimmerCtrl.forward();

    // 2. When ring is 80% done → burst particles + grade pop
    await Future.delayed(const Duration(milliseconds: 750));
    setState(() => _showParticles = true);
    _particleCtrl.forward();
    _gradeCtrl.forward();

    // 3. After burst → gentle pulse loop
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _countCtrl.dispose();
    _gradeCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.score.color as Color;
    final double targetFraction = widget.score.score / 100.0;

    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ringAnim,
          _pulseAnim,
          _countAnim,
          _gradeScale,
          _particleCtrl,
          _shimmerCtrl,
        ]),
        builder: (context, _) {
          final ring = _ringAnim.value;
          final pulse = _pulseAnim.value;
          final shimmer = _shimmerCtrl.value;
          final gradeScale = _gradeScale.value;
          final count = _countAnim.value;
          final pProgress = _particleCtrl.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer glow ring (pulse) ───────────────────────────────────
              if (_pulseCtrl.isAnimating || _pulseCtrl.value > 0)
                Container(
                  width: 90 + 18 * pulse,
                  height: 90 + 18 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25 * pulse),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // ── Background track ring ─────────────────────────────────────
              CustomPaint(
                size: const Size(90, 90),
                painter: _RingPainter(
                  progress: ring * targetFraction,
                  color: color,
                  shimmer: shimmer,
                  trackColor: color.withOpacity(0.10),
                  strokeWidth: 9,
                ),
              ),

              // ── Particles burst ───────────────────────────────────────────
              if (_showParticles)
                CustomPaint(
                  size: const Size(90, 90),
                  painter: _ParticlePainter(
                    progress: pProgress,
                    color: color,
                    score: widget.score.score,
                  ),
                ),

              // ── Center content ────────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Count-up number
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Grade — pops in with bounce scale
                  Transform.scale(
                    scale: gradeScale,
                    child: Text(
                      widget.score.grade as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Ring painter with shimmer sweep ──────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;
  final double strokeWidth, shimmer;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Gradient arc
    final sweepAngle = math.pi * 2 * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withOpacity(0.6),
        color,
        Color.lerp(color, Colors.white, 0.35)!,
        color,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Shimmer spark at the tip
    if (shimmer > 0 && shimmer < 1) {
      final sparkAngle = startAngle + sweepAngle * math.min(shimmer * 1.2, 1.0);
      final sparkX = center.dx + radius * math.cos(sparkAngle);
      final sparkY = center.dy + radius * math.sin(sparkAngle);
      final sparkOpacity = (math.sin(shimmer * math.pi)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(sparkX, sparkY),
        strokeWidth / 2 + 2,
        Paint()
          ..color = Colors.white.withOpacity(sparkOpacity * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Tip dot
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    canvas.drawCircle(
      Offset(tipX, tipY),
      strokeWidth / 2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.shimmer != shimmer;
}

// ── Particle burst painter ────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int score;

  const _ParticlePainter({
    required this.progress,
    required this.color,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final rng = math.Random(score); // deterministic so no flicker
    final count = 10 + (score / 10).round(); // more particles for higher score
    final fade = (1.0 - progress).clamp(0.0, 1.0);
    final spread = 50.0 * progress;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + rng.nextDouble() * 0.4;
      final dist = spread * (0.6 + rng.nextDouble() * 0.5);
      final radius = (2.0 + rng.nextDouble() * 2.5) * fade;
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final alpha = (fade * (0.5 + rng.nextDouble() * 0.5)).clamp(0.0, 1.0);

      // Alternate between solid dots and hollow rings
      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(px, py),
          radius,
          Paint()..color = Colors.white.withOpacity(alpha * 0.9),
        );
      } else {
        canvas.drawCircle(
          Offset(px, py),
          radius,
          Paint()
            ..color = color.withOpacity(alpha)
            ..style = i % 2 == 0 ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.progress != progress;
}
