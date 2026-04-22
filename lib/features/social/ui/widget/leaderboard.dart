import 'package:expensetracker/common/widgets/shimmer_widget.dart';
import 'package:expensetracker/features/auth/providers/auth_provider.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/expense/providers/expense_provider.dart';
import 'package:expensetracker/features/social/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lb = ref.watch(leaderboardProvider);
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final auth = ref.watch(authProvider);
    final myId = auth.user?.id;
    final name = ref.watch(userNameProvider);
    final initials = ref.watch(userInitialsProvider);
    final all = ref.watch(monthExpensesProvider);
    final myExp = all
        .where((e) => !e.isIncome)
        .fold(0.0, (s, e) => s + e.amount);
    final c = context.c;

    return lb.when(
      loading: () => const Center(child: LeaderboardShimmer()),
      error: (_, __) =>
          _LeaderboardError(onRetry: () => ref.refresh(leaderboardProvider)),
      data: (rows) => RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async => ref.refresh(leaderboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // ── My card ────────────────────────────────────────────────────────
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        auth.isLoggedIn ? initials : '?',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isLoggedIn ? name : 'Guest',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Your spending this month',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt(myExp),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Leaderboard rows ───────────────────────────────────────────────
            if (rows.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        'No one on leaderboard yet',
                        style: TextStyle(color: c.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add expenses to appear here!',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const SectionLabel('Top Savers This Month'),
              const SizedBox(height: 12),
              ...rows.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final d = entry.value;
                final isMe = d['user_id'] == myId;
                final rname = (d['name'] as String?) ?? 'User';
                final spent = (d['spent'] as num?)?.toDouble() ?? 0.0;
                final streak = (d['streak'] as int?) ?? 0;
                final medal = rank == 1
                    ? '🥇'
                    : rank == 2
                    ? '🥈'
                    : rank == 3
                    ? '🥉'
                    : '';
                final col = rank == 1
                    ? kAmber
                    : rank == 2
                    ? c.textSub
                    : rank == 3
                    ? const Color(0xFFCD7F32)
                    : AppColors.primaryColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    color: isMe
                        ? AppColors.primaryColor.withOpacity(0.06)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: col.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              medal.isEmpty ? rname[0].toUpperCase() : medal,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? 'You ($rname)' : rname,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isMe ? AppColors.primaryColor : null,
                                ),
                              ),
                              if (streak > 0)
                                Text(
                                  '🔥 $streak day streak',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: kAmber,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '$sym${spent.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: col,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '*Lower spending = better rank 🏆',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LeaderboardError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('😕', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Text('Failed to load', style: TextStyle(color: context.c.textMuted)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
