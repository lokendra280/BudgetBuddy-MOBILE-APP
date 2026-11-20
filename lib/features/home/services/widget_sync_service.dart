// Pushes a small snapshot of the user's day to the native home-screen
// widgets (iOS WidgetKit "StreakWidget" + Android StreakWidgetProvider).
//
// Everything is saved as a String so both platforms read it the same way
// (home_widget stores Android doubles as raw long bits, which is awkward to
// read natively). The native side only does date checks + picks the mood;
// all money formatting happens here so it matches the app's currency.
//
// Keys (shared with ios/StreakWidget/StreakWidget.swift and
// android/.../StreakWidgetProvider.kt — keep in sync):
//   bb_streak        "12"            streak days (app-open streak)
//   bb_last_active   "2026-11-18"    day the streak was last extended
//   bb_last_log      "2026-11-18"    day of the newest transaction ("" = never)
//   bb_today_date    "2026-11-18"    day bb_today_spent belongs to
//   bb_today_spent   "Rs 450"        spent today (formatted)
//   bb_month_key     "2026-11"       month the budget numbers belong to
//   bb_has_budget    "1" / "0"
//   bb_budget_left   "Rs 1,550"      budget left this month (formatted, can be "-Rs 20")
//   bb_budget_pct    "0.62"          spent / limit (not clamped; >1 = over)
//   bb_zero          "Rs 0"          formatted zero, used after midnight rollover
//   bb_hide          "1" / "0"       mask amounts (eye toggle on Home)

import 'dart:async';

import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/home/ui/widgets/home_widget_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetSyncService {
  WidgetSyncService._();

  /// iOS widget `kind` (StreakWidget.swift) and Android provider class names.
  static const iOSKind = 'StreakWidget';
  static const androidProvider = 'StreakWidgetProvider';

  static Timer? _debounce;

  /// Debounced — safe to call on every provider change.
  static void schedule({
    required List<Expense> all,
    required Budget budget,
    required String Function(double) fmt,
    required bool hideAmounts,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      sync(all: all, budget: budget, fmt: fmt, hideAmounts: hideAmounts);
    });
  }

  static Future<void> sync({
    required List<Expense> all,
    required Budget budget,
    required String Function(double) fmt,
    required bool hideAmounts,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(HomeWidgetService.iosAppGroupId);
      }

      final now = DateTime.now();
      final today = _day(now);
      final monthKey = '${now.year}-${_two(now.month)}';

      var todaySpent = 0.0;
      var monthSpent = 0.0;
      DateTime? newest;
      for (final e in all) {
        if (newest == null || e.date.isAfter(newest)) newest = e.date;
        if (e.isIncome) continue;
        if (e.date.year == now.year && e.date.month == now.month) {
          monthSpent += e.amount;
          if (e.date.day == now.day) todaySpent += e.amount;
        }
      }

      final limit = budget.monthlyLimit;
      final left = limit - monthSpent;

      final data = <String, String>{
        'bb_streak': '${budget.streakDays}',
        'bb_last_active': budget.lastActiveDate,
        'bb_last_log': newest == null ? '' : _day(newest),
        'bb_today_date': today,
        'bb_today_spent': fmt(todaySpent),
        'bb_month_key': monthKey,
        'bb_has_budget': limit > 0 ? '1' : '0',
        'bb_budget_left': left < 0 ? '-${fmt(-left)}' : fmt(left),
        'bb_budget_pct': limit > 0
            ? (monthSpent / limit).toStringAsFixed(3)
            : '0',
        'bb_zero': fmt(0),
        'bb_hide': hideAmounts ? '1' : '0',
      };

      for (final kv in data.entries) {
        await HomeWidget.saveWidgetData<String>(kv.key, kv.value);
      }

      await HomeWidget.updateWidget(
        iOSName: iOSKind,
        androidName: androidProvider,
      );
    } catch (e) {
      // Widgets are a nice-to-have — never let them break the app.
      debugPrint('[WidgetSync] $e');
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _day(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
}
