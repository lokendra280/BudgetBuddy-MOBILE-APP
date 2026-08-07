import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/home/providers/sync_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeaderWidget extends ConsumerWidget {
  final double net;
  final double totalExp;
  final double totalInc;
  final Budget budget;
  final SyncStatus? syncResult;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const HeaderWidget({
    super.key,
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final nc = net >= 0 ? kGreen : kAccent;

    final fmt = ref.watch(fmtProvider);
    final initials = ref.watch(userInitialsProvider);
    final isLogged = ref.watch(isLoggedInProvider);
    final budgPct = ref.watch(budgetUsedPctProvider);
    final name = ref.watch(userNameProvider);

    final l10n = AppLocalizations.of(context)!;

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
            // Header row
            Row(
              children: [
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
                        style: context.t.captionMuted,
                      ),

                      const SizedBox(height: 3),

                      Text(
                        isLogged ? name : "BudgetBuddy",
                        style: context.t.h3,
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                          ),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isLogged
                              ? Text(
                                  initials,
                                  style: context.t.labelLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                )
                              : CommonSvgWidget(
                                  svgName: Assets.profile_circle,
                                  height: 20,
                                  width: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),

                      if (syncResult == SyncStatus.success)
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_done_rounded,
                              size: 11,
                              color: kGreen,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "Synced",
                              style: context.t.caption.copyWith(color: kGreen),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Balance section
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net >= 0 ? l10n.netSaving : l10n.netDeficit,
                      style: context.t.labelMuted,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${net >= 0 ? '+' : ''}${fmt(net.abs())}',
                      style: context.t.amountLarge.copyWith(color: nc),
                    ),
                  ],
                ),

                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniStat('↑ ${l10n.expense}', fmt(totalExp), kAccent),

                    const SizedBox(height: 5),

                    _MiniStat('↓ ${l10n.income}', fmt(totalInc), kGreen),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            BudgetBar(percent: budgPct),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${fmt(totalExp)} spent', style: context.t.captionMuted),

                Text(
                  '${fmt(budget.monthlyLimit)} limit',
                  style: context.t.captionMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: context.t.captionMuted),

        const SizedBox(width: 6),

        Text(
          value,
          style: context.t.amountSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
