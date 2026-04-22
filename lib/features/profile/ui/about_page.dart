import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _State();
}

class _State extends State<AboutScreen> {
  String _version = '1.0.0';
  String _build = '1';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted)
        setState(() {
          _version = info.version;
          _build = info.buildNumber;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── App hero ──────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💸', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SpendSense',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version $_version (Build $_build)',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen.withOpacity(0.25)),
                  ),
                  child: const Text(
                    '🚀 Final Release',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Mission ───────────────────────────────────────────────────────
          _Section('Our Mission'),
          AppCard(
            child: const Text(
              'SpendSense helps you track every rupee, understand your spending habits, '
              'and make smarter financial decisions — whether you\'re in Kathmandu, Mumbai, London, or New York.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ),

          const SizedBox(height: 20),

          // ── Target markets ────────────────────────────────────────────────
          _Section('Target Markets'),
          Row(
            children: [
              _MarketCard('🇳🇵', 'Nepal', 'Primary', AppColors.primaryColor),
              const SizedBox(width: 10),
              _MarketCard('🇮🇳', 'India', 'Growing', kAmber),
              const SizedBox(width: 10),
              _MarketCard('🇬🇧', 'UK', 'Expanding', kBlue),
              const SizedBox(width: 10),
              _MarketCard('🇺🇸', 'USA', 'Target', kGreen),
            ],
          ),

          const SizedBox(height: 20),

          // ── Final goal features ───────────────────────────────────────────
          _Section('Scalable Product Features'),
          AppCard(
            child: Column(
              children: [
                _FeatureRow(
                  '🤖',
                  'AI Insights',
                  'Smart spending suggestions & pattern detection',
                  AppColors.primaryColor,
                ),
                _Divider(),
                _FeatureRow(
                  '☁️',
                  'Cloud Sync',
                  'Real-time sync across all your devices via Supabase',
                  kBlue,
                ),
                _Divider(),
                _FeatureRow(
                  '👥',
                  'Social Features',
                  'Leaderboards, challenges & viral referral system',
                  kAmber,
                ),
                _Divider(),
                _FeatureRow(
                  '💰',
                  'Stable Revenue',
                  'AdMob integration — banner, interstitial & rewarded ads',
                  kGreen,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Built with ────────────────────────────────────────────────────
          _Section('Built With'),
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TechChip('Flutter', '💙'),
                _TechChip('Supabase', '⚡'),
                _TechChip('Hive', '🐝'),
                _TechChip('Google AdMob', '📢'),
                _TechChip('Google ML Kit', '🔍'),
                _TechChip('Lottie', '🎬'),
                _TechChip('FL Chart', '📊'),
                _TechChip('Local Auth', '🔒'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Multi-language ────────────────────────────────────────────────
          _Section('Languages'),
          AppCard(
            child: Row(
              children: [
                _LangBadge('🇬🇧', 'English'),
                const SizedBox(width: 12),
                _LangBadge('🇳🇵', 'नेपाली'),
                const SizedBox(width: 12),
                _LangBadge('🇮🇳', 'हिन्दी'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Legal ─────────────────────────────────────────────────────────
          _Section('Legal'),
          AppCard(
            child: Column(
              children: [
                _LegalRow('Privacy Policy', Icons.privacy_tip_outlined),
                Divider(color: context.c.border, height: 16),
                _LegalRow('Terms of Service', Icons.description_outlined),
                Divider(color: context.c.border, height: 16),
                _LegalRow('Open Source Licenses', Icons.code_rounded),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Text(
                  'Made with ❤️ for Nepal & the world',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} SpendSense. All rights reserved.',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: context.c.border, height: 16);
}

class _MarketCard extends StatelessWidget {
  final String flag, name, status;
  final Color color;
  const _MarketCard(this.flag, this.name, this.status, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, desc;
  final Color color;
  const _FeatureRow(this.emoji, this.title, this.desc, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: context.c.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TechChip extends StatelessWidget {
  final String label, emoji;
  const _TechChip(this.label, this.emoji);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.c.textSub,
          ),
        ),
      ],
    ),
  );
}

class _LangBadge extends StatelessWidget {
  final String flag, name;
  const _LangBadge(this.flag, this.name);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(flag, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(
        name,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _LegalRow extends StatelessWidget {
  final String label;
  final IconData icon;
  const _LegalRow(this.label, this.icon);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: context.c.textMuted),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: context.c.textMuted,
      ),
    ],
  );
}
