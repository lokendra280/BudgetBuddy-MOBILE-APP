import 'package:budgetBuddy/common/widgets/app_tabbar.dart';
import 'package:budgetBuddy/common/widgets/custom_appbar.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';

import 'package:budgetBuddy/features/social/services/share_service.dart';
import 'package:budgetBuddy/features/social/ui/widget/challenges_tab.dart';
import 'package:budgetBuddy/features/social/ui/widget/invite_tab.dart';
import 'package:budgetBuddy/features/social/ui/widget/leaderboard.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
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
      appBar: CustomAppBar(
        backgroundColor: c.surface,

        title: AppLocalizations.of(context)!.community,

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

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: AppTabBar(
            controller: _tabs,
            tabs: [
              AppLocalizations.of(context)!.leaderboard,
              AppLocalizations.of(context)!.challenges,
              AppLocalizations.of(context)!.invite,
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [LeaderboardTab(), ChallengesTab(), InviteTab()],
      ),
    );
  }
}
