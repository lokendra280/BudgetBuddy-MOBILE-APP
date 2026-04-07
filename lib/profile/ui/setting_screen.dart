import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
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
          // ── APPEARANCE ──────────────────────────────────────────────────────
          _SectionTitle('Appearance'),
          const SizedBox(height: 10),
          _ThemeToggleCard(),
          const SizedBox(height: 24),

          // ── BUDGET ──────────────────────────────────────────────────────────
          _SectionTitle('Monthly budget'),
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
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '₹',
                      style: const TextStyle(
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
          const SizedBox(height: 24),

          // ── NOTIFICATIONS ───────────────────────────────────────────────────
          _SectionTitle('Notifications'),
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
          const SizedBox(height: 24),

          // ── STREAK ──────────────────────────────────────────────────────────
          _SectionTitle('Streak'),
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
  }
}

// ── Theme toggle card ─────────────────────────────────────────────────────────
class _ThemeToggleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.notifier,
      builder: (_, mode, __) => AppCard(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            _ModeBtn(
              icon: Icons.dark_mode_rounded,
              label: 'Dark',
              active: mode == ThemeMode.dark,
              onTap: () => ThemeProvider.setMode(ThemeMode.dark),
            ),
            _ModeBtn(
              icon: Icons.light_mode_rounded,
              label: 'Light',
              active: mode == ThemeMode.light,
              onTap: () => ThemeProvider.setMode(ThemeMode.light),
            ),
            _ModeBtn(
              icon: Icons.brightness_auto_rounded,
              label: 'System',
              active: mode == ThemeMode.system,
              onTap: () => ThemeProvider.setMode(ThemeMode.system),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: active ? Colors.white : c.textMuted),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}
