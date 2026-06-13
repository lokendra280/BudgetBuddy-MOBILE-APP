import 'dart:async';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetBuddy/features/home/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focuses = List.generate(6, (_) => FocusNode());

  bool _resending = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;

  // ── loading comes from provider, not local state ──────────────────
  bool get _loading => ref.read(authProvider).isLoading;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focuses[0].requestFocus(),
    );
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // ── Keystroke handling ────────────────────────────────────────────
  void _onChanged(int idx, String val) {
    if (val.length > 1) {
      // Paste
      final digits = val.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focuses[5].requestFocus();
      if (_otp.length == 6) _verify();
      return;
    }

    if (val.isEmpty) {
      // ← Backspace: move to previous box
      _onBackspace(idx);
      return;
    }

    // Forward: move to next box
    if (idx < 5) {
      _focuses[idx + 1].requestFocus();
    } else {
      _focuses[5].unfocus();
      if (_otp.length == 6) _verify();
    }
  }

  void _onBackspace(int idx) {
    if (_controllers[idx].text.isEmpty && idx > 0) {
      _controllers[idx - 1].clear();
      _focuses[idx - 1].requestFocus();
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focuses[0].requestFocus();
  }

  // ── Verify via provider ───────────────────────────────────────────
  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() => _error = null);

    final err = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.email, _otp);

    if (!mounted) return;

    // ── Check actual auth state, not just the error string ───────────
    // verifyOtp may return an error string but Supabase still logged in
    final isLoggedIn = ref.read(isLoggedInProvider);

    debugPrint('[OTP] verifyOtp error: $err | isLoggedIn: $isLoggedIn');

    if (!isLoggedIn) {
      // Truly failed — user is not logged in
      setState(() => _error = 'Invalid or expired code. Please try again.');
      _clearBoxes();
      return;
    }

    // ── User is logged in — proceed regardless of err string ─────────
    await ref.read(syncProvider.notifier).sync();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Signed in successfully!'),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (_) => false,
    );
  }

  // ── Resend via provider ───────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).sendOtp(widget.email);
      _startResendTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent! Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final secs = RegExp(r'(\d+)\s*seconds?').firstMatch(msg)?.group(1);
      setState(
        () => _error = secs != null
            ? 'Please wait $secs seconds before requesting a new code.'
            : 'Failed to resend. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // ✅ Watch provider for loading state — rebuilds button automatically
    final loading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ──────────────────────────────────────────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text('📧', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────
            const Text(
              'Enter verification code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to\n'),
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                      color: context.isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── OTP boxes ─────────────────────────────────────────
            LayoutBuilder(
              builder: (_, constraints) {
                final boxSize = ((constraints.maxWidth - 5 * 10 - 8) / 6).clamp(
                  40.0,
                  54.0,
                );
                return Row(
                  children: List.generate(
                    6,
                    (i) => Padding(
                      padding: EdgeInsets.only(
                        right: i == 5 ? 0 : (i == 2 ? 18 : 10),
                      ),
                      child: _OtpBox(
                        size: boxSize,
                        controller: _controllers[i],
                        focusNode: _focuses[i],
                        onChanged: (v) => _onChanged(i, v),
                        onBackspace: () => _onBackspace(i),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Error ─────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: kAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: kAccent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // ── Verify button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryColor.withOpacity(
                    0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify & Sign in',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Resend ────────────────────────────────────────────
            Center(
              child: _resending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.textMuted,
                      ),
                    )
                  : GestureDetector(
                      onTap: _resendSeconds == 0 ? _resend : null,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                          children: [
                            const TextSpan(text: "Didn't receive the code? "),
                            TextSpan(
                              text: _resendSeconds > 0
                                  ? 'Resend in ${_resendSeconds}s'
                                  : 'Resend',
                              style: TextStyle(
                                color: _resendSeconds > 0
                                    ? c.textMuted
                                    : AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                                decoration: _resendSeconds == 0
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "Check your spam folder if you don't see it.",
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── OTP digit box ─────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: size,
      height: size + 14,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,

        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: size * 0.45, // ← scales with box size
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor, // ← explicit text color
          height: 1,
        ),
        onChanged: onChanged,
        // ── Backspace via onChanged when empty ─────────────────────
        // KeyboardListener is removed — it blocked character display
        // on Android soft keyboard. Backspace is handled in parent
        // via onChanged: if val is empty and box was already empty → go back.
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero, // ← center digit vertically
          filled: true,
          fillColor: focusNode.hasFocus
              ? AppColors.primaryColor.withOpacity(0.06)
              : c.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
