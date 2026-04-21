import 'package:expensetracker/common/onboard/ui/widgets/corner_painter.dart';
import 'package:flutter/material.dart';

class CornerWidget extends StatelessWidget {
  final bool top, left;
  const CornerWidget({required this.top, required this.left});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    height: 14,
    child: CustomPaint(
      painter: CornerPainter(top: top, left: left),
    ),
  );
}
