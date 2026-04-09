import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/otp_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  // ── Send OTP ────────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.sendOtp(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } catch (e) {
      setState(
        () => _error = 'Failed to send code. Check your email and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      final res = await AuthService.signInWithGoogle();
      if (res == null) {
        setState(() => _googleLoading = false);
        return;
      }
      await SyncService.migrateOnFirstLogin();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  bool _isValidEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ─────────────────────────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, Color(0xFF9D8FFF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('💸', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to sync your expenses\nacross all your devices.',
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textMuted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Email field ───────────────────────────────────────────────────
                  Text(
                    'Email address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputField(
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboard: TextInputType.emailAddress,
                    prefix: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ),
                  ),

                  // ── Error ─────────────────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: kAccent,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Send OTP button ───────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
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
                              'Send verification code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Divider ───────────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: c.border)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Google button ─────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _googleLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: context.isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                      ),
                      child: _googleLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: c.textMuted,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleLogo(),
                                const SizedBox(width: 10),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Skip to continue without login ────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      ),
                      child: Text(
                        'Continue without account',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.textMuted,
                          decoration: TextDecoration.underline,
                          decorationColor: c.textMuted,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Your data is stored locally until you sign in.',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google "G" Logo ───────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final segments = [
      (0.0, 1.0, const Color(0xFF4285F4)), // blue top-right
      (1.0, 1.75, const Color(0xFF34A853)), // green bottom-right
      (1.75, 2.5, const Color(0xFFFBBC05)), // yellow bottom-left
      (2.5, 3.2, const Color(0xFFEA4335)), // red top-left
    ];
    for (final (start, end, color) in segments) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start * 1.0,
        (end - start) * 1.0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
