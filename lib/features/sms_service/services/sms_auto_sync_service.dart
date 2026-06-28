import 'package:budgetBuddy/features/sms_service/services/sms_parser_service.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SMS AUTO SYNC SERVICE
//
// Flow:
//   1. User grants permission → onPermissionGranted() → immediate sync
//      of last 30 days so first-time users see existing transactions
//   2. Every app open → sync() is called from HomeScreen._init()
//      reads only NEW SMS since last sync timestamp (throttled)
//   3. Permission revoked → auto-sync disables itself silently
// ─────────────────────────────────────────────────────────────────────────────

// ── Callback type alias — cleaner than repeating the full signature ──────────
typedef AddExpenseFn =
    Future<void> Function({
      required String title,
      required double amount,
      required String category,
      required bool isIncome,
      required DateTime date,
    });

class SmsAutoSyncService {
  SmsAutoSyncService._();

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kLastSync = 'sms_last_sync_ms';
  static const _kPermGranted = 'sms_permission_granted';
  static const _kAutoSync = 'sms_auto_sync_enabled';

  // ── Throttle — skip if synced within last 30 minutes ─────────────────────
  static const _kThrottleMinutes = 30;

  // ── On first grant, pull last 30 days so user sees existing transactions ──
  static const _kFirstSyncDays = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // Public state checks
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoSync) ?? false;
  }

  static Future<DateTime?> get lastSyncTime async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastSync);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // onPermissionGranted
  //
  // Call this immediately after the user taps "Allow" in the permission dialog.
  // Enables auto-sync AND triggers the first sync immediately so the user
  // sees their bank transactions right away — no second app open needed.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<int> onPermissionGranted({
    required AddExpenseFn addExpense,
    required List<dynamic> existingExpenses,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPermGranted, true);
    await prefs.setBool(_kAutoSync, true);

    // Set last sync to 30 days ago so first sync picks up recent history
    final firstSyncFrom = DateTime.now()
        .subtract(const Duration(days: _kFirstSyncDays))
        .millisecondsSinceEpoch;
    await prefs.setInt(_kLastSync, firstSyncFrom);

    debugPrint(
      '[SmsAutoSync] Permission granted — starting first sync (last $_kFirstSyncDays days)',
    );

    // Immediate sync — user sees results right away
    return sync(
      addExpense: addExpense,
      existingExpenses: existingExpenses,
      ignoreThrottle: true, // first sync always runs regardless of throttle
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // disable
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSync, false);
    debugPrint('[SmsAutoSync] Auto-sync disabled');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // sync — main entry point
  //
  // Called:
  //   • Immediately after permission granted (ignoreThrottle: true)
  //   • On every app open from HomeScreen._init() (throttled)
  //
  // Returns number of new transactions imported.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<int> sync({
    required AddExpenseFn addExpense,
    required List<dynamic> existingExpenses,
    bool ignoreThrottle = false,
  }) async {
    // ── Guard: not enabled ────────────────────────────────────────────────
    if (!await isEnabled) return 0;

    // ── Guard: permission revoked ─────────────────────────────────────────
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      await disable();
      debugPrint('[SmsAutoSync] Permission revoked — auto-sync disabled');
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();

    // ── Guard: throttle ───────────────────────────────────────────────────
    if (!ignoreThrottle) {
      final lastMs = prefs.getInt(_kLastSync) ?? 0;
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
      final throttleMs = const Duration(
        minutes: _kThrottleMinutes,
      ).inMilliseconds;
      if (elapsed < throttleMs) {
        debugPrint('[SmsAutoSync] Skipped — synced ${elapsed ~/ 60000}m ago');
        return 0;
      }
    }

    // ── Fetch SMS since last sync ─────────────────────────────────────────
    final lastSyncMs =
        prefs.getInt(_kLastSync) ??
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    final now = DateTime.now();
    debugPrint(
      '[SmsAutoSync] Syncing since ${DateTime.fromMillisecondsSinceEpoch(lastSyncMs)}',
    );

    try {
      final messages = await Telephony.instance.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThan(lastSyncMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
      );

      // Update timestamp immediately — even if 0 results, avoids re-scanning
      await prefs.setInt(_kLastSync, now.millisecondsSinceEpoch);

      if (messages == null || messages.isEmpty) {
        debugPrint('[SmsAutoSync] No new SMS since last sync');
        return 0;
      }

      debugPrint('[SmsAutoSync] ${messages.length} new SMS to scan');

      // ── Parse ─────────────────────────────────────────────────────────
      final rawList = messages
          .where((m) => (m.body ?? '').isNotEmpty)
          .map(
            (m) => (
              body: m.body ?? '',
              sender: m.address ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(m.date ?? 0),
            ),
          )
          .toList();

      final parsed = SmsParserService.parseAll(rawList);
      debugPrint('[SmsAutoSync] ${parsed.length} bank transactions found');

      if (parsed.isEmpty) return 0;

      // ── Deduplicate against existing expenses ─────────────────────────
      final existingFps = <String>{
        for (final e in existingExpenses)
          _fingerprint(
            amount: e.amount as double,
            isIncome: e.isIncome as bool,
            date: e.date as DateTime,
          ),
      };

      // ── Import new transactions ────────────────────────────────────────
      int imported = 0;
      for (final tx in parsed) {
        final fp = _fingerprint(
          amount: tx.amount,
          isIncome: tx.isIncome,
          date: tx.date,
        );
        if (existingFps.contains(fp)) continue;

        await addExpense(
          title: tx.title,
          amount: tx.amount,
          category: tx.category, // always 'Bank' from parser
          isIncome: tx.isIncome,
          date: tx.date,
        );

        existingFps.add(fp); // block duplicates within this batch
        imported++;
      }

      debugPrint('[SmsAutoSync] Imported $imported new transactions');
      return imported;
    } catch (e, stack) {
      debugPrint('[SmsAutoSync] Error: $e\n$stack');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // reset — for testing / logout
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastSync);
    await prefs.remove(_kPermGranted);
    await prefs.remove(_kAutoSync);
    debugPrint('[SmsAutoSync] Reset complete');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _fingerprint — dedup key: amount + type + truncated to minute
  // ─────────────────────────────────────────────────────────────────────────
  static String _fingerprint({
    required double amount,
    required bool isIncome,
    required DateTime date,
  }) {
    final truncated = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
    return '${amount.toStringAsFixed(2)}_${isIncome}_${truncated.millisecondsSinceEpoch}';
  }
}
