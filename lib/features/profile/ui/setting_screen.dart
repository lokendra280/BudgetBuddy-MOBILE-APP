import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/language_screen.dart';
import 'package:budgetBuddy/common/services/notification_service.dart';
import 'package:budgetBuddy/common/theme_provider.dart';
import 'package:budgetBuddy/features/auth/providers/auth_provider.dart';
import 'package:budgetBuddy/features/auth/services/biometric_service.dart';
import 'package:budgetBuddy/features/auth/services/user_profile_service.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/profile/ui/about_page.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
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
  final _limitFocus = FocusNode();
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
    _limitFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await BiometricService.isEnabled;
    final avail = await BiometricService.isAvailable();
    if (!mounted) return;
    setState(() {
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
    _snack('Budget updated', kGreen);
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

  // Push as a proper Navigator route — NOT a bottom sheet.
  // Bottom sheets get a detached BuildContext that breaks ref.watch reactivity.
  Future<void> _selectCurrency() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CurrencyPickerPage()),
    );
    // expenseProvider version change already triggers rebuild via ref.watch above.
    // ref.invalidate is an extra safety net in case navigation timing delays it.
    if (mounted) ref.invalidate(expenseProvider);
  }

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
    // Watch root provider FIRST — version field guarantees Riverpod
    // always sees a new state on any budget/currency change
    ref.watch(expenseProvider);

    final c = context.c;
    final budget = ref.watch(budgetProvider);
    final curInfo = currencyOf(ref.watch(currencyProvider));
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final native = LocaleNotifier.labels[lang]?.$1 ?? 'English';
    final flag = LocaleNotifier.flags[lang] ?? '🇬🇧';

    if (!_limitFocus.hasFocus) {
      final newText = budget.monthlyLimit.toStringAsFixed(0);
      if (_limitCtrl.text != newText) _limitCtrl.text = newText;
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _T(AppLocalizations.of(context)!.appearance),
          const SizedBox(height: 10),
          const _ThemeToggle(),
          const SizedBox(height: 20),
          _T(AppLocalizations.of(context)!.language),
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
                      Text(
                        AppLocalizations.of(context)!.appLanguage,

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
          _T(AppLocalizations.of(context)!.selectCurrency),
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
                      Text(
                        AppLocalizations.of(context)!.displayCurrency,

                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
          _T(AppLocalizations.of(context)!.security),
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
                          Text(
                            AppLocalizations.of(context)!.biometricLock,

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
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: kGreen),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.appBiometricProtected,

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
          _T(AppLocalizations.of(context)!.monthlybudget),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                InputField(
                  hint: 'Monthly spending limit',
                  controller: _limitCtrl,
                  focusNode: _limitFocus,
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
                  label: AppLocalizations.of(context)!.saveBudget,

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
                      Text(
                        AppLocalizations.of(context)!.dailyReminder,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.getRemindedToLog,

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
          _T(AppLocalizations.of(context)!.active),
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
                        '${budget.streakDays} ${AppLocalizations.of(context)!.dayStreak}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.keepLoggingDaily,
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
          _T(AppLocalizations.of(context)!.about),
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
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).deleteAccount();
              }
            },
            child: AppCard(
              color: kAccent.withOpacity(0.07),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: kAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kAccent,
                          ),
                        ),
                        Text(
                          'To Delete Your Account Permanently',
                          style: TextStyle(fontSize: 11, color: kAccent),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: kAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency Picker Page
// Must be a full Navigator route — NOT showModalBottomSheet.
// Bottom sheets run in a separate overlay route with a detached context,
// so Consumer inside can't propagate changes back to the parent screen.
// A pushed route shares the same ProviderScope and updates correctly.
// ─────────────────────────────────────────────────────────────────────────────
class _CurrencyPickerPage extends ConsumerWidget {
  const _CurrencyPickerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final selectedCode = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Currency',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: kCurrencies.map((cur) {
          final selected = cur.code == selectedCode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.selectionClick();
                await ref
                    .read(expenseProvider.notifier)
                    .updateBudget(currency: cur.code);
                UserProfileService.saveProfile(currency: cur.code);
                if (context.mounted) Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryColor.withOpacity(0.08)
                      : c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primaryColor : c.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(cur.flag, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cur.name} (${cur.code})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.primaryColor : null,
                            ),
                          ),
                          Text(
                            'Symbol: ${cur.symbol}',
                            style: TextStyle(fontSize: 11, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.border, width: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────
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
