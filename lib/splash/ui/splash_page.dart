import 'package:expensetracker/auth/services/biometric_service.dart';
import 'package:expensetracker/auth/ui/lock_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard_screen.dart';
import 'package:expensetracker/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Wait minimum 2.8s for animation to play
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    final bioEnabled = await BiometricService.isEnabled;

    Widget dest = onboarded ? const HomeScreen() : const OnboardScreen();

    // Wrap in LockScreen only if biometric is enabled
    if (bioEnabled) dest = LockScreen(child: dest);

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // ── Lottie animation ─────────────────────────────────────────────
            // Uses lottie-flutter to play a JSON animation.
            // Place your animation at: assets/lottie/splash.json
            // Recommended free animations from lottiefiles.com:
            //   - "Money wallet" or "Finance growth" animations work great
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/lottie/splash.json',
                controller: _ctrl,
                onLoaded: (comp) {
                  _ctrl
                    ..duration = comp.duration
                    ..forward();
                },
                // Fallback if animation file not found
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimary, Color(0xFF818CF8)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💸', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── App name with typewriter effect ──────────────────────────────
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'SpendSense',
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
              pause: const Duration(milliseconds: 200),
            ),

            const SizedBox(height: 10),

            // ── Tagline ───────────────────────────────────────────────────────
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

            const Spacer(flex: 3),

            // ── Bottom loading bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 32),
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
                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
