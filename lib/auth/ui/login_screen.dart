import 'package:expensetracker/auth/ui/otp_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

enum _AuthMode { password, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;
  bool _loading = false;
  bool _gLoading = false;
  String? _error;

  bool _valid(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  // ── Password auth ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();
    if (!_valid(email)) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (_isSignUp && pass != _confirm.text.trim()) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await AuthService.signUp(email, pass);
        // Show message — Supabase sends confirmation email
        if (!mounted) return;
        _showSnack(
          'Account created! Check your email to confirm, then sign in.',
          kGreen,
        );
        setState(() => _isSignUp = false);
      } else {
        await AuthService.signIn(email, pass);
        await SyncService.migrateOnFirstLogin();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(
        () => _error = e.toString().contains('Invalid')
            ? 'Incorrect email or password'
            : e.toString().contains('already registered')
            ? 'Email already registered. Please sign in.'
            : 'Authentication failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── OTP auth ─────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _email.text.trim();
    if (!_valid(email)) {
      setState(() => _error = 'Enter a valid email');
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
    } catch (_) {
      setState(() => _error = 'Failed to send code. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────
  Future<void> _google() async {
    setState(() {
      _gLoading = true;
      _error = null;
    });
    try {
      final res = await AuthService.signInWithGoogle();
      if (res == null || !mounted) {
        setState(() => _gLoading = false);
        return;
      }
      await SyncService.migrateOnFirstLogin();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (_) {
      setState(() => _error = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _gLoading = false);
    }
  }

  void _showSnack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.12), Colors.transparent],
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
                  // Logo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, Color(0xFF818CF8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('💸', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSignUp ? 'Create account' : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Sign up to track and sync your finances.'
                        : 'Sign in to continue to SpendSense.',
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textMuted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Auth mode tabs
                  Container(
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      labelColor: Colors.white,
                      unselectedLabelColor: c.textMuted,
                      indicator: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'Password'),
                        Tab(text: 'Email OTP'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: _isSignUp ? 280 : 220,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        // ── Password tab ──────────────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.textSub,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InputField(
                              hint: 'you@example.com',
                              controller: _email,
                              keyboard: TextInputType.emailAddress,
                              prefix: Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.textSub,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InputField(
                              hint: '••••••••',
                              controller: _pass,
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
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 12),
                              InputField(
                                hint: 'Confirm password',
                                controller: _confirm,
                                obscure: _obscure,
                                prefix: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _isSignUp = !_isSignUp),
                                  child: Text(
                                    _isSignUp
                                        ? 'Already have an account? Sign in'
                                        : 'New here? Create account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ── OTP tab ───────────────────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.textSub,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InputField(
                              hint: 'you@example.com',
                              controller: _email,
                              keyboard: TextInputType.emailAddress,
                              prefix: Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kPrimary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: kPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'We\'ll send a 6-digit code to verify your email. No password needed.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.textSub,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAccent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: kAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
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
                    ),
                  ],

                  const SizedBox(height: 20),

                  // CTA
                  AppButton(
                    label: _tabs.index == 0
                        ? (_isSignUp ? 'Create Account' : 'Sign In')
                        : 'Send Verification Code',
                    onTap: _tabs.index == 0 ? _submit : _sendOtp,
                    loading: _loading,
                    icon: _tabs.index == 0
                        ? Icons.arrow_forward_rounded
                        : Icons.send_rounded,
                  ),

                  const SizedBox(height: 20),
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

                  // Google
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _gLoading ? null : _google,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        foregroundColor: context.c.textSub,
                      ),
                      child: _gLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.textMuted,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4285F4),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
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

                  const SizedBox(height: 20),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
