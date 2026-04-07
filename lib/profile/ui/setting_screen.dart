import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/services/notification_service.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';

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
    final b = ExpenseService.budget;
    b.monthlyLimit = val;
    await b.save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget updated ✓'),
        backgroundColor: kGreen,
      ),
    );
  }

  Future<void> _toggleNotif(bool v) async {
    setState(() => _notif = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif', v);
    if (v) {
      await NotificationService.scheduleDailyReminder();
    } else {
      await NotificationService.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kSurface,
      elevation: 0,
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
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Monthly budget'),
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
          const SectionLabel('Notifications'),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily reminder',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get reminded to log expenses',
                      style: TextStyle(fontSize: 11, color: kTextMuted),
                    ),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: _notif,
                  onChanged: _toggleNotif,
                  activeColor: kPrimary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionLabel('Streak'),
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
                    const Text(
                      'Keep logging daily to maintain it',
                      style: TextStyle(fontSize: 11, color: kTextMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
