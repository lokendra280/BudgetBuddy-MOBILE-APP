import 'dart:math' as math;

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetbuddy/features/auth/services/auth_service.dart';
import 'package:budgetbuddy/features/auth/ui/login_screen.dart';
import 'package:budgetbuddy/features/bill_reminder/ui/pages/commitments_screen.dart';
import 'package:budgetbuddy/features/budgeting/ui/pages/budget_planner_screen.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/features/home/services/sync_services.dart';
import 'package:budgetbuddy/features/profile/ui/about_page.dart';
import 'package:budgetbuddy/features/profile/ui/setting_screen.dart';
import 'package:budgetbuddy/features/social/ui/pages/social_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Profile tab (also pushed from the Home avatar — shows a back arrow then).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileScreen> {
  SyncResult? _lastSync;
  bool _syncing = false;

  void _push(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _lastSync = null;
    });
    final result = await SyncService.sync();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _lastSync = result;
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your expenses will remain saved on this device.',
          style: TextStyle(color: context.c.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: context.c.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: kAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.signOut();
    if (!mounted) return;
    // Pushed from Home → go back. As a tab → stay; the page rebuilds as guest.
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showAccountSheet() {
    final user = ref.read(currentUserProvider);
    final email = ref.read(userEmailProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.c.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Personal Information', style: ctx.t.h4),
              const SizedBox(height: 16),
              _InfoRow(Icons.email_outlined, 'Email', email),
              Divider(color: ctx.c.border, height: 24),
              _InfoRow(
                Icons.fingerprint_rounded,
                'User ID',
                user == null ? '—' : '${user.id.substring(0, 8)}…',
              ),
              Divider(color: ctx.c.border, height: 24),
              _InfoRow(
                Icons.verified_user_outlined,
                'Status',
                user?.emailConfirmedAt != null ? 'Verified ✓' : 'Signed in',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogged = ref.watch(isLoggedInProvider);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.c.bg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.of(context).padding.top + 8,
          18,
          // room for the floating glass tab bar
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Row(
            children: [
              if (canPop)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: context.textPrimary,
                ),
                onPressed: () => _push(const SettingsScreen()),
              ),
            ],
          ),

          // ── Avatar + name ────────────────────────────────────────────────
          _ProfileHeader(isLogged: isLogged),
          const SizedBox(height: 18),

          // ── Financial health ─────────────────────────────────────────────
          const _HealthCard(),
          const SizedBox(height: 18),

          // ── Menu ─────────────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                if (isLogged) ...[
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Information',
                    onTap: _showAccountSheet,
                  ),
                  _MenuTile(
                    icon: Icons.cloud_sync_outlined,
                    label: 'Cloud Sync',
                    trailing: _SyncTrailing(
                      syncing: _syncing,
                      result: _lastSync,
                    ),
                    onTap: _sync,
                  ),
                ],
                _MenuTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Budget Planner',
                  onTap: () => _push(const BudgetPlannerScreen()),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Bills & EMIs',
                  onTap: () => _push(const CommitmentsScreen()),
                ),
                _MenuTile(
                  icon: Icons.groups_outlined,
                  label: 'Community',
                  onTap: () => _push(const SocialScreen()),
                ),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & About',
                  onTap: () => _push(const AboutScreen()),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _push(const SettingsScreen()),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Log out / Sign in ────────────────────────────────────────────
          _BottomAction(
            isLogged: isLogged,
            onTap: isLogged ? _signOut : () => _push(const LoginScreen()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  final bool isLogged;
  const _ProfileHeader({required this.isLogged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = isLogged ? ref.watch(userNameProvider) : 'Guest';
    final email = isLogged
        ? ref.watch(userEmailProvider)
        : 'Sign in to back up your data';
    final avatar = isLogged ? ref.watch(userAvatarProvider) : '';
    final initials = isLogged ? ref.watch(userInitialsProvider) : '';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [kMidGreen, AppColors.primaryColor],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: avatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Initials(initials),
                  ),
                )
              : isLogged
              ? _Initials(initials)
              : const Icon(Icons.person_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: context.t.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: context.t.bodySmall.copyWith(color: context.c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text.isEmpty ? '?' : text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial health — a 0–100 score from this month's data.
//   60% savings rate (saving ≥50% of income = full marks)
//   40% budget adherence (less of the budget used = better; over = 0)
// ─────────────────────────────────────────────────────────────────────────────

class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  static int? _score(double income, double expense, double limit) {
    if (income == 0 && expense == 0) return null; // nothing to judge yet

    final savingsRate = income > 0 ? (income - expense) / income : -1.0;
    final s1 = (savingsRate.clamp(0.0, 0.5)) / 0.5;

    double s2;
    if (limit <= 0) {
      s2 = 0.5; // no budget set — neutral
    } else {
      final used = expense / limit;
      s2 = used > 1 ? 0 : 1 - used * 0.5;
    }
    return ((s1 * 0.6 + s2 * 0.4) * 100).round().clamp(0, 100);
  }

  static (String, String) _label(int? score) {
    if (score == null) {
      return ('Getting started', 'Add a few transactions to see your score.');
    }
    if (score >= 80) {
      return ('Excellent', "Keep going! You're on the right track.");
    }
    if (score >= 60) return ('Good', 'Nice work — a little more saving helps.');
    if (score >= 40) return ('Fair', 'Try trimming a category or two.');
    return ('Needs attention', 'Spending is outpacing your income.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthTotalIncomeProvider);
    final expense = ref.watch(monthTotalExpenseProvider);
    final limit = ref.watch(budgetProvider).monthlyLimit;

    final score = _score(income, expense, limit);
    final (title, subtitle) = _label(score);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeepGreen, kMidGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kDeepGreen.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Financial Health',
                        style: context.t.caption.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: context.t.h3.copyWith(
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (score != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              score >= 60
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: context.t.caption.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ScoreRing(score: score),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int? score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score ?? 0) / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Text(
              score == null ? '—' : '${(v * 100).round()}%',
              style: context.t.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(0.18),
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6EE7B7),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ─────────────────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 21, color: context.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: context.t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.c.textMuted,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 51,
            endIndent: 16,
            color: context.c.border,
          ),
      ],
    );
  }
}

class _SyncTrailing extends StatelessWidget {
  final bool syncing;
  final SyncResult? result;
  const _SyncTrailing({required this.syncing, required this.result});

  @override
  Widget build(BuildContext context) {
    if (syncing) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryColor,
        ),
      );
    }
    final (text, color) = switch (result) {
      SyncResult.success => ('Synced ✓', kGreen),
      SyncResult.skipped => ('Up to date', kGreen),
      SyncResult.offline => ('Offline', kAmber),
      SyncResult.notLoggedIn => ('Sign in', context.c.textMuted),
      SyncResult.error => ('Failed', kAccent),
      null => ('Sync now', AppColors.primaryColor),
    };
    return Text(
      text,
      style: context.t.buttonSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final bool isLogged;
  final VoidCallback onTap;
  const _BottomAction({required this.isLogged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isLogged ? kAccent : kMidGreen;
    return Material(
      color: color.withOpacity(context.isDark ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLogged ? Icons.logout_rounded : Icons.login_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isLogged ? 'Log Out' : 'Sign In',
                style: context.t.button.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: context.c.textMuted),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 13, color: context.c.textMuted)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
