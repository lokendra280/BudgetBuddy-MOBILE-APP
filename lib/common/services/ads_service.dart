import 'dart:io';

import 'package:budgetBuddy/common/remote_config/config_env.dart';
import 'package:budgetBuddy/common/providers/remote_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Ad Unit IDs ───────────────────────────────────────────────────────────────
abstract final class AdIds {
  static String get banner =>
      Platform.isAndroid ? Env.bannerAndroid : Env.bannerIos;
  static String get interstitial =>
      Platform.isAndroid ? Env.interstitialAndroid : Env.interstitialIos;
  static String get rewarded =>
      Platform.isAndroid ? Env.rewardedAndroid : Env.rewardedIos;
}

// ── Ad Service ────────────────────────────────────────────────────────────────
class AdService {
  AdService(this._ref);
  final Ref _ref;

  // Instance fields — not static, so dispose() and provider lifecycle work correctly.
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _actionCount = 0;

  /// Call once in main() before runApp().
  static Future<void> init() => MobileAds.instance.initialize();

  // ── Remote config helpers ─────────────────────────────────────────────────
  bool get _adsEnabled => _ref.read(adsEnabledProvider);
  bool get _rewardedEnabled => _ref.read(rewardedAdsEnabledProvider);
  int get _interstitialFreq =>
      _ref.read(remoteConfigProvider).valueOrNull?.interstitialFreq ?? 3;

  // ── Banner ────────────────────────────────────────────────────────────────
  /// Returns a loaded [BannerAd] or null if ads are disabled.
  // ── Banner ────────────────────────────────────────────────────────────────
  /// Creates a banner ad. Ads-disabled → returns null immediately.
  /// [onLoaded] fires when the ad has actually finished loading — only then
  /// is it safe to pass this ad into an AdWidget.
  /// [onFailed] fires if loading fails; the ad is already disposed by then.
  BannerAd? createBanner({
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    if (!_adsEnabled) return null;
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('[AdService] Banner loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) debugPrint('[AdService] Banner failed: $error');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    )..load();
  }

  /// Convenience: returns a [Widget] ready to drop into your tree.
  /// Emits [SizedBox.shrink] when ads are disabled, so callers need no null checks.
  Widget buildBannerWidget() {
    final banner = createBanner();
    if (banner == null) return const SizedBox.shrink();
    return SizedBox(
      height: banner.size.height.toDouble(),
      width: banner.size.width.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  // ── Interstitial ──────────────────────────────────────────────────────────
  void preloadInterstitial() {
    if (!_adsEnabled) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('[AdService] Interstitial loaded');
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('[AdService] Interstitial failed: $error');
          _interstitial = null;
        },
      ),
    );
  }

  /// Call after user actions (e.g. saving a transaction).
  /// Shows an interstitial every [_interstitialFreq] actions.
  void trackAction() {
    if (!_adsEnabled) return;
    _actionCount++;
    if (_actionCount % _interstitialFreq == 0) {
      // If not loaded yet, start loading now — show next cycle.
      if (_interstitial == null) {
        preloadInterstitial();
        return;
      }
      showInterstitial();
    }
  }

  void showInterstitial({VoidCallback? onDismissed}) {
    if (!_adsEnabled || _interstitial == null) {
      onDismissed?.call();
      return;
    }

    _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        preloadInterstitial(); // ready for next time
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode)
          debugPrint('[AdService] Interstitial show failed: $error');
        ad.dispose();
        _interstitial = null;
        onDismissed?.call();
      },
    );
    _interstitial!.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────
  void preloadRewarded() {
    if (!_rewardedEnabled) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('[AdService] Rewarded loaded');
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint(
              '[AdService] Rewarded failed: ${error.code} - ${error.message}',
            );
          }
          _rewarded = null;
        },
      ),
    );
  }

  /// Shows a rewarded ad if one is ready.
  ///
  /// [onRewarded]    — called when the user earns the reward.
  /// [onNotAvailable] — called when no ad is ready (caller decides the fallback).
  ///                    If null, the reward is NOT granted automatically.
  void showRewarded({
    required VoidCallback onRewarded,
    VoidCallback? onNotAvailable,
  }) {
    if (!_rewardedEnabled || _rewarded == null) {
      if (kDebugMode) debugPrint('[AdService] Rewarded not available');
      onNotAvailable?.call();
      return;
    }

    final ad = _rewarded!;
    _rewarded = null; // clear before show to prevent double-use

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) debugPrint('[AdService] Rewarded dismissed');
        ad.dispose();
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) debugPrint('[AdService] Rewarded show failed: $error');
        ad.dispose();
        preloadRewarded();
        onNotAvailable?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode)
          debugPrint('[AdService] Reward earned: ${reward.amount}');
        onRewarded();
      },
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService(ref);
  ref.onDispose(service.dispose); // cleanup tied to provider lifecycle
  return service;
});
