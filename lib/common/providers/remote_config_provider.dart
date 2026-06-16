import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Keys ─────────────────────────────────────────────────────────────────────
const _kAds = 'rc_ads';
const _kRewarded = 'rc_rewarded';
const _kMaintenance = 'rc_maintenance';
const _kPremium = 'rc_premium';
const _kInterstitialFreq = 'rc_interstitial_freq';

// ── Model ─────────────────────────────────────────────────────────────────────
class RemoteConfig {
  final bool adsEnabled;
  final bool rewardedAdsEnabled;
  final bool maintenanceMode;
  final bool premiumEnabled;
  final int interstitialFreq;

  const RemoteConfig({
    this.adsEnabled = true,
    this.rewardedAdsEnabled = true,
    this.maintenanceMode = false,
    this.premiumEnabled = false,
    this.interstitialFreq = 3,
  });

  // ── Supabase row → model ─────────────────────────────────────────────────
  factory RemoteConfig.fromMap(Map<String, dynamic> m) => RemoteConfig(
    adsEnabled: m['ads_enabled'] as bool? ?? true,
    rewardedAdsEnabled: m['rewarded_ads_enabled'] as bool? ?? true,
    maintenanceMode: m['maintenance_mode'] as bool? ?? false,
    premiumEnabled: m['premium_enabled'] as bool? ?? false,
    interstitialFreq: m['interstitial_freq'] as int? ?? 3,
  );

  // ── Persist to SharedPreferences for offline fallback ────────────────────
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool(_kAds, adsEnabled),
      p.setBool(_kRewarded, rewardedAdsEnabled),
      p.setBool(_kMaintenance, maintenanceMode),
      p.setBool(_kPremium, premiumEnabled),
      p.setInt(_kInterstitialFreq, interstitialFreq),
    ]);
  }

  // ── Load from SharedPreferences (offline fallback) ────────────────────────
  static Future<RemoteConfig> loadCached() async {
    final p = await SharedPreferences.getInstance();
    return RemoteConfig(
      adsEnabled: p.getBool(_kAds) ?? true,
      rewardedAdsEnabled: p.getBool(_kRewarded) ?? true,
      maintenanceMode: p.getBool(_kMaintenance) ?? false,
      premiumEnabled: p.getBool(_kPremium) ?? false,
      interstitialFreq: p.getInt(_kInterstitialFreq) ?? 3,
    );
  }

  @override
  String toString() =>
      'RemoteConfig('
      'adsEnabled: $adsEnabled, '
      'rewardedAdsEnabled: $rewardedAdsEnabled, '
      'maintenanceMode: $maintenanceMode, '
      'premiumEnabled: $premiumEnabled, '
      'interstitialFreq: $interstitialFreq)';
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() => _fetch();

  Future<RemoteConfig> _fetch() async {
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle();

      if (row == null) return RemoteConfig.loadCached();

      final cfg = RemoteConfig.fromMap(row);
      await cfg.save();
      return cfg;
    } catch (_) {
      return RemoteConfig.loadCached();
    }
  }

  /// Re-fetch from Supabase, handling errors gracefully.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig>(
      RemoteConfigNotifier.new,
    );

// ── Convenience selectors ─────────────────────────────────────────────────────
final adsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).valueOrNull?.adsEnabled ?? true,
);

final rewardedAdsEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(remoteConfigProvider).valueOrNull?.rewardedAdsEnabled ?? true,
);

final maintenanceModeProvider = Provider<bool>(
  (ref) =>
      ref.watch(remoteConfigProvider).valueOrNull?.maintenanceMode ?? false,
);

final premiumEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).valueOrNull?.premiumEnabled ?? false,
);
