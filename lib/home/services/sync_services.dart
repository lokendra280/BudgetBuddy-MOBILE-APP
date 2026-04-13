import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

class SyncService {
  static Box<Expense> get _box => Hive.box<Expense>('expenses');

  static Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  }

  static Future<SyncResult> sync() async {
    if (!AuthService.isLoggedIn) return SyncResult.notLoggedIn;
    if (!await isOnline) return SyncResult.offline;
    try {
      await _push();
      await _pull();
      return SyncResult.success;
    } catch (_) {
      return SyncResult.error;
    }
  }

  static Future<void> _push() async {
    final uid = AuthService.currentUser!.id;
    final rows = _box.values
        .map(
          (e) => {
            'id': e.id, 'user_id': uid, 'title': e.title,
            'amount': e.amount, 'category': e.category,
            'date': e.date.toIso8601String(),
            'is_income': e.isIncome, // ← synced
            'currency': e.currency, // ← synced
          },
        )
        .toList();
    if (rows.isEmpty) return;
    await _sb.from('expenses').upsert(rows, onConflict: 'id');
  }

  static Future<void> _pull() async {
    final uid = AuthService.currentUser!.id;
    final rows =
        await _sb
                .from('expenses')
                .select()
                .eq('user_id', uid)
                .order('date', ascending: false)
            as List<dynamic>;
    for (final r in rows) {
      final id = (r['id'] as String?) ?? '';
      if (id.isEmpty || _box.values.any((e) => e.id == id)) continue;
      _box.add(
        Expense(
          id: id,
          title: (r['title'] as String?) ?? '',
          amount: (r['amount'] as num?)?.toDouble() ?? 0,
          category: (r['category'] as String?) ?? 'Other',
          date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
          isIncome: (r['is_income'] as bool?) ?? false,
          currency: (r['currency'] as String?) ?? 'NPR',
        ),
      );
    }
  }

  static Future<void> deleteExpense(Expense e) async {
    await e.delete();
    if (AuthService.isLoggedIn && await isOnline)
      await _sb.from('expenses').delete().eq('id', e.id);
  }

  static Future<void> migrateOnFirstLogin() async {
    if (!await isOnline) return;
    await _push();
  }
}

enum SyncResult { success, offline, notLoggedIn, error }
