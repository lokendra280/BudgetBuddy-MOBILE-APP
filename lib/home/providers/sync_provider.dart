import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/auth/providers/auth_provider.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

enum SyncStatus { idle, syncing, success, offline, notLoggedIn, error }

class SyncNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  static Future<bool> get _online async {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  }

  Future<void> sync() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      state = SyncStatus.notLoggedIn;
      return;
    }
    if (!await _online) {
      state = SyncStatus.offline;
      return;
    }

    state = SyncStatus.syncing;
    try {
      final uid = auth.user!.id;
      final expState = ref.read(expenseProvider);

      // Push local
      final rows = expState.all
          .map(
            (e) => {
              'id': e.id,
              'user_id': uid,
              'title': e.title,
              'amount': e.amount,
              'category': e.category,
              'date': e.date.toIso8601String(),
              'is_income': e.isIncome,
              'currency': e.currency,
            },
          )
          .toList();
      if (rows.isNotEmpty)
        await _sb.from('expenses').upsert(rows, onConflict: 'id');

      // Pull remote
      final remote =
          await _sb
                  .from('expenses')
                  .select()
                  .eq('user_id', uid)
                  .order('date', ascending: false)
              as List<dynamic>;
      final notifier = ref.read(expenseProvider.notifier);
      for (final r in remote) {
        final id = (r['id'] as String?) ?? '';
        if (id.isEmpty || expState.all.any((e) => e.id == id)) continue;
        await notifier.addExpense(
          title: (r['title'] as String?) ?? '',
          amount: (r['amount'] as num?)?.toDouble() ?? 0,
          category: (r['category'] as String?) ?? 'Other',
          isIncome: (r['is_income'] as bool?) ?? false,
          date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
        );
      }
      state = SyncStatus.success;
    } catch (_) {
      state = SyncStatus.error;
    }
  }

  Future<void> deleteExpense(Expense e) async {
    await ref.read(expenseProvider.notifier).deleteExpense(e);
    if (ref.read(isLoggedInProvider) && await _online) {
      await _sb.from('expenses').delete().eq('id', e.id);
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncStatus>(
  SyncNotifier.new,
);
