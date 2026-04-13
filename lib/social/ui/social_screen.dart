import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/shimmer_widget.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/profile/services/refers_service.dart';
import 'package:expensetracker/social/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SS();
}

class _SS extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  String? _code;
  int _codeCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final code = await ReferralService.getOrCreateCode();
    final count = await ReferralService.fetchCount();
    await _pushLeaderboard();
    if (mounted)
      setState(() {
        _code = code;
        _codeCount = count;
        _loading = false;
      });
  }

  Future<void> _pushLeaderboard() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final expenses = ExpenseService.forMonth(DateTime.now());
      await Supabase.instance.client.from('leaderboard').upsert({
        'user_id': AuthService.currentUser!.id,
        'name': AuthService.userName,
        'avatar': AuthService.userAvatarUrl,
        'spent': ExpenseService.expenseFor(expenses),
        'streak': ExpenseService.budget.streakDays,
        'month': month,
      }, onConflict: 'user_id');
    } catch (_) {}
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: kPrimary),
            onPressed: () => ShareService.shareReport(context),
            tooltip: 'Share my report',
          ),
        ],
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
      body: _loading
          ? const SocialShimmer()
          : TabBarView(
              controller: _tabs,
              children: [
                _LeaderboardTab(),
                _ChallengesTab(),
                _InviteTab(code: _code, count: _codeCount),
              ],
            ),
    );
  }
}

// ── LEADERBOARD ───────────────────────────────────────────────────────────────
class _LeaderboardTab extends StatefulWidget {
  @override
  State<_LeaderboardTab> createState() => _LBS();
}

