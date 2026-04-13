import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserProfileService {
  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Save / update user profile in Supabase ──────────────────────────────────
  static Future<void> saveProfile({String? currency, String? language}) async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.id;
      final cur = currency ?? ExpenseService.currency;
      await _sb.from('user_profiles').upsert({
        'id': uid,
        'currency': cur,
        'language': language ?? 'en',
        'display_name': AuthService.userName,
        'avatar_url': AuthService.userAvatarUrl,
        'streak': ExpenseService.budget.streakDays,
        'monthly_limit': ExpenseService.budget.monthlyLimit,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {}
  }

  // ── Load profile from Supabase → sync to local ──────────────────────────────
  static Future<void> loadAndSync() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.id;
      final row = await _sb
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) {
        // First login — push local settings up
        await saveProfile();
        return;
      }
      // Sync currency from cloud to local
      final cloudCur = row['currency'] as String? ?? 'NPR';
      final b = ExpenseService.budget;
      if (b.currency != cloudCur) {
        b.currency = cloudCur;
        await b.save();
      }
    } catch (_) {}
  }

  // ── Update leaderboard row for this user ────────────────────────────────────
  static Future<void> updateLeaderboard() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final expenses = ExpenseService.forMonth(DateTime.now());
      await _sb.from('leaderboard').upsert({
        'user_id': AuthService.currentUser!.id,
        'name': AuthService.userName,
        'avatar': AuthService.userAvatarUrl,
        'spent': ExpenseService.expenseFor(expenses),
        'income': ExpenseService.incomeFor(expenses),
        'streak': ExpenseService.budget.streakDays,
        'currency': ExpenseService.currency,
        'month': month,
      }, onConflict: 'user_id');
    } catch (_) {}
  }
}
