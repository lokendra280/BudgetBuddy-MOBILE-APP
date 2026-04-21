import 'package:expensetracker/auth/providers/auth_provider.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:expensetracker/home/providers/sync_provider.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeaderWidget extends ConsumerWidget {
  final double net, totalExp, totalInc;
  final Budget budget;
  final SyncStatus? syncResult;
  final VoidCallback onMenuTap, onProfileTap;

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
            // ── Top row: menu + greeting + avatar ────────────────────────────
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
                      Text(
                        AppLocalizations.of(context)!.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile avatar + sync badge
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
                          child: isLogged
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      if (syncResult == SyncStatus.success)
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

            // ── Net balance + expense/income labels ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net >= 0
                          ? AppLocalizations.of(context)!.netSaving
                          : AppLocalizations.of(context)!.netDeficit,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${net >= 0 ? '+' : ''}${fmt(net.abs())}',
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
                    _MiniStat(
                      '↑ ${AppLocalizations.of(context)!.expense}',
                      fmt(totalExp),
                      kAccent,
                    ),
                    const SizedBox(height: 4),
                    _MiniStat(
                      '↓ ${AppLocalizations.of(context)!.income}',
                      fmt(totalInc),
                      kGreen,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Budget progress bar ──────────────────────────────────────────
            BudgetBar(percent: budgPct),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fmt(totalExp)} spent',
                  style: TextStyle(fontSize: 10, color: c.textMuted),
                ),
                Text(
                  '${fmt(budget.monthlyLimit)} limit',
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

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontSize: 10, color: context.c.textMuted)),
      const SizedBox(width: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
