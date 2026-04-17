import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class HeaderButtonWidget extends StatelessWidget {
  final String l, v;
  final Color c;
  const HeaderButtonWidget(this.l, this.v, this.c, {super.key});
  @override
  Widget build(BuildContext ctx) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(l, style: TextStyle(fontSize: 10, color: ctx.c.textMuted)),
      const SizedBox(width: 6),
      Text(
        v,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    ],
  );
}
