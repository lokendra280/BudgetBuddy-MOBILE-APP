import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_transaction.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:budgetBuddy/features/auth/services/auth_service.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncResult { success, offline, notLoggedIn, error, skipped }

class SyncService {
  SyncService._();

  static SupabaseClient get _sb => Supabase.instance.client;
  static String? get _uid => AuthService.currentUser?.id;

  // ── Last sync timestamp key (per user) ───────────────────────────────────
  static String _lastSyncKey(String uid) => 'last_sync_$uid';

  // ── Check if sync is needed (throttle: 15 min) ───────────────────────────
  static Future<bool> _shouldSync(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey(uid)) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSync;
    return diff > const Duration(minutes: 15).inMilliseconds;
  }

  static Future<void> _markSynced(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastSyncKey(uid),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ── Force reset sync timer (e.g. after logout) ────────────────────────────
  static Future<void> resetSyncTimer() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey(uid));
  }

  static Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  }

  // ── Public pull for goals ─────────────────────────────────────────────────
  static Future<void> pullGoals() => _pullGoals();

  // ── Row mappers ───────────────────────────────────────────────────────────
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
    'transactions': g.transactions
        .map(
          (t) => {
            'id': t.id,
            'amount': t.amount,
            'date': t.date.toIso8601String(),
          },
        )
        .toList(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  // ── Full sync (throttled — skips if synced recently) ─────────────────────
  static Future<SyncResult> sync() async {
    if (!AuthService.isLoggedIn) return SyncResult.notLoggedIn;
    if (!await isOnline) return SyncResult.offline;

    final uid = _uid!;

    // Skip if synced within last 15 minutes
    if (!await _shouldSync(uid)) {
      debugPrint('[SyncService] Skipped — synced recently');
      return SyncResult.skipped;
    }

    try {
      await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
      await Future.wait([_pullExpenses(), _pullGoals()]);
      await _markSynced(uid);
      debugPrint('[SyncService] Sync complete');
      return SyncResult.success;
    } catch (e) {
      debugPrint('[SyncService] sync error: $e');
      return SyncResult.error;
    }
  }

  // ── First login migration (always runs once) ──────────────────────────────
  static Future<void> migrateOnFirstLogin() async {
    if (!await isOnline) return;
    await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
    // Mark as synced so app open doesn't immediately re-sync
    if (_uid != null) await _markSynced(_uid!);
  }

  // ── Fire-and-forget individual pushes (called after local writes) ─────────
  static void pushExpense(Expense e) async {
    try {
      final uid = _uid;
      if (uid == null || !await isOnline) return;
      await _sb.from('expenses').upsert(_expenseRow(e, uid), onConflict: 'id');
    } catch (err) {
      debugPrint('[SyncService] pushExpense: $err');
    }
  }

  static void deleteExpenseRemote(String id) async {
    try {
      if (_uid == null || !await isOnline) return;
      await _sb.from('expenses').delete().eq('id', id);
    } catch (_) {}
  }

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

  static void deleteGoalRemote(String id) async {
    try {
      if (_uid == null || !await isOnline) return;
      await _sb.from('savings_goals').delete().eq('id', id);
    } catch (_) {}
  }

  // ── Push all expenses ─────────────────────────────────────────────────────
  static Future<void> _pushExpenses() async {
    if (_uid == null) return;
    final rows = HiveStorage.expenses.values
        .map((e) => _expenseRow(e, _uid!))
        .toList();
    if (rows.isEmpty) return;
    // Upsert in batches of 100 to avoid payload limits
    for (var i = 0; i < rows.length; i += 100) {
      final batch = rows.sublist(i, (i + 100).clamp(0, rows.length));
      await _sb.from('expenses').upsert(batch, onConflict: 'id');
    }
  }

  // ── Pull expenses — only fetch what's NOT already local ───────────────────
  static Future<void> _pullExpenses() async {
    if (_uid == null) return;

    // Build set of local IDs for fast lookup
    final localIds = HiveStorage.expenses.values.map((e) => e.id).toSet();

    final rows =
        await _sb
                .from('expenses')
                .select()
                .eq('user_id', _uid!)
                .order('date', ascending: false)
            as List<dynamic>;

    final toAdd = <Expense>[];
    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      if (id.isEmpty || localIds.contains(id)) continue; // skip duplicates

      toAdd.add(
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

    // Batch add — avoid adding one by one
    for (final e in toAdd) {
      await HiveStorage.expenses.add(e);
    }

    if (toAdd.isNotEmpty) {
      debugPrint('[SyncService] Pulled ${toAdd.length} new expenses');
    }
  }

  // ── Push all goals ────────────────────────────────────────────────────────
  static Future<void> _pushGoals() async {
    if (_uid == null) return;
    final rows = HiveStorage.goals.values
        .map((g) => _goalRow(g, _uid!))
        .toList();
    if (rows.isEmpty) return;
    await _sb.from('savings_goals').upsert(rows, onConflict: 'id');
  }

  // ── Pull goals — only update if cloud version is newer ───────────────────
  static Future<void> _pullGoals() async {
    if (_uid == null) return;

    final rows =
        await _sb.from('savings_goals').select().eq('user_id', _uid!)
            as List<dynamic>;

    final localGoals = HiveStorage.goals.values.toList();
    final localIds = {for (final g in localGoals) g.id: g};

    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      if (id.isEmpty) continue;

      final cloudSaved = (r['saved'] as num?)?.toDouble() ?? 0;

      if (localIds.containsKey(id)) {
        // Only update if cloud has higher saved amount
        final local = localIds[id]!;
        if (cloudSaved > local.saved) {
          local.saved = cloudSaved;
          await local.save();
          debugPrint('[SyncService] Updated goal $id from cloud');
        }
      } else {
        // New goal from cloud — add locally
        await HiveStorage.goals.add(
          GoalEntry(
            id: id,
            name: r['name'] as String? ?? '',
            emoji: r['emoji'] as String? ?? '🎯',
            target: (r['target'] as num?)?.toDouble() ?? 0,
            saved: cloudSaved,
            daysLeft: r['days_left'] as int? ?? 30,
            transactions: [
              GoalTransaction(id: id, amount: 0, date: DateTime.now()),
            ],
          ),
        );
        debugPrint('[SyncService] Added new goal $id from cloud');
      }
    }
  }

  // ── Push budget ───────────────────────────────────────────────────────────
  static Future<void> _pushBudget() async {
    if (_uid == null || HiveStorage.budget.isEmpty) return;
    await _sb
        .from('user_profiles')
        .upsert(
          _budgetRow(HiveStorage.budget.getAt(0)!, _uid!),
          onConflict: 'id',
        );
  }
}
