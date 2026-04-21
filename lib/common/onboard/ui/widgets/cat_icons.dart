import 'dart:ui';
import 'package:flutter/material.dart';

class CatIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  const CatIcon(this.emoji, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color.withOpacity(0.22),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Center(child: Image.asset(emoji, width: 16, height: 16)),
  );
}
