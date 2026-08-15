// lib/expense/ui/widgets/bill_scanning_overlay.dart
//
// Full-screen scanning animation shown while Gemini processes the photo:
// the captured image with a glowing horizontal line sweeping top-to-
// bottom on a loop, framed by viewfinder-style corner brackets — the
// same visual language Paytm/GPay use for their bill/QR scan states.

import 'dart:io';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:flutter/material.dart';

class BillScanningOverlay extends StatefulWidget {
  final File image;
  final String label;

  const BillScanningOverlay({
    super.key,
    required this.image,
    this.label = 'Reading your bill...',
  });

  @override
  State<BillScanningOverlay> createState() => _BillScanningOverlayState();
}

class _BillScanningOverlayState extends State<BillScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _ScanFrame(
                      controller: _controller,
                      image: widget.image,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final dots = '.' * (1 + (_controller.value * 3).floor());
                return Text(
                  '${widget.label}$dots',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Hold still',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final AnimationController controller;
  final File image;

  const _ScanFrame({required this.controller, required this.image});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(image, fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.15)),

              // Sweeping scan line with a soft glow gradient above/below it.
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final y = controller.value * constraints.maxHeight;
                  return Positioned(
                    top: y - 40,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryColor.withOpacity(0.0),
                            AppColors.primaryColor.withOpacity(0.55),
                            AppColors.primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final y = controller.value * constraints.maxHeight;
                  return Positioned(
                    top: y,
                    left: 0,
                    right: 0,
                    child: Container(height: 2, color: AppColors.primaryColor),
                  );
                },
              ),

              // Corner brackets, viewfinder-style.
              const _CornerBrackets(),
            ],
          ),
        );
      },
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    const thickness = 3.0;
    const inset = 12.0;
    final color = Colors.white.withOpacity(0.85);

    Widget corner({required bool top, required bool left}) => Positioned(
      top: top ? inset : null,
      bottom: top ? null : inset,
      left: left ? inset : null,
      right: left ? null : inset,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(
            top: top,
            left: left,
            color: color,
            thickness: thickness,
          ),
        ),
      ),
    );

    return Stack(
      children: [
        corner(top: true, left: true),
        corner(top: true, left: false),
        corner(top: false, left: true),
        corner(top: false, left: false),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // The corner point itself, e.g. top-left corner is (0,0).
    final cornerX = left ? 0.0 : size.width;
    final cornerY = top ? 0.0 : size.height;

    // Horizontal arm: from the corner, extending inward along the width.
    final horizontalEndX = left ? size.width : 0.0;
    canvas.drawLine(
      Offset(cornerX, cornerY),
      Offset(horizontalEndX, cornerY),
      paint,
    );

    // Vertical arm: from the corner, extending inward along the height.
    final verticalEndY = top ? size.height : 0.0;
    canvas.drawLine(
      Offset(cornerX, cornerY),
      Offset(cornerX, verticalEndY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
