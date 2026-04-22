import 'package:expensetracker/features/auth/services/biometric_service.dart';
import 'package:expensetracker/features/auth/ui/lock_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard/onboard_screen.dart';
import 'package:expensetracker/common/services/app_version_service.dart';
import 'package:expensetracker/features/dashboard/pages/dashboard_page.dart';
import 'package:expensetracker/features/dashboard/widget/dashboard_widget.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Wait for animation + version check in parallel
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      AppVersionService.checkAndResetIfNeeded(), // resets onboarding on new build
    ]);

    if (!mounted) return;

    final onboarded = await AppVersionService.isOnboarded();
    final bioEnabled = await BiometricService.isEnabled;

    Widget dest = onboarded ? const DashboardPage() : const OnboardScreen();
    if (bioEnabled && onboarded) dest = LockScreen(child: dest);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.white,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    AppLocalizations.of(context)!.appName,
                    textStyle: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F0F1A),
                      letterSpacing: -0.5,
                    ),
                    speed: const Duration(milliseconds: 80),
                    cursor: '',
                  ),
                ],
                totalRepeatCount: 1,
              ),

              const SizedBox(height: 10),

              AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'Track. Save. Grow.',
                    textStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF52526E)
                          : const Color(0xFF9090B0),
                      letterSpacing: 1.2,
                    ),
                    duration: const Duration(milliseconds: 1200),
                  ),
                ],
                totalRepeatCount: 1,
              ),

              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2400),
                    curve: Curves.easeInOut,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 3,
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E30)
                          : const Color(0xFFE8E8F0),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryColor,
                      ),
                    ),
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
