// import 'dart:async';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const kPremiumId = 'spendsense_premium'; // one-time purchase
// const kPremiumSubId = 'spendsense_premium_monthly'; // optional subscription

// class PremiumService {
//   static bool _premium = false;
//   static bool get isPremium => _premium;

//   static final _iap = InAppPurchase.instance;
//   static StreamSubscription<List<PurchaseDetails>>? _sub;
//   static List<ProductDetails> products = [];

//   // ── Init ────────────────────────────────────────────────────────────────────
//   static Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     _premium = prefs.getBool('is_premium') ?? false;

//     if (!await _iap.isAvailable()) return;

//     _sub = _iap.purchaseStream.listen(_handlePurchases);

//     final res = await _iap.queryProductDetails({kPremiumId, kPremiumSubId});
//     products = res.productDetails;

//     // Restore on launch
//     await _iap.restorePurchases();
//   }

//   // ── Buy ─────────────────────────────────────────────────────────────────────
//   static Future<void> buy(ProductDetails product) => _iap.buyNonConsumable(
//     purchaseParam: PurchaseParam(productDetails: product),
//   );

//   static Future<void> restore() => _iap.restorePurchases();

//   // ── Handle stream ───────────────────────────────────────────────────────────
//   static Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
//     for (final p in purchases) {
//       if (p.status == PurchaseStatus.purchased ||
//           p.status == PurchaseStatus.restored) {
//         if (p.productID == kPremiumId || p.productID == kPremiumSubId) {
//           await _setPremium(true);
//         }
//       }
//       if (p.pendingCompletePurchase) await _iap.completePurchase(p);
//     }
//   }

//   static Future<void> _setPremium(bool v) async {
//     _premium = v;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_premium', v);
//   }

//   static void dispose() => _sub?.cancel();
// }
