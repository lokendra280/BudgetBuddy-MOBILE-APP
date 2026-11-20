import 'dart:math' as math;

import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/common_widget.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/services/home_service.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:budgetbuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetbuddy/features/auth/services/auth_service.dart';
import 'package:budgetbuddy/features/auth/ui/login_screen.dart';
import 'package:budgetbuddy/features/bill_reminder/ui/pages/commitments_screen.dart';
import 'package:budgetbuddy/features/budgeting/ui/pages/budget_planner_screen.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetbuddy/features/home/services/sync_services.dart';
import 'package:budgetbuddy/features/profile/ui/about_page.dart';
import 'package:budgetbuddy/features/profile/ui/currency_screen.dart';
import 'package:budgetbuddy/common/language_screen.dart';
import 'package:budgetbuddy/common/services/notification_service.dart';
import 'package:budgetbuddy/common/theme_provider.dart';
import 'package:budgetbuddy/features/auth/services/biometric_service.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Settings
  bool _notif = false;
  bool _lockOn = false;
  BiometricKind? _bio;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lockOn = await BiometricService.isEnabled;
    final bio = await BiometricService.kind();
    if (!mounted) return;
    setState(() {
      _notif = prefs.getBool('notif') ?? false;
      _lockOn = lockOn;
      _bio = bio;
    });
  }

  Future<void> _toggleNotif(bool v) async {
    HapticFeedback.selectionClick();
    setState(() => _notif = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif', v);
    v
        ? await NotificationService.scheduleDailyReminder()
        : await NotificationService.cancelDailyReminder();
  }

  Future<void> _toggleLock(bool v) async {
    HapticFeedback.selectionClick();
    final bio = _bio;
    if (v) {
      if (bio == null || !bio.available) {
        _snack(bio?.subtitle ?? 'Not available on this device', kAmber);
        return;
      }
      final ok = await BiometricService.authenticate(
        reason: 'Verify to turn on ${bio.title}',
      );
      if (!ok) return;
    }
    await BiometricService.setEnabled(v);
    if (!mounted) return;
    setState(() => _lockOn = v);
    _snack(
      v ? '${bio?.title ?? 'Lock'} is on' : '${bio?.title ?? 'Lock'} is off',
      v ? kGreen : context.c.textSub,
    );
  }

  Future<void> _openCurrency() async {
    await _push(const CurrencyPickerPage());
    if (mounted) ref.invalidate(expenseProvider);
  }

  Future<void> _editBudget() async {
    final budget = ref.read(budgetProvider);
    final sym = currencyOf(ref.read(currencyProvider)).symbol;
    final saved = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BudgetSheet(initial: budget.monthlyLimit, symbol: sym),
    );
    if (saved == null) return;
    await ref.read(expenseProvider.notifier).updateBudget(limit: saved);
    _snack('Monthly budget updated', kGreen);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.card,
        title: Text('Delete account?', style: context.t.h3),
        content: Text(
          'This permanently deletes your account and cloud backup. '
          'This can\'t be undone.',
          style: context.t.bodySub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: context.t.buttonSmall),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  void _snack(String msg, Color col) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: col,
          behavior: SnackBarBehavior.floating,
        ),
      );

  Future<void> _push(Widget s) =>
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
    ref.watch(expenseProvider); // rebuild on budget / currency changes
    final budget = ref.watch(budgetProvider);
    final fmt = ref.watch(fmtProvider);
    final cur = currencyOf(ref.watch(currencyProvider));
    final lang = ref.watch(localeProvider).languageCode;
    final langLabel = LocaleNotifier.labels[lang]?.$1 ?? 'English';

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
          // ── Top bar (back arrow only when pushed from Home) ─────────────
          if (canPop)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          else
            const SizedBox(height: 12),

          // ── Avatar + name ────────────────────────────────────────────────
          _ProfileHeader(isLogged: isLogged),
          const SizedBox(height: 18),

          // ── Financial health ─────────────────────────────────────────────
          const _HealthCard(),
          const SizedBox(height: 22),

          // ── Preferences ──────────────────────────────────────────────────
          const _GroupLabel('Preferences'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: _ThemeSegment(),
                ),
                Divider(height: 1, color: context.c.border),
                _MenuTile(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  value: langLabel,
                  onTap: () => _push(const LanguageScreen()),
                ),
                _MenuTile(
                  icon: Icons.currency_exchange_rounded,
                  label: 'Currency',
                  value: '${cur.code} · ${cur.symbol}',
                  onTap: _openCurrency,
                ),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Monthly budget',
                  value: budget.monthlyLimit > 0
                      ? fmt(budget.monthlyLimit)
                      : 'Not set',
                  onTap: _editBudget,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Security & notifications ─────────────────────────────────────
          const _GroupLabel('Security & notifications'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _SwitchTile(
                  icon: _bio?.icon ?? Icons.lock_outline_rounded,
                  label: _bio?.title ?? 'App lock',
                  subtitle: _bio == null
                      ? 'Checking…'
                      : _bio!.available
                      ? _bio!.subtitle
                      : _bio!.subtitle,
                  value: _lockOn,
                  enabled: _bio?.available ?? false,
                  onChanged: _toggleLock,
                ),
                _SwitchTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Daily reminder',
                  subtitle: 'A nudge to log your spending',
                  value: _notif,
                  onChanged: _toggleNotif,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Tools ────────────────────────────────────────────────────────
          const _GroupLabel('Tools'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
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
                  icon: Icons.widgets_outlined,
                  label: 'Home screen widget',
                  trailing: const _NewBadge(),
                  onTap: () => WidgetIntro.show(context),
                ),
                _MenuTile(
                  icon: Icons.groups_outlined,
                  label: 'Community',
                  onTap: () => _push(const SocialScreen()),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Account ──────────────────────────────────────────────────────
          const _GroupLabel('Account & support'),
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
                  icon: Icons.help_outline_rounded,
                  label: 'Help & About',
                  value: 'Version, legal',
                  onTap: () => _push(const AboutScreen()),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AdSlot(),

          // ── Log out / Sign in ────────────────────────────────────────────
          _BottomAction(
            isLogged: isLogged,
            onTap: isLogged ? _signOut : () => _push(const LoginScreen()),
          ),
          if (isLogged) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _deleteAccount,
                child: Text(
                  'Delete account',
                  style: context.t.labelSmall.colored(kAccent),
                ),
              ),
            ),
          ],
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
    final streak = ref.watch(budgetProvider).streakDays;

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
              if (streak > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔥 $streak-day streak',
                    style: context.t.labelSmall.copyWith(
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                              style: context.t.h3.copyWith(color: Colors.white),
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
  final String? value;
  final bool showDivider;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.value,
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
                _TileIcon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: context.t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (value != null) ...[
                  Flexible(
                    child: Text(
                      value!,
                      style: context.t.bodySub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
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
            indent: 60,
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

class _NewBadge extends StatelessWidget {
  const _NewBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: kMidGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'NEW',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(text.toUpperCase(), style: context.t.overline),
  );
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon(this.icon);
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: context.isDark ? kMidGreen.withValues(alpha: 0.2) : kMint,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      icon,
      size: 19,
      color: context.isDark ? Colors.white : kMidGreen,
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            _TileIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(subtitle, style: context.t.labelMuted),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: kMidGreen,
              onChanged: enabled || value ? onChanged : null,
            ),
          ],
        ),
      ),
      if (showDivider)
        Divider(height: 1, indent: 60, endIndent: 16, color: context.c.border),
    ],
  );
}

