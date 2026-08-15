// lib/expense/services/bill_scan_orchestrator.dart
//
// Glue code: picks the image, shows the scanning animation while Gemini
// processes it, then navigates to the review screen. Call
// BillScanOrchestrator.start(context) from wherever you want the "Scan
// Bill" entry point — e.g. a button on AddExpenseScreen or the Dashboard.

import 'dart:async';
import 'dart:io';
import 'package:budgetBuddy/common/services/ads_service.dart';

import 'package:budgetBuddy/features/expense/services/bill_scaning_service.dart';
import 'package:budgetBuddy/features/expense/ui/bill_scan_review_screen.dart';
import 'package:budgetBuddy/features/expense/ui/widgets/bill_scanning_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillScanOrchestrator {
  static Future<void> start(
    BuildContext context, {
    bool fromCamera = true,
  }) async {
    File? image;
    // Rewarded ads take a moment to load — start preloading as soon as the
    // user commits to scanning, so it's ready by the time the scan
    // finishes (rather than starting the load only after the scan, which
    // would often mean no ad is ready yet and it silently gets skipped).
    final adService = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adServiceProvider);
    adService.preloadRewarded();

    try {
      image = await GeminiBillScanService.pickImage(fromCamera: fromCamera);
    } on BillScanException catch (e) {
      _showError(context, e.message);
      return;
    }

    if (image == null || !context.mounted) return; // user cancelled picker

    // Show the scanning overlay as a dialog-like full-screen route while
    // the Gemini request runs in the background.
    bool overlayDismissed = false;

    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => BillScanningOverlay(image: image!),
        ),
      ),
    );

    try {
      final result = await GeminiBillScanService.scanImage(image);

      if (!context.mounted) return;
      overlayDismissed = true;
      Navigator.of(context).pop(); // close scanning overlay

      // Scan succeeded — show the rewarded ad here, once, before the
      // review screen. Fire-and-forget: doesn't block navigation, and
      // proceeds to review regardless of whether an ad was available or
      // the user watched it to completion.
      adService.showRewarded(onRewarded: () {}, onNotAvailable: () {});

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BillScanReviewScreen(result: result)),
      );
    } on BillScanException catch (e) {
      if (!overlayDismissed && context.mounted) Navigator.of(context).pop();
      if (context.mounted) _showError(context, e.message);
    } catch (e) {
      if (!overlayDismissed && context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        _showError(context, 'Something went wrong while scanning.');
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
