import 'package:flutter/material.dart';

class GlassWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassWidget({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.09),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}
