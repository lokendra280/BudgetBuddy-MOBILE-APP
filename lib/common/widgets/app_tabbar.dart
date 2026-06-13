import 'package:budgetBuddy/common/app_theme.dart';
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
    final active = activeColor ?? AppColors.primaryColor;
    final inactive = inactiveColor ?? context.c.textMuted;

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.border, width: .5),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: active,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: active.withOpacity(.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: const EdgeInsets.all(3),
        labelColor: Colors.white,
        unselectedLabelColor: inactive,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabs
            .map(
              (t) => Tab(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(t),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
