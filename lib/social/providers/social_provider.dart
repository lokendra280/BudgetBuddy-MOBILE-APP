import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:expensetracker/profile/services/refers_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

// ── Leaderboard ───────────────────────────────────────────────────────────────
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(expenseProvider); // re-fetch on expense changes
  final month =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  final data = await _sb
      .from('leaderboard')
      .select()
      .eq('month', month)
      .order('spent', ascending: true)
      .limit(20);
  return List<Map<String, dynamic>>.from(data as List);
});

// ── Referral code + count ─────────────────────────────────────────────────────
class ReferralState {
  final String? code;
  final int count;
  final bool hasUsedCode;
  final bool isLoading;
  const ReferralState({
    this.code,
    this.count = 0,
    this.hasUsedCode = false,
    this.isLoading = true,
  });
  ReferralState copyWith({
    String? code,
    int? count,
    bool? hasUsedCode,
    bool? isLoading,
  }) => ReferralState(
    code: code ?? this.code,
    count: count ?? this.count,
    hasUsedCode: hasUsedCode ?? this.hasUsedCode,
    isLoading: isLoading ?? this.isLoading,
  );
}

class ReferralNotifier extends Notifier<ReferralState> {
  @override
  ReferralState build() {
    _load();
    return const ReferralState();
  }

  Future<void> _load() async {
    final code = await ReferralService.getOrCreateCode();
    final count = await ReferralService.fetchCount();
    final hasUsed = await ReferralService.hasUsedCode();
    state = ReferralState(
      code: code,
      count: count,
      hasUsedCode: hasUsed,
      isLoading: false,
    );
  }

  Future<ApplyResult> applyCode(String code) async {
    final result = await ReferralService.applyCode(code);
    if (result == ApplyResult.success) {
      state = state.copyWith(hasUsedCode: true);
    }
    return result;
  }

  Future<void> share() async {
    if (state.code != null) await ReferralService.share(state.code!);
  }
}

final referralProvider = NotifierProvider<ReferralNotifier, ReferralState>(
  ReferralNotifier.new,
);
