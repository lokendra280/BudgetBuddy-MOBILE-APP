import 'dart:io';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/sms_service/services/sms_auto_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Only used for modal (splash) — tracks if dialog was shown once
const _kAskedKey = 'sms_permission_asked';

class SmsPermissionGuard extends StatefulWidget {
  final bool modal;
  final Widget child;
  final Future<void> Function()? onSyncRequested;

  const SmsPermissionGuard({
    super.key,
    required this.child,
    this.modal = false,
    this.onSyncRequested,
  });

  @override
  State<SmsPermissionGuard> createState() => _SmsPermissionGuardState();
}

class _SmsPermissionGuardState extends State<SmsPermissionGuard> {
  bool _showPrompt = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.isIOS) _checkShouldShow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check every time widget re-enters the tree
    // (e.g. returning from settings or navigating back to home)
    if (!Platform.isIOS) _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    final status = await Permission.sms.status;

    // Permission already granted — never show
    if (status.isGranted) {
      if (mounted && _showPrompt) setState(() => _showPrompt = false);
      return;
    }

    if (widget.modal) {
      // Modal (splash): show only once on first launch
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool(_kAskedKey) ?? false;
      if (mounted) setState(() => _showPrompt = !alreadyAsked);
    } else {
      // Banner (home): show every app open until permission granted
      // Tapping × only hides for current session — never permanently
      if (mounted) setState(() => _showPrompt = true);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAskedKey, true);

    final status = await Permission.sms.request();

    if (status.isGranted) {
      // ── Just enable the flag + set 30-day window ─────────────────────────
      // Do NOT call onPermissionGranted() with no-op here — it would
      // update the sync timestamp before the real sync runs, skipping data
      await prefs.setBool('sms_permission_granted', true);
      await prefs.setBool('sms_auto_sync_enabled', true);
      final firstSyncFrom = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      await prefs.setInt('sms_last_sync_ms', firstSyncFrom);

      // ── Now run real sync via caller which has Riverpod access ───────────
      await widget.onSyncRequested?.call();

      if (mounted) setState(() => _showPrompt = false);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      await _checkShouldShow();
    } else {
      if (mounted) setState(() => _showPrompt = true);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _dismiss() {
    // Hide for this session only — no SharedPreferences write
    // Next app open: didChangeDependencies runs → _checkShouldShow → shows again
    if (mounted) setState(() => _showPrompt = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showPrompt) return widget.child;

    if (widget.modal) {
      return Stack(
        children: [
          widget.child,
          _SmsDialog(
            loading: _loading,
            onAllow: _requestPermission,
            onSkip: _dismiss,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmsBanner(
          loading: _loading,
          onAllow: _requestPermission,
          onDismiss: _dismiss, // session-only hide
        ),
        widget.child,
      ],
    );
  }
}

class _SmsDialog extends StatelessWidget {
  final bool loading;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _SmsDialog({
    required this.loading,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: context.c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.c.border),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: AppColors.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Auto-import bank SMS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'BudgetBuddy reads your bank messages to track expenses automatically — no manual entry needed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.c.textMuted,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...[
                  ('🏦', 'Supports 20+ banks — Nepal, India, UK & US'),
                  ('🔒', 'Processed on-device, never sent to any server'),
                  ('⚡', 'Imports last 30 days instantly on first enable'),
                  ('🔄', 'Syncs silently on every app open after that'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.c.textSub,
                              height: 1.4,
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
                    onPressed: loading ? null : onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Allow SMS Access',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: loading ? null : onSkip,
                  child: Text(
                    'Not now',
                    style: TextStyle(fontSize: 13, color: context.c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmsBanner extends StatelessWidget {
  final bool loading;
  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  const _SmsBanner({
    required this.loading,
    required this.onAllow,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sms_outlined,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-import bank SMS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Track expenses automatically from your bank messages.',
                  style: TextStyle(fontSize: 11, color: context.c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onAllow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 18, color: context.c.textMuted),
          ),
        ],
      ),
    );
  }
}
