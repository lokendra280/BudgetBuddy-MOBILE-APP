import 'package:flutter/material.dart';

/// The BudgetBuddy piggy mascot, drawn in code.
///
/// Same 100×100 geometry as the native home-screen widgets
/// (ios/StreakWidget/StreakWidget.swift and android res/drawable/piggy_*.xml),
/// so in-app previews match what users get on their home screen.
enum PiggyMood { happy, worried, sad }

class PiggyMascot extends StatelessWidget {
  final PiggyMood mood;
  final double size;
  const PiggyMascot({super.key, this.mood = PiggyMood.happy, this.size = 64});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PiggyPainter(mood)),
  );
}

class _PiggyPainter extends CustomPainter {
  final PiggyMood mood;
  _PiggyPainter(this.mood);

  static const _ink = Color(0xFF0E4A30);
  static const _body = Color(0xFFC8EFD9);
  static const _snout = Color(0xFF9BDDB8);
  static const _water = Color(0xFF7DD3FC);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(double w, [Color c = _ink]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Rect ell(double cx, double cy, double rx, double ry) =>
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    Path tri(List<double> p) => Path()
      ..moveTo(p[0], p[1])
      ..lineTo(p[2], p[3])
      ..lineTo(p[4], p[5])
      ..close();
    Path quad(
      double x1,
      double y1,
      double cx,
      double cy,
      double x2,
      double y2,
    ) => Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(cx, cy, x2, y2);

    // Ears
    for (final ear in [
      tri([18, 32, 27, 8, 44, 24]),
      tri([82, 32, 73, 8, 56, 24]),
    ]) {
      canvas.drawPath(ear, fill(_body));
      canvas.drawPath(ear, stroke(2.5));
    }

    // Head
    canvas.drawOval(ell(50, 56, 36, 36), fill(_body));
    canvas.drawOval(ell(50, 56, 36, 36), stroke(2.5));

    // Cheeks + eyes
    if (mood == PiggyMood.happy) {
      final blush = fill(const Color(0xFFF9A8D4).withValues(alpha: 0.8));
      canvas.drawOval(ell(26, 62, 6, 5), blush);
      canvas.drawOval(ell(74, 62, 6, 5), blush);
      canvas.drawPath(quad(30, 47, 36, 38, 42, 47), stroke(3.5));
      canvas.drawPath(quad(58, 47, 64, 38, 70, 47), stroke(3.5));
    } else {
      canvas.drawOval(ell(36, 46, 4, 4.5), fill(_ink));
      canvas.drawOval(ell(64, 46, 4, 4.5), fill(_ink));
      canvas.drawLine(const Offset(29, 38), const Offset(41, 34), stroke(2.5));
      canvas.drawLine(const Offset(71, 38), const Offset(59, 34), stroke(2.5));
    }

    // Snout
    canvas.drawOval(ell(50, 65, 15, 11), fill(_snout));
    canvas.drawOval(ell(50, 65, 15, 11), stroke(2.5));
    canvas.drawOval(ell(44.5, 65, 2.5, 4), fill(_ink));
    canvas.drawOval(ell(55.5, 65, 2.5, 4), fill(_ink));

    // Mouth + extras
    switch (mood) {
      case PiggyMood.happy:
        canvas.drawPath(quad(42, 81, 50, 89, 58, 81), stroke(3.5));
        canvas.drawOval(ell(88, 16, 8, 8), fill(const Color(0xFFFCD34D)));
        canvas.drawOval(
          ell(88, 16, 8, 8),
          stroke(1.5, const Color(0xFFB45309)),
        );
        canvas.drawOval(
          ell(88, 16, 3.5, 3.5),
          stroke(1.2, const Color(0xFFB45309)),
        );
      case PiggyMood.worried:
        canvas.drawPath(
          Path()
            ..moveTo(41, 83)
            ..quadraticBezierTo(45.5, 79, 50, 83)
            ..quadraticBezierTo(54.5, 87, 59, 83),
          stroke(3.5),
        );
        canvas.drawPath(
          Path()
            ..moveTo(86, 28)
            ..quadraticBezierTo(93, 38, 86, 42)
            ..quadraticBezierTo(79, 38, 86, 28),
          fill(_water),
        );
      case PiggyMood.sad:
        canvas.drawPath(quad(42, 86, 50, 78, 58, 86), stroke(3.5));
        canvas.drawPath(
          Path()
            ..moveTo(34, 52)
            ..quadraticBezierTo(40, 61, 34, 64)
            ..quadraticBezierTo(28, 61, 34, 52),
          fill(_water),
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PiggyPainter old) => old.mood != mood;
}
