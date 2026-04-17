import 'dart:ui';

import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/home/services/sync_services.dart';
import 'package:expensetracker/home/ui/widgets/header_button.dart';
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final double net, totalExp, totalInc;
  final Budget budget;
  final SyncResult? syncResult;
  final VoidCallback onMenuTap, onProfileTap;
  const HeaderWidget({
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nc = net >= 0 ? kGreen : kAccent;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 16,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hamburger
                GestureDetector(
                  onTap: onMenuTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 20,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTime.now().hour < 12
                            ? 'Good morning ☀️'
                            : DateTime.now().hour < 17
                            ? 'Good afternoon 👋'
                            : 'Good evening 🌙',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'BudgetBuddy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                          ),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AuthService.isLoggedIn
                              ? Text(
                                  AuthService.userInitials,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : CommonSvgWidget(
                                  svgName: Assets.profile_circle,
                                  height: 20,
                                  width: 20,
                                  color: AppColors.white,
                                ),
                        ),
                      ),
                      if (syncResult == SyncResult.success)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 10,
                                color: kGreen,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: kGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net >= 0 ? 'Net Savings' : 'Net Deficit',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${net >= 0 ? '+' : ''}${ExpenseService.fmt(net.abs())}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: nc,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    HeaderButtonWidget(
                      '↑ Expenses',
                      ExpenseService.fmt(totalExp),
                      kAccent,
                    ),
                    const SizedBox(height: 4),
                    HeaderButtonWidget(
                      '↓ Income',
                      ExpenseService.fmt(totalInc),
                      kGreen,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            BudgetBar(percent: ExpenseService.budgetUsedPercent()),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ExpenseService.fmt(totalExp)} spent',
                  style: TextStyle(fontSize: 10, color: c.textMuted),
                ),
                Text(
                  '${ExpenseService.fmt(budget.monthlyLimit)} limit',
                  style: TextStyle(fontSize: 10, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
