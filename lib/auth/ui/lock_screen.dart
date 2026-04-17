import 'package:expensetracker/auth/services/biometric_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class LockScreen extends StatefulWidget {
  final Widget child; // shown after successful auth
  const LockScreen({super.key, required this.child});
  @override
  State<LockScreen> createState() => _State();
}

class _State extends State<LockScreen> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _checking = true;

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

  // Re-lock when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _unlocked = false;
    }

    if (state == AppLifecycleState.resumed && !_unlocked) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_unlocked) {
          _tryAuth();
        }
      });
    }
  }

  Future<void> _init() async {
    bool enabled = false;

    try {
      enabled = await BiometricService.isEnabled;
    } catch (_) {
      enabled = false;
    }

    if (!mounted) return;

    if (!enabled) {
      setState(() {
        _unlocked = true;
        _checking = false;
      });
      return;
    }

    setState(() => _checking = false);

    await _tryAuth();
  }

  bool _authRunning = false;

  Future<void> _tryAuth() async {
    if (_authRunning) return;
    _authRunning = true;

    try {
      final ok = await BiometricService.authenticate();
      if (!mounted) return;
      setState(() => _unlocked = ok);
    } catch (_) {}

    _authRunning = false;
  }

  void _skip() => setState(() => _unlocked = true);

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_unlocked) return widget.child;

    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryColor, Color(0xFF9D8FFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💸', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'SpendSense',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your identity to continue',
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),
              const SizedBox(height: 48),
              // Biometric button
              GestureDetector(
                onTap: _tryAuth,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 38,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Touch to authenticate',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    decoration: TextDecoration.underline,
                    decorationColor: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
