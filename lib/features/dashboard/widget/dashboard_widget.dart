import 'dart:ui';

import 'package:budgetbuddy/features/ai_screen/pages/ai_screen.dart';
import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/button.dart';
import 'package:budgetbuddy/common/common_svg_widget.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/common/navigation_service.dart';
import 'package:budgetbuddy/features/expense/ui/add_expense_screen.dart';
import 'package:budgetbuddy/features/expense/ui/statemet_screen.dart';
import 'package:budgetbuddy/features/home/ui/pages/home_screen.dart';
import 'package:budgetbuddy/features/home/ui/widgets/home_banner_ad.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:budgetbuddy/features/profile/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One tab in the glass tab bar. The icon is built with the current
/// tint so selected / unselected colors stay in one place.
class GlassTabItem {
  final Widget Function(Color color) icon;
  final String label;

  const GlassTabItem({required this.icon, required this.label});
}

/// iOS 26 style floating tab bar: a frosted-glass capsule holding the tabs,
/// with the primary "add" action as a separate round button beside it.
class GlassTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<GlassTabItem> items;
  final VoidCallback onAddTap;

  const GlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.onAddTap,
  });

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = context.isDark;

    return Padding(
      // Sits just above the home indicator, like native iOS tab bars.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset - 6 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _GlassSurface(
              height: barHeight,
              radius: barHeight / 2,
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: List.generate(items.length, (i) {
                    return Expanded(
                      child: _TabButton(
                        item: items[i],
                        selected: i == selectedIndex,
                        isDark: isDark,
                        onTap: () {
                          if (i != selectedIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onTap(i);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _AddButton(size: barHeight, onTap: onAddTap),
        ],
      ),
    );
  }
}

/// Frosted, translucent capsule with a hairline edge and soft shadow.
class _GlassSurface extends StatelessWidget {
  final double height;
  final double radius;
  final bool isDark;
  final Widget child;

  const _GlassSurface({
    required this.height,
    required this.radius,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              // Translucent version of the theme surface (AppColors.surface).
              color: context.c.surface.withOpacity(isDark ? 0.72 : 0.78),
              border: Border.all(
                color: isDark ? context.c.borderStrong : context.c.border,
                width: 0.6,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final GlassTabItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryColor : context.c.textSub;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            // Soft pill behind the selected tab, as on iOS 26.
            color: selected
                ? AppColors.primaryColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: selected ? 1.08 : 1.0,
                child: SizedBox(height: 24, child: item.icon(color)),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.t.caption
                    .colored(color)
                    .weighted(selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round primary action that sits beside the tab capsule.
class _AddButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const _AddButton({required this.size, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add expense',
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.92 : 1.0,
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor,
              border: Border.all(
                color: AppColors.white.withOpacity(0.35),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: CommonSvgWidget(
              svgName: Assets.add,
              color: AppColors.white,
              height: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({Key? key}) : super(key: key);

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _hideBottomNav = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  Future<bool> showExitPopup() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            alignment: Alignment.center,
            title: const Text('Exit App'),
            content: const Text('Do you want to exit an App?'),
            actions: [
              PrimaryButton(
                width: 85,
                onPressed: () => Navigator.of(context).pop(false),
                title: "No",
              ),
              const HomeBannerAd(),
              const SizedBox(height: 10),
              PrimaryButton(
                width: 85,
                onPressed: () => Navigator.of(context).pop(true),
                title: "Yes",
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        // Lets page content scroll behind the translucent glass bar.
        extendBody: true,
        bottomNavigationBar: _hideBottomNav
            ? null
            : GlassTabBar(
                selectedIndex: _selectedIndex,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.ease,
                  );
                },
                onAddTap: () {
                  NavigationService.push(target: AddExpenseScreen());
                },
                items: [
                  GlassTabItem(
                    label: l10n.home,
                    icon: (color) =>
                        CommonSvgWidget(svgName: Assets.home, color: color),
                  ),
                  GlassTabItem(
                    label: l10n.statements,
                    icon: (color) => CommonSvgWidget(
                      svgName: Assets.statements,
                      color: color,
                    ),
                  ),
                  GlassTabItem(
                    label: l10n.aiInsight,
                    icon: (color) =>
                        CommonSvgWidget(svgName: Assets.ai, color: color),
                  ),
                  GlassTabItem(
                    label: 'Profile',
                    icon: (color) => CommonSvgWidget(
                      svgName: Assets.profile_circle,
                      color: color,
                    ),
                  ),
                ],
              ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            HomeScreen(
              onDrawerChanged: (opened) {
                setState(() => _hideBottomNav = opened);
              },
            ),
            const StatementsScreen(),
            const AiScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
