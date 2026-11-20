import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/onboard/ui/widgets/onboard_illustrations.dart';
import 'package:budgetbuddy/common/services/app_version_service.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../language_screen.dart';

// Light, brand-green onboarding that matches the in-app design
// (mint background, deep-green cards, piggy mascot). Always light — it's
// the first screen and should look the same regardless of system theme.

const _ink = Color(0xFF0F0F1A);
const _sub = Color(0xFF606080);

class _PageData {
  final String tag, title, subtitle;
  final Widget Function(double t) illustration;
  const _PageData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});
  @override
  State<OnboardScreen> createState() => _OnboardState();
}

class _OnboardState extends State<OnboardScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Gentle float for the illustration pieces.
  late final _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  // Fade/slide-in for the first page's content.
  late final _introCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  final _pages = <_PageData>[
    _PageData(
      tag: 'TRACK',
      title: 'Take control of\nevery rupee',
      subtitle:
          'Log expenses in seconds — type, speak or snap a bill. See exactly where your money goes.',
      illustration: (t) => TrackIllustration(t: t),
    ),
    _PageData(
      tag: 'UNDERSTAND',
      title: 'Smart insights,\nzero effort',
      subtitle:
          'Spot overspending early, see your top categories and get a daily financial health score.',
      illustration: (t) => AnalyseIllustration(t: t),
    ),
    _PageData(
      tag: 'GROW',
      title: 'Save more,\nstress less',
      subtitle:
          'Set budgets and goals, keep your streak alive and check in right from your home screen.',
      illustration: (t) => GrowIllustration(t: t),
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _floatCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (!_isLast) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await AppVersionService.markOnboarded();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LanguageScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kMint, Color(0xFFF4FBF7), Colors.white],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                  child: Row(
                    children: [
                      const PiggyMascot(size: 32),
                      const SizedBox(width: 8),
                      const Text(
                        'BudgetBuddy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kDeepGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isLast ? 0 : 1,
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          style: TextButton.styleFrom(foregroundColor: _sub),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Pages: illustration + copy swipe together ─────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _introCtrl,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) =>
                          _Page(data: _pages[i], float: _floatCtrl),
                    ),
                  ),
                ),

                // ── Dots + CTA ────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? kMidGreen
                                    : kMidGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: kMidGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              key: ValueKey(_isLast),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isLast ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final _PageData data;
  final Animation<double> float;
  const _Page({required this.data, required this.float});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration takes whatever height is left; sits low so it stays
          // close to the copy on tall phones (capped so it doesn't balloon).
          Expanded(
            child: Align(
              alignment: const Alignment(0, 0.6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AnimatedBuilder(
                    animation: float,
                    builder: (_, __) => data.illustration(
                      Curves.easeInOut.transform(float.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kMint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.tag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: kMidGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.8,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 15, height: 1.5, color: _sub),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
