import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/common/navigation_service.dart';
import 'package:budgetBuddy/features/auth/helper/auth_helpers.dart';
import 'package:budgetBuddy/features/auth/ui/sign_up_screen.dart';
import 'package:budgetBuddy/features/auth/ui/otp_screen.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetBuddy/features/dashboard/widget/dashboard_widget.dart';
import 'package:budgetBuddy/features/home/providers/sync_provider.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _isEmailNotConfirmed =>
      _error?.contains('verify your email') == true ||
      _error?.contains('Resend') == true;

  Future<void> _submit() async {
    final err = validateEmailPass(_emailCtrl.text, _passCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    final result = await ref
        .read(authProvider.notifier)
        .signIn(email, password);

    if (result != null) {
      setState(() => _error = friendlyError(result));
      return;
    }
    if (!mounted) return;
    await ref.read(syncProvider.notifier).sync();
    if (!mounted) return;
    NavigationService.push(target: DashboardPage());
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const Das()),
    // );
  }

  Future<void> _resendVerification() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!emailRx.hasMatch(email)) {
      setState(() => _error = 'Enter your email address first');
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendOtp(email);
      if (!mounted) return;
      setState(() => _error = null);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } catch (e) {
      setState(() => _error = friendlyError(e.toString()));
    }
  }

  Future<void> _google() async {
    setState(() => _error = null);

    try {
      final response = await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;

      // signInWithGoogle() returns null when the user cancels the Google
      // picker — that's not an error, just do nothing.
      if (response == null) return;

      if (ref.read(isLoggedInProvider)) {
        await ref.read(syncProvider.notifier).sync();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      // signInWithGoogle() rethrows on real failures instead of returning
      // an error string, so this is where actual failures are caught.
      if (!mounted) return;
      setState(() => _error = 'Google sign-in failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final loading = ref.watch(authProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          AuthOrb(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthLogo(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeBack,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.signinContinue,
                    style: TextStyle(fontSize: 14, color: c.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  InputField(
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboard: TextInputType.emailAddress,
                    prefix: Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  InputField(
                    hint: 'Password',
                    controller: _passCtrl,
                    obscure: _obscure,
                    prefix: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: c.textMuted,
                    ),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: c.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        /* navigate to forgot password */
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    ErrorBox(
                      error: _error!,
                      showResend: _isEmailNotConfirmed,
                      onResend: loading ? null : _resendVerification,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Sign in button
                  AppButton(
                    label: l10n.signIn,
                    loading: loading,
                    onTap: loading ? () {} : _submit,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 20),

                  // _OrDivider(c: c),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: loading ? null : _google,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: context.isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                      ),
                      child: loading
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
                                // _GoogleLogo(),
                                CommonSvgWidget(
                                  svgName: Assets.google,
                                  height: 30,
                                  width: 30,
                                ),
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
                  const SizedBox(height: 24),

                  // Go to sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 13, color: c.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Skip
                  Center(
                    child: TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DashboardWidget(),
                              ),
                            ),
                      child: Text(
                        l10n.continueWithoutAccount,
                        style: TextStyle(
                          color: c.textMuted,
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                      ),
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

// class _GoogleLogo extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => SizedBox(
//     width: 20,
//     height: 20,
//     child: CustomPaint(painter: _GoogleLogoPainter()),
//   );
// }

// class _GoogleLogoPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final c = size.center(Offset.zero);
//     final r = size.width / 2;
//     final segments = [
//       (0.0, 1.0, const Color(0xFF4285F4)), // blue top-right
//       (1.0, 1.75, const Color(0xFF34A853)), // green bottom-right
//       (1.75, 2.5, const Color(0xFFFBBC05)), // yellow bottom-left
//       (2.5, 3.2, const Color(0xFFEA4335)), // red top-left
//     ];
//     for (final (start, end, color) in segments) {
//       final paint = Paint()
//         ..color = color
//         ..strokeWidth = 3
//         ..style = PaintingStyle.stroke;
//       canvas.drawArc(
//         Rect.fromCircle(center: c, radius: r),
//         start * 1.0,
//         (end - start) * 1.0,
//         false,
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(_) => false;
// }
