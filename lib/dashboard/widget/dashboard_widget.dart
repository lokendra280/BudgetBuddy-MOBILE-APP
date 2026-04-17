import 'package:expensetracker/ai_screen/pages/ai_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/button.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/navigation_service.dart';
import 'package:expensetracker/expense/ui/add_expense_screen.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/ui/pages/home_screen.dart';
import 'package:expensetracker/social/ui/social_screen.dart';
import 'package:flutter/material.dart';

class NavigationDestination {
  final Widget icon;
  final String label;

  const NavigationDestination({required this.icon, required this.label});
}

class NavigationBar extends StatelessWidget {
  final double height;
  final double elevation;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const NavigationBar({
    super.key,
    required this.height,
    required this.elevation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,

      elevation: elevation,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.darkGrey,
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      items: destinations.map((destination) {
        return BottomNavigationBarItem(
          icon: destination.icon,
          label: destination.label,
        );
      }).toList(),
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
                //return false when click on "NO"
                title: "No",
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                width: 85,
                onPressed: () => Navigator.of(context).pop(true),
                //return false when click on "NO"
                title: "Yes",
              ),
            ],
          ),
        ) ??
        false; //if showDialouge had returned null, then return false
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
            );
          },
          destinations: [
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.home,
                color: _selectedIndex == 0
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Home",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.statements,
                color: _selectedIndex == 1
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Statements",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.social,
                color: _selectedIndex == 2
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Social",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.ai,
                color: _selectedIndex == 3
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "AI Insights",
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            const HomeScreen(),
            const StatementsScreen(),
            const SocialScreen(),
            const AiScreen(),
          ],
        ),
        floatingActionButton: SizedBox(
          height: 50,
          width: 50,

          child: FloatingActionButton(
            elevation: 2,
            backgroundColor: AppColors.primaryColor,
            // mini: false,
            child: CommonSvgWidget(
              svgName: Assets.add,
              color: Colors.white,
              height: 25,
            ),
            onPressed: () {
              NavigationService.push(target: AddExpenseScreen());
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