class _LBS extends State<_LeaderboardTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final data = await Supabase.instance.client
          .from('leaderboard')
          .select()
          .eq('month', month)
          .order('spent', ascending: true)
          .limit(20);
      if (mounted)
        setState(() => _rows = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      if (mounted) setState(() => _err = 'Failed to load.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sym = ExpenseService.symbol;
    final my = AuthService.currentUser?.id;
    final myExp = ExpenseService.expenseFor(
      ExpenseService.forMonth(DateTime.now()),
    );

    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
      );
    if (_err != null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(_err!, style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

    return RefreshIndicator(
      onRefresh: _fetch,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // My card
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, Color(0xFF818CF8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      AuthService.isLoggedIn ? AuthService.userInitials : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthService.isLoggedIn ? AuthService.userName : 'Guest',
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
                  ExpenseService.fmt(myExp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_rows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      'No one on leaderboard yet',
                      style: TextStyle(color: c.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add expenses to appear here!',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SectionLabel('Top Savers This Month'),
            const SizedBox(height: 12),
            ..._rows.asMap().entries.map((e) {
              final rank = e.key + 1;
              final d = e.value;
              final isMe = d['user_id'] == my;
              final name = (d['name'] as String?) ?? 'User';
              final spent = (d['spent'] as num?)?.toDouble() ?? 0.0;
              final streak = d['streak'] as int ?? 0;
              final medal = rank == 1
                  ? '🥇'
                  : rank == 2
                  ? '🥈'
                  : rank == 3
                  ? '🥉'
                  : '';
              final col = rank == 1
                  ? kAmber
                  : rank == 2
                  ? c.textSub
                  : rank == 3
                  ? const Color(0xFFCD7F32)
                  : kPrimary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  color: isMe ? kPrimary.withOpacity(0.06) : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            medal.isEmpty ? name[0].toUpperCase() : medal,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You ($name)' : name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMe ? kPrimary : null,
                              ),
                            ),
                            if (streak > 0)
                              Text(
                                '🔥 $streak day streak',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: kAmber,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '$sym${spent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: col,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '*Lower spending = better rank 🏆',
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── CHALLENGES — real progress from user data ─────────────────────────────────
class _ChallengesTab extends StatefulWidget {
  @override
  State<_ChallengesTab> createState() => _CHS();
}

class _CHS extends State<_ChallengesTab> {
  List<_CData> _ch = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final all = ExpenseService.forMonth(DateTime.now());
    final exp = all.where((e) => !e.isIncome).toList();
    final total = ExpenseService.expenseFor(all);
    final budget = ExpenseService.budget.monthlyLimit;
    final cats = ExpenseService.byCategory(exp);
    final food = (cats['Food'] ?? 0) + (cats['Groceries'] ?? 0);
    final trans = cats['Transport'] ?? 0;
    final ent = cats['Entertainment'] ?? 0;

    final now = DateTime.now();
    final ws = now.subtract(Duration(days: now.weekday - 1));
    final wkSat = ExpenseService.forWeek(ws)
        .where(
          (e) => !e.isIncome && (e.date.weekday == 6 || e.date.weekday == 7),
        )
        .fold(0.0, (s, e) => s + e.amount);

    setState(() {
      _ch = [
        _CData(
          'Budget Hero 💰',
          'Stay under monthly budget',
          budget > 0 ? (total < budget ? (budget - total) / budget : 0) : 0,
          kGreen,
          '${((total / budget.clamp(1, 99999)) * 100).toInt()}% of budget used',
        ),
        _CData(
          'Food Saver 🍱',
          'Keep food under 30% of budget',
          food > 0 ? (1 - (food / (budget * 0.3)).clamp(0, 1)) : 1.0,
          kPrimary,
          'Food: ${ExpenseService.fmt(food)} / ${ExpenseService.fmt(budget * 0.3)}',
        ),
        _CData(
          'No-Spend Weekend 🚫',
          'Zero spend on Sat & Sun',
          wkSat == 0 ? 1.0 : 0.0,
          kAmber,
          wkSat == 0
              ? '✓ Weekend clear so far!'
              : '${ExpenseService.fmt(wkSat)} spent this weekend',
        ),
        _CData(
          'Transport Cutter 🚌',
          'Transport under 10% of budget',
          trans > 0 ? (1 - (trans / (budget * 0.1)).clamp(0, 1)) : 1.0,
          kBlue,
          'Transport: ${ExpenseService.fmt(trans)} / ${ExpenseService.fmt(budget * 0.1)}',
        ),
        _CData(
          'Entertainment Free 🎬',
          'No entertainment this month',
          ent == 0 ? 1.0 : 0.0,
          kAccent,
          ent == 0
              ? '✓ No entertainment spend!'
              : '${ExpenseService.fmt(ent)} spent on entertainment',
        ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
      );
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionLabel('Active Challenges'),
        const SizedBox(height: 12),
        ..._ch.map(
          (ch) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ch.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (ch.progress >= 1 ? kGreen : ch.color)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ch.progress >= 1
                              ? '✓ Done'
                              : '${(ch.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ch.progress >= 1 ? kGreen : ch.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ch.desc,
                    style: TextStyle(fontSize: 11, color: context.c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ch.progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: context.c.border,
                      valueColor: AlwaysStoppedAnimation(
                        ch.progress >= 1 ? kGreen : ch.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ch.hint,
                    style: TextStyle(fontSize: 10, color: context.c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CData {
  final String title, desc, hint;
  final double progress;
  final Color color;
  const _CData(this.title, this.desc, this.progress, this.color, this.hint);
}

// ── INVITE ────────────────────────────────────────────────────────────────────
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
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.14), kPrimary.withOpacity(0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 10),
              const Text(
                'Invite Friends',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Both get 3 bonus streak days!',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 18),
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
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
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
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(ClipboardData(text: code!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                            backgroundColor: kGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPrimary.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: kPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Share Invite',
                        onTap: () => ReferralService.share(code!),
                        icon: Icons.share_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ShareService.shareReport(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: kGreen.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: kGreen,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                const Center(child: CircularProgressIndicator(color: kPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Share report
        AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.ios_share_rounded,
                  color: kGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share my report',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Share monthly spending summary as image',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ShareService.shareReport(context),
                child: const Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Count
        AppCard(
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count friend${count == 1 ? '' : 's'} invited',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Keep sharing to grow!',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${count * 3} streak days',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionLabel('How it works'), const SizedBox(height: 12),
        ...[
          ('1️⃣', 'Share your code or report'),
          ('2️⃣', 'Friend enters code on install'),
          ('3️⃣', 'Both get +3 streak bonus days 🔥'),
          ('4️⃣', 'Compete on leaderboard 🏆'),
        ].map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.$2,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
