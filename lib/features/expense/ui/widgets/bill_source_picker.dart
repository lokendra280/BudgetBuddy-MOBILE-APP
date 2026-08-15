// lib/expense/ui/widgets/bill_source_picker.dart
//
// Bottom sheet offering "Take Photo" vs "Choose from Gallery" before
// starting a bill scan. Call showBillSourcePicker(context) from the scan
// button instead of calling BillScanOrchestrator.start directly.

import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/expense/services/bill_scan_orchestrator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showBillSourcePicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _BillSourceSheet(),
  );
}

class _BillSourceSheet extends StatelessWidget {
  const _BillSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Scan a Bill',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Add expenses or income straight from a receipt photo.',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 18),
            _SourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Use the camera to scan a receipt now',
              onTap: () {
                HapticFeedback.selectionClick();
                // Navigator.pop(context);
                BillScanOrchestrator.start(context, fromCamera: true);
              },
            ),
            const SizedBox(height: 10),
            _SourceOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Pick an existing photo of a bill',
              onTap: () {
                HapticFeedback.selectionClick();
                // Navigator.pop(context);
                BillScanOrchestrator.start(context, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
