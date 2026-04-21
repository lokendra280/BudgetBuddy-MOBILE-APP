import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard/ui/widgets/analyseillustration.dart';
import 'package:expensetracker/common/onboard/ui/widgets/chip_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/dot_grid_painter.dart';
import 'package:expensetracker/common/onboard/ui/widgets/dots_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/grow_illustration_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/logo_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/onboarding_button.dart';
import 'package:expensetracker/common/onboard/ui/widgets/skip_button.dart';
import 'package:expensetracker/common/onboard/ui/widgets/track_illustration_widget.dart';
import 'package:expensetracker/common/services/app_version_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../language_screen.dart';

class _PageData {
  final String chip, title, subtitle;
  final List<Color> bg;
  final Color orbColor;
  final Widget Function(double t) illustration;
  const _PageData({
    required this.chip,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.orbColor,
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
  double _offset = 0;

  // Slide-up + fade animation for bottom text content
  late final _contentCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _contentAnim = CurvedAnimation(
    parent: _contentCtrl,
    curve: Curves.easeOutExpo,
  );

  // Float animation for illustration cards
  late final _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final List<_PageData> _pages = [
    _PageData(
      chip: '01 / TRACK',
      title: 'Every Rupee\nCounts',
      subtitle:
          'Snap a bill or type an amount in seconds.\nSee exactly where your money goes.',
      bg: const [Color(0xFF0D0825), Color(0xFF1A1060), Color(0xFF2A1869)],
      orbColor: AppColors.primaryColor,
      illustration: (t) => TrackIllustration(t: t),
    ),
    _PageData(
      chip: '02 / ANALYSE',
      title: 'Smart AI\nInsights',
      subtitle:
          'Spot overspending before it hurts.\nGet a financial health score daily.',
      bg: const [Color(0xFF051228), Color(0xFF092040), Color(0xFF0D3560)],
      orbColor: AppColors.secondaryColor,
      illustration: (t) => AnalyseIllustration(t: t),
    ),
    _PageData(
      chip: '03 / GROW',
      title: 'Build Wealth\nTogether',
      subtitle:
          'Set savings goals, beat streaks and\ncompete on the leaderboard.',
      bg: const [Color(0xFF021410), Color(0xFF053828), Color(0xFF0A5240)],
      orbColor: AppColors.primaryColor,
      illustration: (t) => GrowIllustrationWidget(t: t),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() => setState(() => _offset = _pageCtrl.page ?? 0));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _contentCtrl.forward(from: 0);
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 520),
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

  // Interpolate gradient between current page and next during swipe
  Color _lerpBg(int stop) {
    final floor = _offset.floor().clamp(0, _pages.length - 1);
    final ceil = (_offset.ceil()).clamp(0, _pages.length - 1);
    final t = _offset - _offset.floor();
    return Color.lerp(_pages[floor].bg[stop], _pages[ceil].bg[stop], t)!;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final p = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Animated gradient background ─────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_lerpBg(0), _lerpBg(1), _lerpBg(2)],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Dot-grid texture ─────────────────────────────────────────────
            Positioned.fill(child: CustomPaint(painter: DotGridPainter())),

            // ── Large radial orb top-right ────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              top: -80,
              right: -80,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.orbColor.withOpacity(0.22), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Small orb bottom-left
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              bottom: size.height * 0.28,
              left: -50,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.orbColor.withOpacity(0.12), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Illustration PageView (fills the top 70%) ─────────────────────
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) => PageView.builder(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i].illustration(_floatCtrl.value),
              ),
            ),

            // ── Top bar: logo + skip ─────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 18, 0),
                child: Row(
                  children: [
                    LogoWidget(),
                    const Spacer(),
                    SkipButton(onTap: _finish),
                  ],
                ),
              ),
            ),

            // ── Bottom gradient overlay + content ────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(_contentAnim),
                child: FadeTransition(
                  opacity: _contentAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.90),
                        ],
                        stops: const [0.0, 0.22, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(26, 48, 26, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Chip tag
                            ChipWidget(p.chip),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.08,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Text(
                              p.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.58),
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Dots + CTA
                            Row(
                              children: [
                                DotsWidget(
                                  count: _pages.length,
                                  current: _page,
                                ),
                                const Spacer(),
                                OnBoardingButton(isLast: isLast, onTap: _next),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
