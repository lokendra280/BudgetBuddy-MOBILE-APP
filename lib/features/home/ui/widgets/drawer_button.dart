import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:flutter/material.dart';

class DrawsButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const DrawsButton(this.icon, this.label, this.color, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CommonSvgWidget(
      svgName: icon,
      color: color ?? context.c.textSub,
      height: 20,
      width: 20,
    ),
    title: Text(label, style: const TextStyle(fontSize: 14)),
    onTap: onTap,
    dense: true,
    visualDensity: const VisualDensity(horizontal: -3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
