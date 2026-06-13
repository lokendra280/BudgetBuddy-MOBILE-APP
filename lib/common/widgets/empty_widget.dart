import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
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
          Text(
            AppLocalizations.of(context)!.noBillsAdded,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addBills,
            style: TextStyle(
              fontSize: 13,
              color: context.c.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: AppLocalizations.of(context)!.addFirstBill,
            onTap: onAdd,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    ),
  );
}
