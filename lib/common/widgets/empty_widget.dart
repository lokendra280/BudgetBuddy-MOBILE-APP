import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'No bills added yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add bills, EMIs and subscriptions to\nget reminded before they\'re due.',
            style: TextStyle(
              fontSize: 13,
              color: context.c.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Add First Bill',
            onTap: onAdd,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    ),
  );
}
