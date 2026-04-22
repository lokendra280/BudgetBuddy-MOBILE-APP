import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/features/ai_screen/services/ai_services.dart';
import 'package:expensetracker/features/expense/models/expense.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HiveStorage — single source of truth for ALL local data
//
// Rules:
//  1. Write to Hive first (offline-first, instant UI update)
//  2. If online → sync to Supabase in background (fire & forget)
//  3. Supabase Realtime / manual pull restores data on new device / login
// ─────────────────────────────────────────────────────────────────────────────

class HiveStorage {
  HiveStorage._();

  // ── Box accessors ───────────────────────────────────────────────────────────
  static Box<Expense> get expenses => Hive.box<Expense>('expenses');
  static Box<Budget> get budget => Hive.box<Budget>('budget');
  static Box<GoalEntry> get goals => Hive.box<GoalEntry>('goals');

  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Connectivity ────────────────────────────────────────────────────────────
  static Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INITIALISATION — registers adapters, opens boxes, handles migration
  // ─────────────────────────────────────────────────────────────────────────────

  static const int _schemaVersion = 5;
  static const String _versionKey = 'hive_schema_v';

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_versionKey) ?? 0;

    if (stored > 0 && stored < _schemaVersion) {
      debugPrint('[HiveStorage] Schema $stored → $_schemaVersion: wiping');
      await _wipeAndRebuild();
    } else {
      await _openWithRecovery();
    }

    await prefs.setInt(_versionKey, _schemaVersion);
    debugPrint('[HiveStorage] Ready v$_schemaVersion');
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GoalEntryAdapter());
  }

  static Future<void> _openWithRecovery() async {
    try {
      await Hive.openBox<Expense>('expenses');
      await Hive.openBox<Budget>('budget');
      await Hive.openBox<GoalEntry>('goals');
    } catch (e) {
      debugPrint('[HiveStorage] Open failed: $e — wiping');
      await _wipeAndRebuild();
    }
  }

  static Future<void> _wipeAndRebuild() async {
    for (final name in ['expenses', 'budget', 'goals']) {
      try {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      } catch (_) {}
      await Hive.deleteBoxFromDisk(name).catchError((_) {});
    }
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Budget>('budget');
    await Hive.openBox<GoalEntry>('goals');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EXPENSE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<void> addExpense(Expense e) async {
    await expenses.add(e);
    _syncExpenseToSupabase(e); // fire & forget
  }

  static Future<void> deleteExpense(Expense e) async {
    final id = e.id;
    await e.delete();
    _deleteExpenseFromSupabase(id); // fire & forget
  }

  static void _syncExpenseToSupabase(Expense e) async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null || !await isOnline) return;
      await _sb.from('expenses').upsert({
        'id': e.id,
        'user_id': uid,
        'title': e.title,
        'amount': e.amount,
        'category': e.category,
        'date': e.date.toIso8601String(),
        'is_income': e.isIncome,
        'currency': e.currency,
      }, onConflict: 'id');
    } catch (err) {
      debugPrint('[HiveStorage] expense sync error: $err');
    }
  }

  static void _deleteExpenseFromSupabase(String id) async {
    try {
      if (_sb.auth.currentUser == null || !await isOnline) return;
      await _sb.from('expenses').delete().eq('id', id);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUDGET OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  static Budget ensureBudget() {
    if (budget.isEmpty) budget.add(Budget());
    return budget.getAt(0)!;
  }

  static Future<void> saveBudget(Budget b) async {
    await b.save();
    _syncBudgetToSupabase(b); // fire & forget
  }

  static void _syncBudgetToSupabase(Budget b) async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null || !await isOnline) return;
      await _sb.from('user_profiles').upsert({
        'id': uid,
        'currency': b.currency,
        'monthly_limit': b.monthlyLimit,
        'streak': b.streakDays,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GOAL OPERATIONS — local-first, then Supabase
  // ─────────────────────────────────────────────────────────────────────────────

  /// Add a goal: saves to Hive immediately, then syncs to Supabase if online
  static Future<GoalEntry> addGoal({
    required String name,
    required String emoji,
    required double target,
    required int daysLeft,
  }) async {
    final entry = GoalEntry(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      target: target,
      saved: 0,
      daysLeft: daysLeft,
    );
    await goals.add(entry);
    _syncGoalToSupabase(entry); // fire & forget — works offline too
    return entry;
  }

  /// Add savings to a goal: updates Hive immediately, then syncs
  static Future<void> addToGoal(String id, double amount) async {
    for (final g in goals.values) {
      if (g.id == id) {
        g.saved = (g.saved + amount).clamp(0, g.target);
        await g.save();
        _syncGoalToSupabase(g);
        break;
      }
    }
  }

  /// Delete a goal from Hive and Supabase
  static Future<void> deleteGoal(String id) async {
    final idx = goals.values.toList().indexWhere((g) => g.id == id);
    if (idx >= 0) await goals.deleteAt(idx);
    _deleteGoalFromSupabase(id);
  }

  /// Read all goals as an unmodifiable list
  static List<GoalEntry> allGoals() => goals.values.toList();

  // ── Supabase sync for goals ─────────────────────────────────────────────────
  static void _syncGoalToSupabase(GoalEntry g) async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null || !await isOnline) return;
      await _sb.from('savings_goals').upsert({
        'id': g.id,
        'user_id': uid,
        'name': g.name,
        'emoji': g.emoji,
        'target': g.target,
        'saved': g.saved,
        'days_left': g.daysLeft,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (err) {
      debugPrint('[HiveStorage] goal sync error: $err');
    }
  }

  static void _deleteGoalFromSupabase(String id) async {
    try {
      if (_sb.auth.currentUser == null || !await isOnline) return;
      await _sb.from('savings_goals').delete().eq('id', id);
    } catch (_) {}
  }

  /// Pull goals from Supabase → merge into Hive (called on login / app start)
  static Future<void> pullGoalsFromSupabase() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null || !await isOnline) return;

      final rows =
          await _sb.from('savings_goals').select().eq('user_id', uid)
              as List<dynamic>;

      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        if (id.isEmpty) continue;

        final existing = goals.values.toList().indexWhere((g) => g.id == id);
        if (existing >= 0) {
          // Update if cloud has newer saved amount
          final g = goals.values.toList()[existing];
          final cloudSaved = (r['saved'] as num?)?.toDouble() ?? 0;
          if (cloudSaved > g.saved) {
            g.saved = cloudSaved;
            await g.save();
          }
        } else {
          // Insert missing goal
          await goals.add(
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
    } catch (err) {
      debugPrint('[HiveStorage] pullGoals error: $err');
    }
  }
}
