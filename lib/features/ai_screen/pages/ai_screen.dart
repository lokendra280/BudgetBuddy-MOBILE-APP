import 'package:expensetracker/features/ai_screen/pages/widget/budget_tab.dart';
import 'package:expensetracker/features/ai_screen/pages/widget/coach_tab.dart';
import 'package:expensetracker/features/ai_screen/pages/widget/goal_tab.dart';
import 'package:expensetracker/features/ai_screen/pages/widget/over_view_tab.dart';
import 'package:expensetracker/features/ai_screen/pages/widget/predict.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Insights screen — thin shell that owns the TabController
/// and assembles the 5 independent tab pages.
///
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.c.bg,
    appBar: AppBar(
      backgroundColor: context.c.surface,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.aiInsight,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: context.c.textMuted,
        indicatorColor: AppColors.primaryColor,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.overView),
          Tab(text: AppLocalizations.of(context)!.budget),
          Tab(text: AppLocalizations.of(context)!.predict),
          Tab(text: AppLocalizations.of(context)!.goals),
          Tab(text: AppLocalizations.of(context)!.coach),
        ],
      ),
    ),
    // const constructors → Flutter caches tabs not in view
    body: TabBarView(
      controller: _tabs,
      children: const [
        OverviewTab(),
        BudgetTab(),
        PredictTab(),
        GoalsTab(),
        CoachTab(),
      ],
    ),
  );
}
