import 'package:expensetracker/features/auth/providers/auth_provider.dart';
import 'package:expensetracker/features/auth/ui/otp_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/features/dashboard/widget/dashboard_widget.dart';
import 'package:expensetracker/features/home/providers/sync_provider.dart';
import 'package:expensetracker/features/home/ui/pages/home_screen.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _State();
}

class _State extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  static final _emailRx = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String? _validate() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (!_emailRx.hasMatch(email)) return 'Enter a valid email address';
    if (pass.length < 6) return 'Password must be at least 6 characters';
    if (_isSignUp && pass != _confirmCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ── Human-readable Supabase error messages ─────────────────────────────────
  // FIX: Supabase throws "Email not confirmed" when a user signed up but
  // hasn't verified their email yet, then tries to sign in after logging out.
  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('not confirmed') || r.contains('email not confirmed')) {
      return 'Please verify your email first.\nTap "Resend verification" below.';
    }
    if (r.contains('invalid login') ||
        r.contains('invalid credentials') ||
        r.contains('wrong password') ||
        r.contains('user not found')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (r.contains('already registered') ||
        r.contains('already exists') ||
        r.contains('email address is already')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (r.contains('rate limit') || r.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (r.contains('network') ||
        r.contains('socket') ||
        r.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  bool get _isEmailNotConfirmed =>
      _error?.contains('verify your email') == true ||
      _error?.contains('not confirmed') == true;

  // ── Email/Password submit ──────────────────────────────────────────────────
  Future<void> _submit() async {
    final validErr = _validate();
    if (validErr != null) {
      setState(() => _error = validErr);
      return;
    }

    setState(() => _error = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    final notifier = ref.read(authProvider.notifier);

    if (_isSignUp) {
      // ── SIGN UP ─────────────────────────────────────────────────────────
      // Step 1: create the account
      final err = await notifier.signUp(email, password);
      if (err != null) {
        setState(() => _error = _friendlyError(err));
        return;
      }

      //  await notifier.signOut();
      await notifier.sendOtp(email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } else {
      // ── SIGN IN ─────────────────────────────────────────────────────────
      final err = await notifier.signIn(email, password);
      if (err != null) {
        setState(() => _error = _friendlyError(err));
        return;
      }
      if (!mounted) return;

      // Pull cloud data into local Hive after login
      await ref.read(syncProvider.notifier).sync();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // ── Resend OTP (for "email not confirmed" state) ───────────────────────────
  Future<void> _resendVerification() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!_emailRx.hasMatch(email)) {
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
    } catch (_) {
      setState(() => _error = 'Could not send verification email. Try again.');
    }
  }

  // ── Google Sign In ─────────────────────────────────────────────────────────
  Future<void> _google() async {
    setState(() => _error = null);
    final err = await ref.read(authProvider.notifier).signInWithGoogle();

    // 'Cancelled' means user dismissed the picker — not an error to show
    if (err != null && err != 'Cancelled') {
      setState(() => _error = 'Google sign-in failed. Please try again.');
      return;
    }
    if (!mounted) return;
    if (ref.read(isLoggedInProvider)) {
      await ref.read(syncProvider.notifier).sync();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Watch loading state directly from provider — no local _loading/_gLoading flags
    final authState = ref.watch(authProvider);
    final loading = authState.isLoading;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // Background orb
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ─────────────────────────────────────────────────────────
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(Assets.appIcons, height: 20),
                  ),
                  const SizedBox(height: 24),

                  // ── Heading ───────────────────────────────────────────────────────
                  Text(
                    _isSignUp
                        ? AppLocalizations.of(context)!.createAccount
                        : AppLocalizations.of(context)!.welcomeBack,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? AppLocalizations.of(context)!.signUpToTrack
                        : AppLocalizations.of(context)!.signinContinue,
                    style: TextStyle(fontSize: 14, color: c.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // ── Email ─────────────────────────────────────────────────────────
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

                  // ── Password ──────────────────────────────────────────────────────
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

                  // ── Confirm password (signup only) ────────────────────────────────
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    InputField(
                      hint: 'Confirm password',
                      controller: _confirmCtrl,
                      obscure: _obscure,
                      prefix: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Sign in / Sign up toggle ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                      child: Text(
                        _isSignUp
                            ? AppLocalizations.of(context)!.alreadyHaveAn
                            : AppLocalizations.of(context)!.newHere,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // ── Error message ─────────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAccent.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: kAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kAccent,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // FIX: "Email not confirmed" → show Resend button inline
                          if (_isEmailNotConfirmed) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: loading ? null : _resendVerification,
                              child: Text(
                                'Resend verification email →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Primary CTA ───────────────────────────────────────────────────
                  AppButton(
                    label: _isSignUp
                        ? AppLocalizations.of(context)!.createAccount
                        : AppLocalizations.of(context)!.signIn,
                    loading: loading,
                    onTap: loading ? () {} : _submit,
                    icon: Icons.arrow_forward_rounded,
                  ),

                  const SizedBox(height: 20),

                  // ── Divider ───────────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: c.border)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Google Sign-In ───────────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : _google,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                      label: Text(AppLocalizations.of(context)!.continueGoogle),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Skip / Continue without account
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
                        AppLocalizations.of(context)!.continueWithoutAccount,
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
