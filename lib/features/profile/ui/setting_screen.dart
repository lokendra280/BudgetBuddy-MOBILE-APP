import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/language_screen.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/common/theme_provider.dart';
import 'package:budgetBuddy/features/auth/services/biometric_service.dart';
import 'package:budgetBuddy/features/auth/services/user_profile_service.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/profile/ui/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _State();
}

class _State extends ConsumerState<SettingsScreen> {
  final _limitCtrl = TextEditingController();
  bool _notif = false;
  bool _biometric = false;
  bool _bioAvail = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await BiometricService.isEnabled;
    final avail = await BiometricService.isAvailable();
    if (!mounted) return;
    setState(() {
      _limitCtrl.text = ref
          .read(budgetProvider)
          .monthlyLimit
          .toStringAsFixed(0);
      _notif = prefs.getBool('notif') ?? false;
      _biometric = enabled;
      _bioAvail = avail;
    });
  }

  Future<void> _saveLimit() async {
    final val = double.tryParse(_limitCtrl.text.replaceAll(',', ''));
    if (val == null || val <= 0) {
      _snack('Enter a valid amount', kAccent);
      return;
    }
    HapticFeedback.mediumImpact();
    await ref.read(expenseProvider.notifier).updateBudget(limit: val);
    _snack('Budget updated ', kGreen);
  }

  Future<void> _toggleNotif(bool v) async {
    setState(() => _notif = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif', v);
    v
        ? await NotificationService.scheduleDailyReminder()
        : await NotificationService.cancelAll();
  }

  Future<void> _toggleBio(bool v) async {
    if (v) {
      final ok = await BiometricService.authenticate(
        reason: 'Verify to enable biometric lock',
      );
      if (!ok) return;
    }
    await BiometricService.setEnabled(v);
    if (mounted) setState(() => _biometric = v);
  }

  // ── Currency picker ────────────────────────────────────────────────────────
  Future<void> _selectCurrency() => showModalBottomSheet(
    context: context,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Consumer(
      builder: (ctx, ref, __) {
        // Reactive: rebuilds inside the sheet when currency changes
        final selectedCode = ref.watch(currencyProvider);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select Currency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...kCurrencies.map((cur) {
                  final selected = cur.code == selectedCode;
                  return ListTile(
                    leading: Text(
                      cur.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      '${cur.name} (${cur.code})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Symbol: ${cur.symbol}'),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryColor,
                          )
                        : null,
                    onTap: () async {
                      // 1. Save to Hive + update ALL providers instantly
                      await ref
                          .read(expenseProvider.notifier)
                          .updateBudget(currency: cur.code);

                      // 2. Sync to Supabase (fire & forget)
                      await UserProfileService.saveProfile(currency: cur.code);

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );

  void _snack(String msg, Color col) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: col,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final budget = ref.watch(budgetProvider);
    final curInfo = currencyOf(ref.watch(currencyProvider));
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final native = LocaleNotifier.labels[lang]?.$1 ?? 'English';
    final flag = LocaleNotifier.flags[lang] ?? '🇬🇧';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _T('Appearance'),
          const SizedBox(height: 10),
          const _ThemeToggle(),
          const SizedBox(height: 20),

          const _T('Language'),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Language',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        native,
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('Currency'),
          const SizedBox(height: 10),
          AppCard(
            onTap: _selectCurrency,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      curInfo.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Display Currency',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // ✅ Watches currencyProvider — updates instantly when sheet closes
                      Text(
                        '${curInfo.name} · ${curInfo.symbol}',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('Security'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
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
                            'Biometric lock',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _bioAvail
                                ? 'Require fingerprint or face to open'
                                : 'Not available on this device',
                            style: TextStyle(fontSize: 11, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _biometric,
                      onChanged: _bioAvail ? _toggleBio : null,
                    ),
                  ],
                ),
                if (_biometric) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: kGreen),
                        SizedBox(width: 8),
                        Text(
                          'App is biometric-protected',
                          style: TextStyle(
                            fontSize: 11,
                            color: kGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('Monthly Budget'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                InputField(
                  hint: 'Monthly spending limit',
                  controller: _limitCtrl,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      curInfo.symbol,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Save Budget',
                  onTap: _saveLimit,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('Notifications'),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: kAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily reminder',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Get reminded to log expenses',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(value: _notif, onChanged: _toggleNotif),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('Activity'),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: kAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${budget.streakDays} day streak',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Keep logging daily to maintain it',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                if (budget.streakDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🔥 ${budget.streakDays}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kAmber,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _T('About'),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
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
                        'About BudgetBuddy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Version, markets, legal',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
              ],
            ),
          ),

          // const SizedBox(height: 20),
          // AppCard(
          //   color: kAccent.withOpacity(0.07),
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 36,
          //         height: 36,
          //         decoration: BoxDecoration(
          //           color: kAccent.withOpacity(0.20),
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: const Icon(
          //           Icons.delete_outline_rounded,
          //           color: kAccent,
          //           size: 20,
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: const [
          //             Text(
          //               'Delete Account',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w600,
          //                 color: kAccent,
          //               ),
          //             ),
          //             Text(
          //               'This action cannot be undone',
          //               style: TextStyle(fontSize: 11, color: kAccent),
          //             ),
          //           ],
          //         ),
          //       ),
          //       Icon(Icons.chevron_right_rounded, color: kAccent, size: 20),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          _B(
            Icons.dark_mode_rounded,
            'Dark',
            mode == ThemeMode.dark,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.dark),
          ),
          _B(
            Icons.light_mode_rounded,
            'Light',
            mode == ThemeMode.light,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.light),
          ),
          _B(
            Icons.brightness_auto_rounded,
            'System',
            mode == ThemeMode.system,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _B extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _B(this.icon, this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : context.c.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : context.c.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _T extends StatelessWidget {
  final String text;
  const _T(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}
