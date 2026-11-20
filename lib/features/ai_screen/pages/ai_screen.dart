import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/navigation_service.dart';
import 'package:budgetbuddy/common/widgets/app_tabbar.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/budget_tab.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/coach_tab.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/goal_tab.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/over_view_tab.dart';
import 'package:budgetbuddy/features/ai_screen/pages/widget/predict.dart';
import 'package:budgetbuddy/features/buddy_chat/pages/buddy_chat_page.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Insights tab — header + pill tab bar + 5 independent tab pages.
/// All data is read inside each tab via ref.watch(provider).
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});
  @override
  ConsumerState<AiScreen> createState() => _State();
}

class _State extends ConsumerState<AiScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.c.bg,
      body: Column(
        children: [
          TabHeader(
            title: l.aiInsight,
            subtitle: 'Your money, explained',
            trailing: HeaderIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Ask Buddy',
              onTap: () => NavigationService.push(target: BuddyChatPage()),
            ),
            bottom: AppTabBar(
              controller: _tabs,
              tabs: [l.overView, l.budget, l.predict, l.goals, l.coach],
            ),
          ),
          Expanded(
            // const constructors → Flutter caches tabs not in view
            child: TabBarView(
              controller: _tabs,
              children: const [
                OverviewTab(),
                BudgetTab(),
                PredictTab(),
                GoalsTab(),
                CoachTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
