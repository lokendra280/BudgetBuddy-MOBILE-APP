import 'package:expensetracker/auth/ui/otp_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/dashboard/pages/dashboard_page.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/pages/home_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  // ── Email + Password Auth ───────────────────────────────────────────────
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
        // 1. Create account
        await AuthService.signUp(email, pass);

        // 2. Send OTP after signup
        await AuthService.sendOtp(email);

        if (!mounted) return;

        // 3. Go to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        // LOGIN
        await AuthService.signIn(email, pass);
        await SyncService.migrateOnFirstLogin();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Invalid')
            ? 'Incorrect email or password'
            : e.toString().contains('already registered')
            ? 'Email already registered. Please sign in.'
            : 'Authentication failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign In ───────────────────────────────────────────────────────
  Future<void> _google() async {
    setState(() {
      _gLoading = true;
      _error = null;
    });

    try {
      final res = await AuthService.signInWithGoogle();

      if (res == null || !mounted) return;

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

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

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
                  // LOGO
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                        : 'Sign in to continue.',
                    style: TextStyle(fontSize: 14, color: c.textMuted),
                  ),

                  const SizedBox(height: 32),

                  // EMAIL
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

                  // PASSWORD
                  InputField(
                    hint: 'Password',
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
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // CONFIRM PASSWORD (SIGNUP ONLY)
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

                  const SizedBox(height: 16),

                  // TOGGLE
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New here? Create account',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // ERROR
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // BUTTON
                  AppButton(
                    label: _isSignUp ? 'Create Account' : 'Sign In',
                    loading: _loading,
                    onTap: _submit,
                    icon: Icons.arrow_forward_rounded,
                  ),

                  const SizedBox(height: 24),

                  // GOOGLE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _gLoading ? null : _google,
                      child: _gLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text('Continue with Google'),
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
                          color: c.textMuted,
                          decoration: TextDecoration.underline,
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
