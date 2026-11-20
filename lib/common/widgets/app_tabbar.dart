import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:flutter/material.dart';

class AppTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? activeColor;
  final Color? inactiveColor;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? kMidGreen;
    final inactive = inactiveColor ?? context.c.textSub;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: context.c.border, width: .6),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: active,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: active.withValues(alpha: .25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: Colors.white,
        unselectedLabelColor: inactive,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelLarge,
        tabs: tabs
            .map(
              (t) => Tab(
                height: 38,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(t),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
