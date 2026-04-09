import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

class SyncService {
  static Box<Expense> get _box => Hive.box<Expense>('expenses');

  // ── Check connectivity ──────────────────────────────────────────────────────
  static Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ── Full sync: push local → cloud, pull cloud → local ──────────────────────
  static Future<SyncResult> sync() async {
    if (!AuthService.isLoggedIn) return SyncResult.notLoggedIn;
    if (!await isOnline) return SyncResult.offline;

    try {
      await _pushLocal();
      await _pullRemote();
      return SyncResult.success;
    } catch (e) {
      return SyncResult.error;
    }
  }

  // ── Push all local Hive expenses to Supabase (upsert) ──────────────────────
  static Future<void> _pushLocal() async {
    final uid = AuthService.currentUser!.id;
    final rows = _box.values
        .map(
          (e) => {
            'id': e.id,
            'user_id': uid,
            'title': e.title,
            'amount': e.amount,
            'category': e.category,
            'date': e.date.toIso8601String(),
          },
        )
        .toList();

    if (rows.isEmpty) return;
    // upsert — safe to call multiple times (idempotent)
    await _sb.from('expenses').upsert(rows, onConflict: 'id');
  }

  // ── Pull cloud expenses → write to Hive (merge, no duplicates) ─────────────
  static Future<void> _pullRemote() async {
    final uid = AuthService.currentUser!.id;
    final rows =
        await _sb
                .from('expenses')
                .select()
                .eq('user_id', uid)
                .order('date', ascending: false)
            as List<dynamic>;

    for (final row in rows) {
      final id = row['id'] as String;
      // Only add if not already in local box
      if (!_box.values.any((e) => e.id == id)) {
        await _box.add(
          Expense(
            id: id,
            title: row['title'],
            amount: (row['amount'] as num).toDouble(),
            category: row['category'],
            date: DateTime.parse(row['date']),
          ),
        );
      }
    }
  }

  // ── Delete a single expense from both local + cloud ─────────────────────────
  static Future<void> deleteExpense(Expense e) async {
    await e.delete();
    if (AuthService.isLoggedIn && await isOnline) {
      await _sb.from('expenses').delete().eq('id', e.id);
    }
  }

  // ── Migrate local data on first sign-in ────────────────────────────────────
  static Future<void> migrateOnFirstLogin() async {
    if (!await isOnline) return;
    await _pushLocal(); // upload everything local
  }
}

enum SyncResult { success, offline, notLoggedIn, error }
