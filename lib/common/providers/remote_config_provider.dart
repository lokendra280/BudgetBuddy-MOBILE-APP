import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Remote config model ───────────────────────────────────────────────────────
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

  factory RemoteConfig.fromMap(Map<String, dynamic> m) => RemoteConfig(
    adsEnabled: m['ads_enabled'] as bool? ?? true,
    rewardedAdsEnabled: m['rewarded_ads_enabled'] as bool? ?? true,
    maintenanceMode: m['maintenance_mode'] as bool? ?? false,
    premiumEnabled: m['premium_enabled'] as bool? ?? false,
  );

  // Persist to SharedPreferences for offline fallback
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('rc_ads', adsEnabled);
    await p.setBool('rc_rewarded', rewardedAdsEnabled);
    await p.setBool('rc_maintenance', maintenanceMode);
    await p.setBool('rc_premium', premiumEnabled);
  }

  static Future<RemoteConfig> loadCached() async {
    final p = await SharedPreferences.getInstance();
    return RemoteConfig(
      adsEnabled: p.getBool('rc_ads') ?? true,
      rewardedAdsEnabled: p.getBool('rc_rewarded') ?? true,
      maintenanceMode: p.getBool('rc_maintenance') ?? false,
      premiumEnabled: p.getBool('rc_premium') ?? false,
    );
  }
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
      await cfg.save(); // cache for offline
      return cfg;
    } catch (_) {
      return RemoteConfig.loadCached(); // safe offline fallback
    }
  }

  Future<void> refresh() async => state = AsyncData(await _fetch());
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
