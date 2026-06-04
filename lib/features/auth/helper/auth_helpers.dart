import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:flutter/material.dart';

// ── Validation ────────────────────────────────────────────────────
final emailRx = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

String? validateEmailPass(String email, String pass) {
  if (!emailRx.hasMatch(email.trim())) return 'Enter a valid email address';
  if (pass.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateSignUp(String email, String pass, String confirm) {
  final base = validateEmailPass(email, pass);
  if (base != null) return base;
  if (pass != confirm) return 'Passwords do not match';
  return null;
}

// ── Error messages ────────────────────────────────────────────────
String friendlyError(String raw) {
  final r = raw.toLowerCase();
  if (r.contains('not confirmed') ||
      r.contains('email_not_confirmed') ||
      r.contains('verify'))
    return 'Please verify your email first.\nTap "Resend verification" below.';
  if (r.contains('invalid login') ||
      r.contains('invalid credentials') ||
      r.contains('user not found'))
    return 'Incorrect email or password. Please try again.';
  if (r.contains('already registered') || r.contains('already exists'))
    return 'This email is already registered. Try signing in instead.';
  if (r.contains('rate') ||
      r.contains('429') ||
      r.contains('too many') ||
      r.contains('seconds')) {
    final secs = RegExp(r'(\d+)\s*seconds?').firstMatch(r)?.group(1);
    return secs != null
        ? 'Please wait $secs seconds before trying again.'
        : 'Too many attempts. Please wait a moment and try again.';
  }
  if (r.contains('network') || r.contains('socket') || r.contains('connection'))
    return 'No internet connection. Check your network and try again.';
  debugPrint('[Auth] Unhandled error: $raw');
  return 'Something went wrong. Please try again.';
}

// ── Shared widgets ────────────────────────────────────────────────
class AuthOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
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
  );
}

class AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryColor, Color(0xFF818CF8)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Image.asset(Assets.appIcons, height: 20),
  );
}

class ErrorBox extends StatelessWidget {
  final String error;
  final bool showResend;
  final VoidCallback? onResend;
  const ErrorBox({required this.error, this.showResend = false, this.onResend});

  @override
  Widget build(BuildContext context) => Container(
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
            const Icon(Icons.error_outline_rounded, size: 14, color: kAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  color: kAccent,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (showResend) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onResend,
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
  );
}

class _OrDivider extends StatelessWidget {
  final dynamic c;
  const _OrDivider({required this.c});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: c.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: TextStyle(fontSize: 12, color: c.textMuted)),
      ),
      Expanded(child: Divider(color: c.border)),
    ],
  );
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;
  const _GoogleButton({
    required this.loading,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      onPressed: loading ? null : onTap,
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
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
