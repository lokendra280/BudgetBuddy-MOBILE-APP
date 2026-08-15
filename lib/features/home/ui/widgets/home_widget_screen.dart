// lib/features/home_widget/home_widget_service.dart
//
// Bridges Flutter <-> native home screen widgets via the `home_widget` package.
// Handles:
//   1. Registering the Android widget's static click target (App Group / SharedPrefs setup)
//   2. Listening for taps on the "Add Expense" widget while the app is already running
//   3. Reading the launch URI when the app is cold-started from a widget tap
//
// Add to pubspec.yaml:
//   dependencies:
//     home_widget: ^0.6.0   // check pub.dev for the latest version

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// The custom scheme + host used by every BudgetBuddy widget action.
/// Must match:
///   - Android: HomeWidgetLaunchIntent.getActivity(..., Uri.parse(...))
///   - iOS: .widgetURL(URL(string: "..."))
///   - AndroidManifest.xml intent-filter + iOS Info.plist CFBundleURLSchemes
class WidgetDeepLinks {
  static const addExpense = 'budgetbuddy://add-expense';
  static const addIncome = 'budgetbuddy://add-income';
  static const voiceEntry = 'budgetbuddy://voice-entry';
  static const dashboard = 'budgetbuddy://dashboard';
  static const budgets = 'budgetbuddy://budgets';
  static const bills = 'budgetbuddy://bills';
}

/// Callback signature used by the app to react to a widget-originated deep link.
typedef WidgetLinkHandler = void Function(Uri uri);

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  StreamSubscription<Uri?>? _clickSub;

  /// Required on iOS only — the App Group ID you create in Xcode
  /// (Signing & Capabilities -> App Groups) shared between the app
  /// and the widget extension. Not required for this click-only widget,
  /// but set it now so future data-carrying widgets (balance, budget) work
  /// without another round of native setup.
  static const String iosAppGroupId = 'group.com.yourcompany.budgetbuddy';

  /// Call once in main(), before runApp(), or right after your Riverpod
  /// ProviderScope is mounted.
  Future<void> init({required WidgetLinkHandler onWidgetLink}) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(iosAppGroupId);
    }

    // 1) Cold start: app was closed and the user tapped the widget.
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) {
      onWidgetLink(initialUri);
    }

    // 2) Warm start: app is already running (background/foreground) and
    //    the user taps the widget again.
    _clickSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) onWidgetLink(uri);
    });
  }

  void dispose() {
    _clickSub?.cancel();
  }

  /// Call this whenever balance/budget numbers change, so a future
  /// data-driven widget (Balance Widget, Monthly Budget Widget) has fresh
  /// values to read. Safe to call even before those widgets exist.
  Future<void> syncSnapshot({
    required double availableBalance,
    required double monthlySpent,
    required double monthlyBudget,
    bool hideAmounts = false,
  }) async {
    await HomeWidget.saveWidgetData<double>(
      'availableBalance',
      availableBalance,
    );
    await HomeWidget.saveWidgetData<double>('monthlySpent', monthlySpent);
    await HomeWidget.saveWidgetData<double>('monthlyBudget', monthlyBudget);
    await HomeWidget.saveWidgetData<bool>('hideAmounts', hideAmounts);

    // Tell Android + iOS to redraw any widgets that read this data.
    await HomeWidget.updateWidget(
      androidName: 'BalanceWidgetProvider', // add when you build that widget
      iOSName: 'BudgetBuddyWidgets',
    );
  }
}
