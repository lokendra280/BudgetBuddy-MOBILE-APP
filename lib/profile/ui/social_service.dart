import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/profile/services/refers_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _State();
}

class _State extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String? _referralCode;
  int _referralCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReferral();
  }

  Future<void> _loadReferral() async {
    final code = await ReferralService.getOrCreateCode();
    final count = await ReferralService.fetchCount();
    if (mounted)
      setState(() {
        _referralCode = code;
        _referralCount = count;
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
          'Community',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: kPrimary,
          unselectedLabelColor: c.textMuted,
          indicatorColor: kPrimary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Leaderboard'),
            Tab(text: 'Challenges'),
            Tab(text: 'Invite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LeaderboardTab(),
          _ChallengesTab(),
          _InviteTab(code: _referralCode, count: _referralCount),
        ],
      ),
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  // In production: fetch from Supabase `leaderboard` view
  static final _mock = [
    _LBEntry('Aarav S.', 4200, '🥇', kAmber),
    _LBEntry('Priya M.', 5100, '🥈', AppColors.dark.textSub),
    _LBEntry('Bikash K.', 6800, '🥉', const Color(0xFFCD7F32)),
    _LBEntry('Sita R.', 7200, '', kPrimary),
    _LBEntry('Ram B.', 8900, '', kPrimary),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mySpend = ExpenseService.totalFor(
      ExpenseService.forMonth(DateTime.now()),
    );
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // My stats card
        AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimary, Color(0xFF9D8FFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthService.userName.isEmpty
                          ? 'You'
                          : AuthService.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Your spending this month',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${mySpend.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel('Top Savers This Month'),
        const SizedBox(height: 12),
        ..._mock.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${e.key + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textMuted,
                      // width: 20.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: e.value.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        e.value.medal.isEmpty ? e.value.name[0] : e.value.medal,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₹${e.value.spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: e.value.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '*Lower spending = better rank 🏆',
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

class _LBEntry {
  final String name, medal;
  final double spent;
  final Color color;
  const _LBEntry(this.name, this.spent, this.medal, this.color);
}

// ── Challenges ────────────────────────────────────────────────────────────────
class _ChallengesTab extends StatelessWidget {
  static final _challenges = [
    _Challenge(
      'No-Spend Weekend 🚫',
      'Spend ₹0 on Saturday & Sunday',
      60,
      kGreen,
    ),
    _Challenge(
      'Food Budget Hero 🍱',
      'Keep food under ₹1,500 this week',
      35,
      kPrimary,
    ),
    _Challenge('Transport Saver 🚌', 'Reduce transport by 30%', 10, kAmber),
    _Challenge(
      'Zero Entertainment 🎬',
      'No entertainment spend this week',
      80,
      kAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      SectionLabel('Active Challenges'),
      const SizedBox(height: 12),
      ..._challenges.map(
        (ch) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ch.desc,
                  style: TextStyle(fontSize: 11, color: context.c.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ch.progress / 100,
                          minHeight: 6,
                          backgroundColor: context.c.border,
                          valueColor: AlwaysStoppedAnimation(ch.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${ch.progress}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ch.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Challenge {
  final String title, desc;
  final int progress;
  final Color color;
  const _Challenge(this.title, this.desc, this.progress, this.color);
}

// ── Invite / Referral ─────────────────────────────────────────────────────────
class _InviteTab extends StatelessWidget {
  final String? code;
  final int count;
  const _InviteTab({required this.code, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Referral card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              const Text(
                'Invite Friends',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Share your code and grow together!',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 20),
              // Code box
              if (code != null) ...[
                Text(
                  'YOUR CODE',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        code!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: kPrimary),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(ClipboardData(text: code!));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => ReferralService.share(code!),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Share Invite Link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ] else
                const Center(child: CircularProgressIndicator(color: kPrimary)),
            ],
          ),
        ),

        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count friends invited',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Keep sharing to grow your network!',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        SectionLabel('How it works'),
        const SizedBox(height: 12),
        ...[
          ('1️⃣', 'Share your unique invite code with friends'),
          ('2️⃣', 'They download SpendSense and enter your code'),
          ('3️⃣', 'Both of you get streak bonus days!'),
        ].map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(step.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(step.$2, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
