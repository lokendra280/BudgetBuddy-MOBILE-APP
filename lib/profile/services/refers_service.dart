import 'dart:math';
import 'package:expensetracker/auth/services/auth_service.dart';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ApplyResult { success, notFound, alreadyUsed, ownCode, notLoggedIn, error }

// Benefits a user gets for applying a referral code
const int kReferralStreakBonus = 3; // +3 days streak
const double kReferralBudgetBonus = 500; // +₹500 budget bonus month (optional)

class ReferralService {
  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Get or create this user's own code ───────────────────────────────────────
  static Future<String> getOrCreateCode() async {
    final budget = ExpenseService.budget;
    if (budget.referralCode != null) return budget.referralCode!;

    final code = _generate();
    budget.referralCode = code;
    await budget.save();

    if (AuthService.isLoggedIn) {
      await _sb
          .from('referrals')
          .upsert({
            'user_id': AuthService.currentUser!.id,
            'code': code,
            'count': 0,
          }, onConflict: 'user_id')
          .catchError((_) {});
    }
    return code;
  }

  // ── Apply a friend's code with full validation ────────────────────────────────
  static Future<ApplyResult> applyCode(String input) async {
    if (!AuthService.isLoggedIn) return ApplyResult.notLoggedIn;

    final code = input.trim().toUpperCase();
    if (code.length < 4) return ApplyResult.notFound;

    final myId = AuthService.currentUser!.id;
    final myCode = ExpenseService.budget.referralCode?.toUpperCase();

    // Cannot use own code
    if (myCode != null && code == myCode) return ApplyResult.ownCode;

    try {
      // Check if this user already applied a code
      final existing = await _sb
          .from('referral_uses')
          .select('id')
          .eq('used_by', myId)
          .maybeSingle();
      if (existing != null) return ApplyResult.alreadyUsed;

      // Find the referrer's row
      final referrerRow = await _sb
          .from('referrals')
          .select('user_id, count')
          .eq('code', code)
          .maybeSingle();
      if (referrerRow == null) return ApplyResult.notFound;

      final referrerId = referrerRow['user_id'] as String;
      final currentCount = referrerRow['count'] as int? ?? 0;

      // Cannot use your own code even if stored differently
      if (referrerId == myId) return ApplyResult.ownCode;

      // Record the use
      await _sb.from('referral_uses').insert({
        'code': code,
        'used_by': myId,
        'referrer_id': referrerId,
      });

      // Increment referrer's count
      await _sb
          .from('referrals')
          .update({'count': currentCount + 1})
          .eq('code', code);

      // Give BOTH users streak bonus locally
      final b = ExpenseService.budget;
      b.streakDays = (b.streakDays + kReferralStreakBonus).clamp(0, 9999);
      await b.save();

      // Also bump the referrer's streak in their leaderboard row (best effort)
      try {
        final refLB = await _sb
            .from('leaderboard')
            .select('streak')
            .eq('user_id', referrerId)
            .maybeSingle();
        if (refLB != null) {
          await _sb
              .from('leaderboard')
              .update({
                'streak':
                    ((refLB['streak'] as int? ?? 0) + kReferralStreakBonus),
              })
              .eq('user_id', referrerId);
        }
      } catch (_) {}

      return ApplyResult.success;
    } catch (_) {
      return ApplyResult.error;
    }
  }

  // ── Check if user already used a code ────────────────────────────────────────
  static Future<bool> hasUsedCode() async {
    if (!AuthService.isLoggedIn) return false;
    try {
      final r = await _sb
          .from('referral_uses')
          .select('id')
          .eq('used_by', AuthService.currentUser!.id)
          .maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  // ── Fetch referral count from Supabase ────────────────────────────────────────
  static Future<int> fetchCount() async {
    if (!AuthService.isLoggedIn) return 0;
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

  // ── Share the invite code via OS share sheet ──────────────────────────────────
  static Future<void> share(String code) => Share.share(
    '💸 Hey! I use SpendSense to track my expenses.\n\n'
    '📲 Download SpendSense and enter my invite code:\n'
    '🔑 $code\n\n'
    'When you sign up and apply my code in Community → Invite tab, we BOTH get:\n'
    '🔥 +$kReferralStreakBonus bonus streak days\n'
    '📊 Appear on the savings leaderboard together\n\n'
    'Download: https://play.google.com/store/apps/details?id=com.spendsense',
    subject: 'Join SpendSense with my invite code: $code',
  );

  // ── Generate a random 6-char code ─────────────────────────────────────────────
  static String _generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
