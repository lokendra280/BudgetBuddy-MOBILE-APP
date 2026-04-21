import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class CornerPainter extends CustomPainter {
  final bool top, left;
  const CornerPainter({required this.top, required this.left});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : s.width;
    final y = top ? 0.0 : s.height;
    c.drawLine(
      Offset(x, y),
      Offset(left ? s.width * 0.65 : s.width * 0.35, y),
      p,
    );
    c.drawLine(
      Offset(x, y),
      Offset(x, top ? s.height * 0.65 : s.height * 0.35),
      p,
    );
  }

  @override
  bool shouldRepaint(CornerPainter o) => false;
}