/// Dark / Light / System segmented control.
class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    Widget seg(ThemeMode m, IconData i, String label) {
      final active = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeProvider.notifier).setMode(m);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? kMidGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  i,
                  size: 17,
                  color: active ? Colors.white : context.c.textSub,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.t.labelLarge.colored(
                    active ? Colors.white : context.c.textSub,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.cardElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          seg(ThemeMode.light, Icons.light_mode_rounded, 'Light'),
          seg(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
          seg(ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
        ],
      ),
    );
  }
}

/// Bottom sheet to edit the monthly budget. Pops with the new value.
class _BudgetSheet extends StatefulWidget {
  final double initial;
  final String symbol;
  const _BudgetSheet({required this.initial, required this.symbol});
  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final _ctrl = TextEditingController(
    text: widget.initial > 0 ? widget.initial.toStringAsFixed(0) : '',
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '').trim());
    if (v == null || v <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.c.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Monthly budget', style: context.t.h3),
          const SizedBox(height: 4),
          Text(
            'How much do you want to spend each month?',
            style: context.t.bodySub,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: context.t.h2,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              prefixText: '${widget.symbol} ',
              prefixStyle: context.t.h2.colored(kMidGreen),
              errorText: _error,
              filled: true,
              fillColor: context.c.cardElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kMidGreen, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: kMidGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Save budget',
                style: context.t.button.colored(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
