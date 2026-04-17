import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/language_screen.dart';
import 'package:expensetracker/common/services/app_version_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});
  @override
  State<OnboardScreen> createState() => _State();
}

class _State extends State<OnboardScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardData(
      emoji: '💸',
      gradient: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
      title: 'Track Every Rupee',
      sub: 'Log expenses in seconds.\nKnow exactly where your money goes.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _OnboardData(
      emoji: '📊',
      gradient: [Color(0xFF059669), Color(0xFF34D399)],
      title: 'Smart Insights',
      sub: 'Weekly reports, spending patterns,\nand shocking waste alerts.',
      icon: Icons.insights_rounded,
    ),
    _OnboardData(
      emoji: '🎯',
      gradient: [Color(0xFFD97706), Color(0xFFFBBF24)],
      title: 'Stay on Budget',
      sub: 'Set monthly goals.\nBeat your streak. Build better habits.',
      icon: Icons.savings_rounded,
    ),
  ];

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      await _done();
    }
  }

  Future<void> _done() async {
    // Use AppVersionService — stores build number alongside flag
    // so new installs always trigger onboarding
    await AppVersionService.markOnboarded();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final d = _pages[_page];

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [d.gradient[0].withOpacity(0.14), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _done,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _Page(data: _pages[i]),
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? kPrimary : c.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: d.gradient),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _page == _pages.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final _OnboardData data;
  const _Page({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradient
                    .map((col) => col.withOpacity(0.15))
                    .toList(),
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.gradient[0].withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  data.icon,
                  size: 60,
                  color: data.gradient[0].withOpacity(0.3),
                ),
                Text(data.emoji, style: const TextStyle(fontSize: 52)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.sub,
            style: TextStyle(fontSize: 15, color: c.textSub, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  final String emoji, title, sub;
  final List<Color> gradient;
  final IconData icon;
  const _OnboardData({
    required this.emoji,
    required this.gradient,
    required this.title,
    required this.sub,
    required this.icon,
  });
}
