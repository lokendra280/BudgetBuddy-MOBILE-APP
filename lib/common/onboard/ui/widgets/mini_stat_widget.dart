import 'dart:ui';

import 'package:flutter/material.dart';

class MiniStat extends StatelessWidget {
  final String v, l;
  final Color c;
  const MiniStat(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          v,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c),
        ),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    ),
  );
}
