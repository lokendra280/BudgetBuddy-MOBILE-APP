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

// ── Pagination config ─────────────────────────────────────────────────────────
const _kSyncPageSize = 100;
const _kSyncThrottleMinutes = 15;

class SyncService {
  SyncService._();

  static SupabaseClient get _sb => Supabase.instance.client;
  static String? get _uid => AuthService.currentUser?.id;

  // ── Throttle key ──────────────────────────────────────────────────────────
  static String _lastSyncKey(String uid) => 'last_sync_$uid';

  static Future<bool> _shouldSync(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey(uid)) ?? 0;
    final diff = DateTime.now().millisecondsSinceEpoch - lastSync;
    return diff > const Duration(minutes: _kSyncThrottleMinutes).inMilliseconds;
  }

  static Future<void> _markSynced(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastSyncKey(uid),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

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
    'deleted_at': null, // ensure not marked deleted on push
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

  // ── Full sync (throttled) ─────────────────────────────────────────────────
  static Future<SyncResult> sync() async {
    if (!AuthService.isLoggedIn) return SyncResult.notLoggedIn;
    if (!await isOnline) return SyncResult.offline;

    final uid = _uid!;
    if (!await _shouldSync(uid)) {
      debugPrint('[SyncService] Skipped — synced recently');
      return SyncResult.skipped;
    }

    try {
      // Push first, then pull — ensures local writes win
      await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
      await Future.wait([_pullExpenses(), _pullGoals()]);
      await _markSynced(uid);
      debugPrint('[SyncService] Sync complete');
      return SyncResult.success;
    } catch (e, stack) {
      debugPrint('[SyncService] sync error: $e\n$stack');
      return SyncResult.error;
    }
  }

  // ── First login migration ─────────────────────────────────────────────────
  static Future<void> migrateOnFirstLogin() async {
    if (!await isOnline) return;
    await Future.wait([_pushExpenses(), _pushBudget(), _pushGoals()]);
    if (_uid != null) await _markSynced(_uid!);
  }

  // ── Fire-and-forget individual writes ────────────────────────────────────
  static void pushExpense(Expense e) async {
    try {
      final uid = _uid;
      if (uid == null || !await isOnline) return;
      await _sb.from('expenses').upsert(_expenseRow(e, uid), onConflict: 'id');
    } catch (err) {
      debugPrint('[SyncService] pushExpense: $err');
    }
  }

  /// Soft delete — marks row as deleted in Supabase, pull will skip it
  static void deleteExpenseRemote(String id) async {
    try {
      if (_uid == null || !await isOnline) return;
      await _sb
          .from('expenses')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _uid!);
    } catch (err) {
      debugPrint('[SyncService] deleteExpenseRemote: $err');
    }
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

  // ── Push expenses in batches of 100 ──────────────────────────────────────
  static Future<void> _pushExpenses() async {
    final uid = _uid;
    if (uid == null) return;

    final rows = HiveStorage.expenses.values
        .map((e) => _expenseRow(e, uid))
        .toList();
    if (rows.isEmpty) return;

    for (var i = 0; i < rows.length; i += _kSyncPageSize) {
      final batch = rows.sublist(i, (i + _kSyncPageSize).clamp(0, rows.length));
      await _sb.from('expenses').upsert(batch, onConflict: 'id');
    }
    debugPrint('[SyncService] Pushed ${rows.length} expenses');
  }

  // ── Pull expenses with pagination — skip soft-deleted, skip existing ──────
  static Future<void> _pullExpenses() async {
    final uid = _uid;
    if (uid == null) return;

    // Build local ID set for dedup
    final localIds = HiveStorage.expenses.values.map((e) => e.id).toSet();

    int page = 0;
    int totalAdded = 0;

    while (true) {
      final rows =
          await _sb
                  .from('expenses')
                  .select()
                  .eq('user_id', uid)
                  .filter('deleted_at', 'is', null) // exclude soft-deleted
                  .order('date', ascending: false)
                  .range(page * _kSyncPageSize, (page + 1) * _kSyncPageSize - 1)
              as List<dynamic>;

      if (rows.isEmpty) break;

      final toAdd = <Expense>[];
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        if (id.isEmpty || localIds.contains(id)) continue;

        toAdd.add(
          Expense(
            id: id,
            title: r['title'] as String? ?? '',
            amount: (r['amount'] as num?)?.toDouble() ?? 0,
            category: r['category'] as String? ?? 'Other',
            date:
                DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
            isIncome: r['is_income'] as bool? ?? false,
            currency: r['currency'] as String? ?? 'NPR',
          ),
        );
        localIds.add(id); // prevent re-adding across pages
      }

      // Batch add to Hive
      if (toAdd.isNotEmpty) {
        for (final e in toAdd) {
          await HiveStorage.expenses.add(e);
        }
        totalAdded += toAdd.length;
      }

      // Stop if last page returned fewer rows than page size
      if (rows.length < _kSyncPageSize) break;
      page++;
    }

    if (totalAdded > 0) {
      debugPrint('[SyncService] Pulled $totalAdded new expenses');
    }
  }

  // ── Goals ─────────────────────────────────────────────────────────────────
  static Future<void> _pushGoals() async {
    final uid = _uid;
    if (uid == null) return;

    final rows = HiveStorage.goals.values.map((g) => _goalRow(g, uid)).toList();
    if (rows.isEmpty) return;
    await _sb.from('savings_goals').upsert(rows, onConflict: 'id');
  }

  static Future<void> _pullGoals() async {
    final uid = _uid;
    if (uid == null) return;

    final rows =
        await _sb.from('savings_goals').select().eq('user_id', uid)
            as List<dynamic>;

    final localById = {for (final g in HiveStorage.goals.values) g.id: g};

    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      if (id.isEmpty) continue;

      final cloudSaved = (r['saved'] as num?)?.toDouble() ?? 0;

      if (localById.containsKey(id)) {
        final local = localById[id]!;
        if (cloudSaved > local.saved) {
          local.saved = cloudSaved;
          await local.save();
        }
      } else {
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
      }
    }
  }

  // ── Push budget ───────────────────────────────────────────────────────────
  static Future<void> _pushBudget() async {
    final uid = _uid;
    if (uid == null || HiveStorage.budget.isEmpty) return;
    await _sb
        .from('user_profiles')
        .upsert(
          _budgetRow(HiveStorage.budget.getAt(0)!, uid),
          onConflict: 'id',
        );
  }
}
