import 'package:expensetracker/features/auth/services/auth_service.dart';
import 'package:expensetracker/features/auth/ui/login_screen.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/home/services/sync_services.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> {
  SyncResult? _lastSync;
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _lastSync = null;
    });
    final result = await SyncService.sync();
    if (mounted)
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
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your expenses will remain saved locally.',
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
              'Sign out',
              style: TextStyle(color: kAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = AuthService.currentUser;
    final name = AuthService.userName;
    final email = AuthService.userEmail;
    final avatar = AuthService.userAvatarUrl;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── Avatar + name ─────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _Avatar(url: avatar, name: name),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 13, color: c.textMuted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 12, color: kGreen),
                      SizedBox(width: 5),
                      Text(
                        'Cloud sync enabled',
                        style: TextStyle(
                          fontSize: 11,
                          color: kGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // ── Cloud Sync card ────────────────────────────────────────────────
          _SecTitle('Cloud Sync'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sync to cloud',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Back up & sync across devices',
                            style: TextStyle(fontSize: 11, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (_syncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _sync,
                        child: const Text(
                          'Sync now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),

                // Sync result
                if (_lastSync != null) ...[
                  const SizedBox(height: 10),
                  _SyncStatus(result: _lastSync!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Account info ───────────────────────────────────────────────────
          _SecTitle('Account'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                _InfoRow(Icons.email_outlined, 'Email', email),
                Divider(color: c.border, height: 20),
                _InfoRow(
                  Icons.fingerprint_rounded,
                  'User ID',
                  '${user?.id.substring(0, 8) ?? ''}…',
                ),
                Divider(color: c.border, height: 20),
                _InfoRow(Icons.verified_user_rounded, 'Status', 'Verified ✓'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sign out ───────────────────────────────────────────────────────
          AppButton(
            label: 'Sign out',
            onTap: _signOut,
            color: kAccent.withOpacity(0.15),
            icon: Icons.logout_rounded,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url, name;
  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: url.isEmpty
            ? const LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF9D8FFF)],
              )
            : null,
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials),
              ),
            )
          : _Initials(initials),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
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
      const Spacer(),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _SyncStatus extends StatelessWidget {
  final SyncResult result;
  const _SyncStatus({required this.result});

  @override
  Widget build(BuildContext context) {
    final (icon, msg, color) = switch (result) {
      SyncResult.success => (
        Icons.check_circle_rounded,
        'Synced successfully!',
        kGreen,
      ),
      SyncResult.offline => (
        Icons.wifi_off_rounded,
        'No internet connection',
        kAmber,
      ),
      SyncResult.notLoggedIn => (
        Icons.lock_outline_rounded,
        'Sign in to sync',
        context.c.textMuted,
      ),
      SyncResult.error => (
        Icons.error_outline_rounded,
        'Sync failed. Try again.',
        kAccent,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            msg,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}
