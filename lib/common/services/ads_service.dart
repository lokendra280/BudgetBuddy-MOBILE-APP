import 'dart:ui';

import 'package:expensetracker/common/services/premium_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

// ── Ad Unit IDs (swap test → real before release) ──────────────────────────
class _AdIds {
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // test
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
}

// ── Ad Service ────────────────────────────────────────────────────────────────
class AdService {
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static int _actionCount = 0;

  static Future<void> init() => MobileAds.instance.initialize();

  // ── Banner ──────────────────────────────────────────────────────────────────
  static BannerAd createBanner() => BannerAd(
    adUnitId: _AdIds.banner,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(onAdFailedToLoad: (ad, err) => ad.dispose()),
  )..load();

  // ── Interstitial (every 3 actions) ─────────────────────────────────────────
  static void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  static void trackAction() {
    if (PremiumService.isPremium) return;
    _actionCount++;
    if (_actionCount % 3 == 0) showInterstitial();
  }

  static void showInterstitial({VoidCallback? onDismissed}) {
    if (PremiumService.isPremium || _interstitial == null) return;
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
      },
    );
    _interstitial!.show();
  }

  // ── Rewarded (unlock advanced insight) ─────────────────────────────────────
  static void preloadRewarded() {
    RewardedAd.load(
      adUnitId: _AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  static void showRewarded({required VoidCallback onRewarded}) {
    if (_rewarded == null) {
      onRewarded();
      return;
    } // graceful fallback
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

  static void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
