// lib/expense/widgets/scan_frame_overlay.dart
import 'package:flutter/material.dart';

/// A Paytm/QR-scanner style overlay: four corner brackets plus a glowing
/// line that sweeps top-to-bottom while [isScanning] is true. Stack this
/// on top of a preview image.
class ScanFrameOverlay extends StatefulWidget {
  final bool isScanning;
  final Color color;
  final double cornerLength;
  final double cornerThickness;
  final double borderRadius;

  const ScanFrameOverlay({
    super.key,
    required this.isScanning,
    this.color = Colors.greenAccent,
    this.cornerLength = 28,
    this.cornerThickness = 4,
    this.borderRadius = 16,
  });

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isScanning) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ScanFrameOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                opacity: widget.isScanning ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(color: Colors.black.withOpacity(0.15)),
              ),
              ..._buildCorners(),
              if (widget.isScanning)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final top = (constraints.maxHeight - 3) * _controller.value;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(0),
                              widget.color,
                              widget.color.withOpacity(0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCorners() {
    Widget corner({
      required Alignment alignment,
      required bool flipH,
      required bool flipV,
    }) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
            child: CustomPaint(
              size: Size(widget.cornerLength, widget.cornerLength),
              painter: _CornerPainter(
                color: widget.color,
                thickness: widget.cornerThickness,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft, flipH: false, flipV: false),
      corner(alignment: Alignment.topRight, flipH: true, flipV: false),
      corner(alignment: Alignment.bottomLeft, flipH: false, flipV: true),
      corner(alignment: Alignment.bottomRight, flipH: true, flipV: true),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thickness != thickness;
}
