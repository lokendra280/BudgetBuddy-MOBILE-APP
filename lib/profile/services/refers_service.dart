import 'dart:math';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralService {
  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Generate or load existing code ────────────────────────────────────────
  static Future<String> getOrCreateCode() async {
    final budget = ExpenseService.budget;
    if (budget.referralCode != null) return budget.referralCode!;

    final code = _generate();
    budget.referralCode = code;
    await budget.save();

    // Store in Supabase if logged in
    if (AuthService.isLoggedIn) {
      await _sb.from('referrals').upsert({
        'user_id': AuthService.currentUser!.id,
        'code': code,
        'count': 0,
      }, onConflict: 'user_id');
    }
    return code;
  }

  // ── Share via OS share sheet ───────────────────────────────────────────────
  static Future<void> share(String code) => Share.share(
    '💸 I\'ve been tracking my expenses with SpendSense!\n'
    'Use my invite code "$code" to get started.\n'
    'Download: https://spendsense.app',
    subject: 'Join me on SpendSense!',
  );

  // ── Fetch count from Supabase ─────────────────────────────────────────────
  static Future<int> fetchCount() async {
    if (!AuthService.isLoggedIn) return ExpenseService.budget.referralCount;
    try {
      final row = await _sb
          .from('referrals')
          .select('count')
          .eq('user_id', AuthService.currentUser!.id)
          .maybeSingle();
      return row?['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String _generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
