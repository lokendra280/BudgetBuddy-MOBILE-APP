import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:budgetbuddy/features/auth/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps the app when Face ID / biometric lock is on.
///
///  • Prompts on launch, and again when returning after > [_relockAfter]
///    in the background (so quick trips to the camera / share sheet don't
///    re-prompt every time).
///  • No "skip" — the system prompt already falls back to the device
///    passcode/PIN. If the device has no passcode or biometrics at all
///    (e.g. they were removed), the lock switches itself off instead of
///    locking the user out of their own data.
class LockScreen extends StatefulWidget {
  final Widget child; // shown after successful auth
  const LockScreen({super.key, required this.child});
  @override
  State<LockScreen> createState() => _State();
}

class _State extends State<LockScreen> with WidgetsBindingObserver {
  static const _relockAfter = Duration(seconds: 30);

  bool _unlocked = false;
  bool _checking = true;
  bool _authRunning = false;
  DateTime? _backgroundedAt;
  BiometricKind? _kind;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      final away = _backgroundedAt == null
          ? Duration.zero
          : DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (_unlocked && away > _relockAfter) {
        setState(() => _unlocked = false);
      }
      if (!_unlocked) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_unlocked) _tryAuth();
        });
      }
    }
  }

  Future<void> _init() async {
    final enabled = await BiometricService.isEnabled;
    if (!mounted) return;
    if (!enabled) {
      setState(() {
        _unlocked = true;
        _checking = false;
      });
      return;
    }
    final kind = await BiometricService.kind();
    if (!mounted) return;
    setState(() {
      _kind = kind;
      _checking = false;
    });
    await _tryAuth();
  }

  Future<void> _tryAuth() async {
    if (_authRunning) return;
    _authRunning = true;
    try {
      final ok = await BiometricService.authenticate(
        reason: 'Unlock BudgetBuddy',
      );
      if (!mounted) return;
      if (ok) {
        setState(() => _unlocked = true);
        return;
      }
      // Device has no passcode/biometrics any more → don't trap the user.
      final supported = await LocalAuthentication().isDeviceSupported();
      if (!supported) {
        await BiometricService.setEnabled(false);
        if (mounted) setState(() => _unlocked = true);
      }
    } catch (_) {
    } finally {
      _authRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(backgroundColor: context.c.bg);
    }
    if (_unlocked) return widget.child;

    final kind = _kind;
    final icon = kind?.icon ?? Icons.lock_outline_rounded;
    final method = kind?.title ?? 'passcode';

    return Scaffold(
      backgroundColor: context.c.bg,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDark
                ? [kDeepGreen.withValues(alpha: 0.4), context.c.bg]
                : [kMint, context.c.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const PiggyMascot(size: 110),
              const SizedBox(height: 20),
              Text('BudgetBuddy is locked', style: context.t.h2),
              const SizedBox(height: 6),
              Text(
                'Your finances stay private.',
                style: context.t.bodySub,
              ),
              const Spacer(flex: 2),
              GestureDetector(
                onTap: _tryAuth,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kDeepGreen, kMidGreen],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kDeepGreen.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Text('Unlock with $method', style: context.t.labelLarge),
              const SizedBox(height: 4),
              Text(
                'Your device passcode works too',
                style: context.t.labelMuted,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
