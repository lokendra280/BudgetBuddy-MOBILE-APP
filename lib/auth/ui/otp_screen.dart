import 'dart:async';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/dashboard/pages/dashboard_page.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _State();
}

class _State extends State<OtpScreen> {
  // 6 individual controllers + focus nodes for each digit box
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focuses = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focuses[0].requestFocus(),
    );
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
        return;
      }
      if (mounted) setState(() => _resendSeconds--);
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // ── Handle each keystroke ────────────────────────────────────────────────────
  void _onChanged(int idx, String val) {
    if (val.length > 1) {
      // Handle paste — distribute across boxes
      final digits = val.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focuses[5].requestFocus();
      if (_otp.length == 6) _verify();
      return;
    }
    if (val.isNotEmpty && idx < 5) _focuses[idx + 1].requestFocus();
    if (val.isNotEmpty && idx == 5) {
      _focuses[5].unfocus();
      _verify();
    }
  }

  void _onBackspace(int idx) {
    if (_controllers[idx].text.isEmpty && idx > 0) {
      _controllers[idx - 1].clear();
      _focuses[idx - 1].requestFocus();
    }
  }

  // ── Verify ───────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.verifyOtp(widget.email, _otp);
      await SyncService.migrateOnFirstLogin();
      if (!mounted) return;
      // Show success snack then navigate
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
    } catch (e) {
      setState(() {
        _error = 'Invalid code. Please check and try again.';
        // Clear boxes on wrong OTP
        for (final c in _controllers) c.clear();
      });
      _focuses[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Resend ───────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await AuthService.sendOtp(widget.email);
      _startResendTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      setState(() => _error = 'Failed to resend. Please try again.');
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
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

            // ── OTP Boxes ───────────────────────────────────────────────────────
            Row(
              children: List.generate(6, (i) {
                final gap = i == 2 ? 16.0 : 8.0; // visual gap in middle
                return Padding(
                  padding: EdgeInsets.only(right: gap),
                  child: _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focuses[i],
                    onChanged: (v) => _onChanged(i, v),
                    onBackspace: () => _onBackspace(i),
                  ),
                );
              }),
            ),

            // ── Error ──────────────────────────────────────────────────────────
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

            // ── Verify button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
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

            // ── Resend ─────────────────────────────────────────────────────────
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
                'Check your spam folder if you don\'t see it.',
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: c.card,
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
      ),
    );
  }
}
