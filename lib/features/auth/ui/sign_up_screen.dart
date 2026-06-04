import 'package:budgetBuddy/features/auth/helper/auth_helpers.dart';
import 'package:budgetBuddy/features/auth/ui/otp_screen.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final err = validateSignUp(
      _emailCtrl.text,
      _passCtrl.text,
      _confirmCtrl.text,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    final result = await ref
        .read(authProvider.notifier)
        .signUp(email, password);

    if (result != null) {
      setState(() => _error = friendlyError(result));
      return;
    }

    // Send OTP safely (ignore rate limit — email just sent by signUp)
    await _safeSendOtp(email);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
    );
  }

  Future<void> _safeSendOtp(String email) async {
    try {
      await ref.read(authProvider.notifier).sendOtp(email);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('rate') ||
          msg.contains('429') ||
          msg.contains('seconds')) {
        debugPrint('[Auth] OTP rate limited — previous OTP still valid');
        return; // safe to ignore — OTP from signUp still valid
      }
      rethrow;
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
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),

                  AuthLogo(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.signUpToTrack,
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
                  const SizedBox(height: 12),

                  // Confirm password
                  InputField(
                    hint: 'Confirm password',
                    controller: _confirmCtrl,
                    obscure: true,
                    prefix: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Error
                  if (_error != null) ...[
                    ErrorBox(error: _error!),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 6),

                  // Sign up button
                  AppButton(
                    label: l10n.createAccount,
                    loading: loading,
                    onTap: loading ? () {} : _submit,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Go to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 13, color: c.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
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
