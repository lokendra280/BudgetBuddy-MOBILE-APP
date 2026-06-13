import 'package:budgetBuddy/common/widgets/app_tabbar.dart';
import 'package:budgetBuddy/common/widgets/custom_appbar.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/budget_tab.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/coach_tab.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/goal_tab.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/over_view_tab.dart';
import 'package:budgetBuddy/features/ai_screen/pages/widget/predict.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
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
    appBar: CustomAppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.message_rounded, size: 22),
                ),
              ),

              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ask AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      showBackButton: false,
      backgroundColor: context.c.surface,
      title: AppLocalizations.of(context)!.aiInsight,

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: AppTabBar(
          controller: _tabs,
          tabs: [
            AppLocalizations.of(context)!.overView,
            AppLocalizations.of(context)!.budget,
            AppLocalizations.of(context)!.predict,
            AppLocalizations.of(context)!.goals,
            AppLocalizations.of(context)!.coach,
          ],
        ),
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
