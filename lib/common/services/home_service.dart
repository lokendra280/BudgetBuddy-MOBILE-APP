import 'dart:ui';

import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AddWidgetGuideSheet extends StatelessWidget {
  const AddWidgetGuideSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final steps = [
      ('1', l10n.addWidgetStep1),
      ('2', l10n.addWidgetStep2),
      ('3', l10n.addWidgetStep3),
      ('4', l10n.addWidgetStep4),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.widgets_rounded,
              size: 40,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addWidgetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.addWidgetDesc,
              style: const TextStyle(fontSize: 13, color: Color(0xFF606080)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        step.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F0F1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.gotIt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
