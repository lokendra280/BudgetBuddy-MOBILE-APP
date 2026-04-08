import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/language_screen.dart';
import 'package:expensetracker/common/services/lang_provider.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _State();
}

class _State extends State<SettingsScreen> {
  final _limitCtrl = TextEditingController();
  bool _notif = false;

  @override
  void initState() {
    super.initState();
    _limitCtrl.text = ExpenseService.budget.monthlyLimit.toStringAsFixed(0);
    SharedPreferences.getInstance().then(
      (p) => setState(() => _notif = p.getBool('notif') ?? false),
    );
  }

  Future<void> _saveLimit() async {
    final val = double.tryParse(_limitCtrl.text);
    if (val == null || val <= 0) return;
    HapticFeedback.mediumImpact();
    final b = ExpenseService.budget;
    b.monthlyLimit = val;
    await b.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Budget updated ✓'),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleNotif(bool v) async {
    setState(() => _notif = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif', v);
    v
        ? await NotificationService.scheduleDailyReminder()
        : await NotificationService.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<Locale>(
      valueListenable: LangProvider.notifier,
      builder: (_, locale, __) {
        final lang = locale.languageCode;
        final (native, _) = LangProvider.labels[lang]!;
        final flag = LangProvider.flags[lang]!;

        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.settings,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _SecTitle(l10n.appearance),
              const SizedBox(height: 10),
              _ThemeToggle(),
              const SizedBox(height: 20),

              _SecTitle(l10n.language),
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
                            "App Language",
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: c.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SecTitle('Monthly Budget'),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    InputField(
                      hint: 'Enter monthly limit',
                      controller: _limitCtrl,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 16,
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(label: 'Save Budget', onTap: _saveLimit),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SecTitle('Notifications'),
              const SizedBox(height: 10),
              AppCard(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily reminder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get reminded to log expenses',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Switch(value: _notif, onChanged: _toggleNotif),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SecTitle('Streak'),
              const SizedBox(height: 10),
              AppCard(
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ExpenseService.budget.streakDays} day streak',
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
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeProvider.notifier,
    builder: (_, mode, __) => Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          _Btn(
            Icons.dark_mode_rounded,
            'Dark',
            mode == ThemeMode.dark,
            () => ThemeProvider.setMode(ThemeMode.dark),
          ),
          _Btn(
            Icons.light_mode_rounded,
            'Light',
            mode == ThemeMode.light,
            () => ThemeProvider.setMode(ThemeMode.light),
          ),
          _Btn(
            Icons.brightness_auto_rounded,
            'System',
            mode == ThemeMode.system,
            () => ThemeProvider.setMode(ThemeMode.system),
          ),
        ],
      ),
    ),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.active, this.onTap);

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
          color: active ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
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

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}
