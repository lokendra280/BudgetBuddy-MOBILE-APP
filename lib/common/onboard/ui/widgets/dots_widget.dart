import 'package:flutter/material.dart';

class DotsWidget extends StatelessWidget {
  final int count, current;
  const DotsWidget({required this.count, required this.current});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      count,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(right: 6),
        width: i == current ? 22 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: i == current ? Colors.white : Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}
