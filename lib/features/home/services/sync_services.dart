import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:budgetBuddy/features/auth/services/auth_service.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncResult { success, offline, notLoggedIn, error }

class SyncService {
  SyncService._();

  static SupabaseClient get _sb => Supabase.instance.client;
  static String? get _uid => AuthService.currentUser?.id;
  // Add this public method to SyncService
  static Future<void> pullGoals() => _pullGoals();
  static Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  }

  // ── Row mappers (single source of truth) ─────────────────────
  static Map<String, dynamic> _expenseRow(Expense e, String uid) => {
    'id': e.id,
    'user_id': uid,
    'title': e.title,
    'amount': e.amount,
    'category': e.category,
    'date': e.date.toIso8601String(),
    'is_income': e.isIncome,
    'currency': e.currency,
  };

  static Map<String, dynamic> _budgetRow(Budget b, String uid) => {
    'id': uid,
    'currency': b.currency,
    'monthly_limit': b.monthlyLimit,
    'streak': b.streakDays,
    'updated_at': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> _goalRow(GoalEntry g, String uid) => {
    'id': g.id,
    'user_id': uid,
    'name': g.name,
    'emoji': g.emoji,
    'target': g.target,
    'saved': g.saved,
    'days_left': g.daysLeft,
    'updated_at': DateTime.now().toIso8601String(),
  };

  // ── Full sync ─────────────────────────────────────────────────
  static Future<SyncResult> sync() async {
    if (!AuthService.isLoggedIn) return SyncResult.notLoggedIn;
    if (!await isOnline) return SyncResult.offline;
    try {
      await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
      await Future.wait([_pullExpenses(), _pullGoals()]);
      return SyncResult.success;
    } catch (e) {
      debugPrint('[SyncService] sync error: $e');
      return SyncResult.error;
    }
  }

  static Future<void> migrateOnFirstLogin() async {
    if (!await isOnline) return;
    await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
  }

  // ── Expenses ──────────────────────────────────────────────────
  /// Fire-and-forget: called from HiveStorage after local write
  static void pushExpense(Expense e) async {
    try {
      final uid = _uid;
      if (uid == null || !await isOnline) return;
      await _sb.from('expenses').upsert(_expenseRow(e, uid), onConflict: 'id');
    } catch (err) {
      debugPrint('[SyncService] pushExpense: $err');
    }
  }

  /// Fire-and-forget: called from HiveStorage after local delete
  static void deleteExpenseRemote(String id) async {
    try {
      if (_uid == null || !await isOnline) return;
      await _sb.from('expenses').delete().eq('id', id);
    } catch (_) {}
  }

  static Future<void> _pushExpenses() async {
    if (_uid == null) return;
    final rows = HiveStorage.expenses.values
        .map((e) => _expenseRow(e, _uid!))
        .toList();
    if (rows.isEmpty) return;
    await _sb.from('expenses').upsert(rows, onConflict: 'id');
  }

  static Future<void> _pullExpenses() async {
    if (_uid == null) return;
    final rows =
        await _sb
                .from('expenses')
                .select()
                .eq('user_id', _uid!)
                .order('date', ascending: false)
            as List<dynamic>;

    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      if (id.isEmpty || HiveStorage.expenses.values.any((e) => e.id == id))
        continue;
      await HiveStorage.expenses.add(
        Expense(
          id: id,
          title: r['title'] as String? ?? '',
          amount: (r['amount'] as num?)?.toDouble() ?? 0,
          category: r['category'] as String? ?? 'Other',
          date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
          isIncome: r['is_income'] as bool? ?? false,
          currency: r['currency'] as String? ?? 'NPR',
        ),
      );
    }
  }

  // ── Budget ────────────────────────────────────────────────────
  /// Fire-and-forget: called from HiveStorage after local save
  static void pushBudget(Budget b) async {
    try {
      final uid = _uid;
      if (uid == null || !await isOnline) return;
      await _sb
          .from('user_profiles')
          .upsert(_budgetRow(b, uid), onConflict: 'id');
    } catch (err) {
      debugPrint('[SyncService] pushBudget: $err');
    }
  }

  static Future<void> _pushBudget() async {
    if (_uid == null || HiveStorage.budget.isEmpty) return;
    await _sb
        .from('user_profiles')
        .upsert(
          _budgetRow(HiveStorage.budget.getAt(0)!, _uid!),
          onConflict: 'id',
        );
  }

  // ── Goals ─────────────────────────────────────────────────────
  /// Fire-and-forget: called from HiveStorage after local write
  static void pushGoal(GoalEntry g) async {
    try {
      final uid = _uid;
      if (uid == null || !await isOnline) return;
      await _sb
          .from('savings_goals')
          .upsert(_goalRow(g, uid), onConflict: 'id');
    } catch (err) {
      debugPrint('[SyncService] pushGoal: $err');
    }
  }

  /// Fire-and-forget: called from HiveStorage after local delete
  static void deleteGoalRemote(String id) async {
    try {
      if (_uid == null || !await isOnline) return;
      await _sb.from('savings_goals').delete().eq('id', id);
    } catch (_) {}
  }

  static Future<void> _pushGoals() async {
    if (_uid == null) return;
    final rows = HiveStorage.goals.values
        .map((g) => _goalRow(g, _uid!))
        .toList();
    if (rows.isEmpty) return;
    await _sb.from('savings_goals').upsert(rows, onConflict: 'id');
  }

  static Future<void> _pullGoals() async {
    if (_uid == null) return;
    final rows =
        await _sb.from('savings_goals').select().eq('user_id', _uid!)
            as List<dynamic>;

    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      if (id.isEmpty) continue;

      final list = HiveStorage.goals.values.toList();
      final idx = list.indexWhere((g) => g.id == id);

      if (idx >= 0) {
        final g = list[idx];
        final cloudSaved = (r['saved'] as num?)?.toDouble() ?? 0;
        if (cloudSaved > g.saved) {
          g.saved = cloudSaved;
          await g.save();
        }
      } else {
        await HiveStorage.goals.add(
          GoalEntry(
            id: id,
            name: r['name'] as String? ?? '',
            emoji: r['emoji'] as String? ?? '🎯',
            target: (r['target'] as num?)?.toDouble() ?? 0,
            saved: (r['saved'] as num?)?.toDouble() ?? 0,
            daysLeft: r['days_left'] as int? ?? 30,
          ),
        );
      }
    }
  }
}
