import 'package:expensetracker/ai_screen/pages/ai_screen.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/home/ui/inslight_screen.dart';
import 'package:expensetracker/home/ui/widgets/drawer_button.dart';
import 'package:expensetracker/profile/ui/about_page.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/profile/ui/setting_screen.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final void Function(Widget) onPush;
  final VoidCallback onShare;
  const AppDrawer({super.key, required this.onPush, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLogged = AuthService.isLoggedIn;
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.12),
                    AppColors.primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onPush(
                        isLogged ? const ProfileScreen() : const LoginScreen(),
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                        ),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isLogged ? AuthService.userInitials : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLogged ? AuthService.userName : 'Guest',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isLogged ? AuthService.userEmail : 'Sign in to sync',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StreakBadge(days: ExpenseService.budget.streakDays),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  DrawsButton(Assets.insights, 'Insights', null, () {
                    Navigator.pop(context);
                    onPush(const InsightsScreen());
                  }),
                  DrawsButton(Assets.ai, 'AI Insights', null, () {
                    Navigator.pop(context);
                    onPush(const AiScreen());
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),

                  DrawsButton(Assets.share, 'Share Report', kGreen, () {
                    Navigator.pop(context);
                    onShare();
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),
                  DrawsButton(Assets.settings, 'Settings', null, () {
                    Navigator.pop(context);
                    onPush(const SettingsScreen());
                  }),
                  DrawsButton(Assets.about, 'About', null, () {
                    Navigator.pop(context);
                    onPush(const AboutScreen());
                  }),
                  if (!isLogged)
                    DrawsButton(
                      Assets.login,
                      'Sign In',
                      AppColors.primaryColor,
                      () {
                        Navigator.pop(context);
                        onPush(const LoginScreen());
                      },
                    ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'BudgetBuddy v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
