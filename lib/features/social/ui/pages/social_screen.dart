import 'package:expensetracker/features/auth/providers/auth_provider.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';

import 'package:expensetracker/features/social/services/share_service.dart';
import 'package:expensetracker/features/social/ui/widget/challenges_tab.dart';
import 'package:expensetracker/features/social/ui/widget/invite_tab.dart';
import 'package:expensetracker/features/social/ui/widget/leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});
  @override
  ConsumerState<SocialScreen> createState() => _SS();
}

class _SS extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    Future.microtask(_pushLeaderboard);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pushLeaderboard() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    try {
      final month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final all = ref.read(monthExpensesProvider);
      final spent = all
          .where((e) => !e.isIncome)
          .fold(0.0, (s, e) => s + e.amount);
      final streak = ref.read(budgetProvider).streakDays;
      await _sb.from('leaderboard').upsert({
        'user_id': auth.user!.id,
        'name': ref.read(userNameProvider),
        'avatar': ref.read(userAvatarProvider),
        'spent': spent,
        'streak': streak,
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

        title: const Text(
          'Community',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: CommonSvgWidget(
              svgName: Assets.share,
              color: AppColors.primaryColor,
              height: 25,
              width: 25,
            ),
            tooltip: 'Share my report',
            onPressed: () => ShareService.shareReport(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: c.textMuted,
          indicatorColor: AppColors.primaryColor,
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
        children: const [LeaderboardTab(), ChallengesTab(), InviteTab()],
      ),
    );
  }
}
