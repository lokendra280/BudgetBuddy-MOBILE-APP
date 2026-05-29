import 'dart:io';
import 'package:budgetBuddy/common/remote_config/config_env.dart';
import 'package:budgetBuddy/common/providers/remote_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Ad Unit IDs from .env ─────────────────────────────────────────
class _AdIds {
  static String get banner =>
      Platform.isAndroid ? Env.bannerAndroid : Env.bannerIos;
  static String get interstitial =>
      Platform.isAndroid ? Env.interstitialAndroid : Env.interstitialIos;
  static String get rewarded =>
      Platform.isAndroid ? Env.rewardedAndroid : Env.rewardedIos;
}

// ── Ad Service ────────────────────────────────────────────────────
class AdService {
  AdService(this._ref);
  final Ref _ref;

  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static int _actionCount = 0;

  static Future<void> init() => MobileAds.instance.initialize();

  // ── Remote config helpers ─────────────────────────────────────
  bool get _adsEnabled => _ref.read(adsEnabledProvider);
  bool get _rewardedEnabled => _ref.read(rewardedAdsEnabledProvider);
  int get _interstitialFreq =>
      _ref.read(remoteConfigProvider).valueOrNull?.interstitialFreq ?? 3;

  // ── Banner ────────────────────────────────────────────────────
  BannerAd? createBanner() {
    if (!_adsEnabled) return null;
    return BannerAd(
      adUnitId: _AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdFailedToLoad: (ad, _) => ad.dispose()),
    )..load();
  }

  // ── Interstitial ──────────────────────────────────────────────
  void preloadInterstitial() {
    if (!_adsEnabled) return;
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void trackAction() {
    if (!_adsEnabled) return;
    _actionCount++;
    if (_actionCount % _interstitialFreq == 0) showInterstitial();
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
        preloadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        onDismissed?.call();
      },
    );
    _interstitial!.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────
  void preloadRewarded() {
    if (!_rewardedEnabled) return;
    RewardedAd.load(
      adUnitId: _AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void showRewarded({required VoidCallback onRewarded}) {
    if (!_rewardedEnabled || _rewarded == null) {
      onRewarded(); // graceful fallback
      return;
    }
    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewarded = null;
      },
    );
    _rewarded!.show(onUserEarnedReward: (_, __) => onRewarded());
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────
final adServiceProvider = Provider<AdService>((ref) => AdService(ref));
