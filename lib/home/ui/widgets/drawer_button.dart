import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class DrawsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const DrawsButton(this.icon, this.label, this.color, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? context.c.textSub, size: 22),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
    dense: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
