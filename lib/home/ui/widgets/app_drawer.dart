import 'package:expensetracker/ai_screen/pages/ai_screen.dart';
import 'package:expensetracker/auth/providers/auth_provider.dart';
import 'package:expensetracker/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:expensetracker/expense/ui/statemet_screen.dart';
import 'package:expensetracker/home/ui/inslight_screen.dart';
import 'package:expensetracker/profile/ui/about_page.dart';
import 'package:expensetracker/profile/ui/profile_screen.dart';
import 'package:expensetracker/profile/ui/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerWidget {
  final void Function(Widget) onPush;
  final VoidCallback onShare;
  const AppDrawer({super.key, required this.onPush, required this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final isLogged = ref.watch(isLoggedInProvider);
    final name = ref.watch(userNameProvider);
    final email = ref.watch(userEmailProvider);
    final initials = ref.watch(userInitialsProvider);
    final streak = ref.watch(budgetProvider).streakDays;

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Profile header ─────────────────────────────────────────────
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
                          isLogged ? initials : '?',
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
                          isLogged ? name : 'Guest',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isLogged ? email : 'Sign in to sync',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StreakBadge(days: streak),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Nav items ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(Assets.insights, 'Insights', null, () {
                    Navigator.pop(context);
                    onPush(const InsightsScreen());
                  }),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),

                  _DrawerItem(Assets.share, 'Share Report', kGreen, () {
                    Navigator.pop(context);
                    onShare();
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(),
                  ),
                  _DrawerItem(Assets.settings, 'Settings', null, () {
                    Navigator.pop(context);
                    onPush(const SettingsScreen());
                  }),
                  _DrawerItem(Assets.about, 'About', null, () {
                    Navigator.pop(context);
                    onPush(const AboutScreen());
                  }),
                  if (!isLogged)
                    _DrawerItem(
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

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'BudgetBuddy v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: context.c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _DrawerItem(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CommonSvgWidget(
      svgName: icon,
      color: color ?? context.c.textSub,
      height: 22,
      width: 22,
    ),
    // leading: Icon(icon, color: color ?? context.c.textSub, size: 22),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
    dense: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
