import 'dart:math' as math;

import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class RingPainter extends CustomPainter {
  final double value;
  const RingPainter({required this.value});
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2, r = s.width / 2 - 5;
    final track = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primaryColor, AppColors.secondaryColor],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * value;
    c.drawCircle(Offset(cx, cy), r, track);
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      sweep,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(RingPainter o) => o.value != value;
}
