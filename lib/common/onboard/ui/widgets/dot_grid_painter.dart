import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(0.045);
    const spacing = 22.0;
    for (double x = 0; x < s.width; x += spacing) {
      for (double y = 0; y < s.height; y += spacing) {
        c.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter o) => false;
}
