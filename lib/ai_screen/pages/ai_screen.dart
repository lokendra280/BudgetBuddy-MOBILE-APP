import 'package:expensetracker/ai_screen/pages/widget/budget_tab.dart';
import 'package:expensetracker/ai_screen/pages/widget/coach_tab.dart';
import 'package:expensetracker/ai_screen/pages/widget/goal_tab.dart';
import 'package:expensetracker/ai_screen/pages/widget/over_view_tab.dart';
import 'package:expensetracker/ai_screen/pages/widget/predict.dart';
import 'package:expensetracker/common/app_theme.dart';
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'AI Insights',
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
        tabs: const [
          Tab(text: '📊 Overview'),
          Tab(text: '💰 Budget'),
          Tab(text: '🔮 Predict'),
          Tab(text: '🎯 Goals'),
          Tab(text: '🤖 Coach'),
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
