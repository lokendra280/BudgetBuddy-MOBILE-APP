import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_svg_widget.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/features/home/providers/sync_provider.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Whether amounts on the balance card are masked (eye toggle).
final hideBalanceProvider = StateProvider<bool>((ref) => false);

class HeaderWidget extends ConsumerWidget {
  final double net;
  final double totalExp;
  final double totalInc;
  final Budget budget;
  final SyncStatus? syncResult;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onBillsTap;

  const HeaderWidget({
    super.key,
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
    required this.syncResult,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onBillsTap,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogged = ref.watch(isLoggedInProvider);
    final name = ref.watch(userNameProvider);
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDark
                ? [kDeepGreen.withOpacity(0.35), context.c.bg]
                : [kMint, context.c.bg],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.of(context).padding.top + 14,
          18,
          4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: context.t.bodySmall.copyWith(
                          color: kMidGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isLogged ? name : 'BudgetBuddy'} 👋',
                        style: context.t.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _Avatar(syncResult: syncResult, onTap: onProfileTap),
              ],
            ),

            const SizedBox(height: 18),

            _BalanceCard(
              net: net,
              totalExp: totalExp,
              totalInc: totalInc,
              budget: budget,
            ),

            const SizedBox(height: 20),

            // ── Quick actions ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(
                  icon: Icons.north_east_rounded,
                  label: l10n.expense,
                  onTap: onAddExpense,
                ),
                _QuickAction(
                  icon: Icons.south_west_rounded,
                  label: l10n.income,
                  onTap: onAddIncome,
                ),
                _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.bills,
                  onTap: onBillsTap,
                ),
                _QuickAction(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: onMenuTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends ConsumerWidget {
  final SyncStatus? syncResult;
  final VoidCallback onTap;
  const _Avatar({required this.syncResult, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogged = ref.watch(isLoggedInProvider);
    final initials = ref.watch(userInitialsProvider);
    final avatarUrl = ref.watch(userAvatarProvider);

    Widget inner;
    if (isLogged && avatarUrl.isNotEmpty) {
      inner = ClipOval(
        child: Image.network(
          avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(context, initials),
        ),
      );
    } else if (isLogged) {
      inner = _initials(context, initials);
    } else {
      inner = const CommonSvgWidget(
        svgName: Assets.profile_circle,
        height: 22,
        width: 22,
        color: Colors.white,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kMidGreen, AppColors.primaryColor],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: inner),
          ),
          if (syncResult == SyncStatus.success)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  size: 12,
                  color: kGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials(BuildContext context, String initials) => Text(
    initials,
    style: context.t.labelLarge.copyWith(color: Colors.white),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  final double net;
  final double totalExp;
  final double totalInc;
  final Budget budget;

  const _BalanceCard({
    required this.net,
    required this.totalExp,
    required this.totalInc,
    required this.budget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(fmtProvider);
    final hidden = ref.watch(hideBalanceProvider);
    final budgPct = ref.watch(budgetUsedPctProvider);
    final l10n = AppLocalizations.of(context)!;

    String money(double v) => hidden ? '••••••' : fmt(v);

    final savedPct = totalInc > 0 ? (net / totalInc * 100) : 0.0;
    final positive = net >= 0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeepGreen, kMidGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kDeepGreen.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glass shapes (like the card graphic in the design)
          Positioned(
            right: -30,
            top: -40,
            child: _glassCircle(150, 0.08),
          ),
          Positioned(
            right: 40,
            bottom: -60,
            child: _glassCircle(120, 0.06),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  positive ? l10n.netSaving : l10n.netDeficit,
                  style: context.t.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.80),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${positive ? '' : '-'}${money(net.abs())}',
                          style: context.t.amountLarge.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ref.read(hideBalanceProvider.notifier).state =
                              !hidden,
                      child: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: positive
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFFDA4AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        totalInc > 0
                            ? '${savedPct.toStringAsFixed(1)}% of income · ${l10n.thisMonth.toLowerCase()}'
                            : l10n.thisMonth,
                        style: context.t.caption.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Income / expense chips
                Row(
                  children: [
                    Expanded(
                      child: _CardStat(
                        icon: Icons.south_west_rounded,
                        label: l10n.income,
                        value: money(totalInc),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CardStat(
                        icon: Icons.north_east_rounded,
                        label: l10n.expense,
                        value: money(totalExp),
                      ),
                    ),
                  ],
                ),

                if (budget.monthlyLimit > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgPct,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      valueColor: AlwaysStoppedAnimation(
                        totalExp > budget.monthlyLimit
                            ? const Color(0xFFFDA4AF)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${money(totalExp)} spent',
                        style: context.t.caption.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '${money(budget.monthlyLimit)} limit',
                        style: context.t.caption.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCircle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CardStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.t.caption.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: context.t.amountSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.primaryColor.withOpacity(0.15)
                    : kMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: kMidGreen, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.t.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
