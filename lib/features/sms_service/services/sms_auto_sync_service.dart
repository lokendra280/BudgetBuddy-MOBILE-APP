import 'package:budgetBuddy/features/sms_service/services/sms_parser_service.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SMS AUTO SYNC SERVICE
//
// Once the user grants SMS permission (via SmsImportScreen), this service
// runs silently in the background:
//   • On every app open (splash screen)
//   • Reads only NEW SMS since the last sync timestamp
//   • Parses + deduplicates + imports — no UI required
//   • Stores last sync timestamp in SharedPreferences
//
// The user never has to open the SMS import screen again after the first time.
// ─────────────────────────────────────────────────────────────────────────────
class SmsAutoSyncService {
  static const _lastSyncKey = 'sms_last_sync_ms';
  static const _permGrantedKey = 'sms_permission_granted';
  static const _autoSyncKey = 'sms_auto_sync_enabled';

  // ── Check if auto-sync should run ─────────────────────────────────────────
  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? false;
  }

  // ── Called once when user grants SMS permission in SmsImportScreen ─────────
  static Future<void> onPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permGrantedKey, true);
    await prefs.setBool(_autoSyncKey, true);
    // Set last sync to 6 months ago so first manual import still works
    // On subsequent runs we only fetch NEW messages
    debugPrint('[SmsAutoSync] Permission granted — auto-sync enabled');
  }

  // ── Disable auto-sync (user can turn off from settings) ───────────────────
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, false);
    debugPrint('[SmsAutoSync] Auto-sync disabled by user');
  }

  // ── Main sync method — call from splash boot or home screen ───────────────
  // Returns number of new transactions imported (0 = nothing new)
  static Future<int> sync({
    required Future<void> Function({
      required String title,
      required double amount,
      required String category,
      required bool isIncome,
      required DateTime date,
    })
    addExpense,
    required List<dynamic> existingExpenses,
  }) async {
    // Skip if not enabled
    final enabled = await isEnabled;
    if (!enabled) return 0;

    // Skip if no SMS permission
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      // Permission was revoked — disable auto-sync
      await disable();
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs =
        prefs.getInt(_lastSyncKey) ??
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    debugPrint(
      '[SmsAutoSync] Syncing since ${DateTime.fromMillisecondsSinceEpoch(lastSyncMs)}',
    );

    try {
      final telephony = Telephony.instance;
      final now = DateTime.now();

      // Only fetch SMS newer than last sync
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThan(lastSyncMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
      );

      if (messages == null || messages.isEmpty) {
        debugPrint('[SmsAutoSync] No new SMS since last sync');
        await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
        return 0;
      }

      debugPrint('[SmsAutoSync] Found ${messages.length} new SMS to check');

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
      debugPrint('[SmsAutoSync] Parsed ${parsed.length} bank transactions');

      if (parsed.isEmpty) {
        await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
        return 0;
      }

      // Build fingerprint set from existing expenses
      final existingFps = <String>{};
      for (final e in existingExpenses) {
        existingFps.add(
          _fp(
            amount: e.amount as double,
            isIncome: e.isIncome as bool,
            date: e.date as DateTime,
          ),
        );
      }

      int imported = 0;
      for (final tx in parsed) {
        final fp = _fp(amount: tx.amount, isIncome: tx.isIncome, date: tx.date);
        if (existingFps.contains(fp)) continue;

        await addExpense(
          title: tx.title,
          amount: tx.amount,
          category: tx.category,
          isIncome: tx.isIncome,
          date: tx.date,
        );

        existingFps.add(fp); // prevent double-import within this batch
        imported++;
      }

      // Update last sync timestamp
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
      debugPrint('[SmsAutoSync] Imported $imported new transactions');
      return imported;
    } catch (e) {
      debugPrint('[SmsAutoSync] Error: $e');
      return 0;
    }
  }

  // ── Fingerprint: amount + type + date minute ───────────────────────────────
  static String _fp({
    required double amount,
    required bool isIncome,
    required DateTime date,
  }) {
    final r = DateTime(date.year, date.month, date.day, date.hour, date.minute);
    return '${amount.toStringAsFixed(2)}_${isIncome}_${r.millisecondsSinceEpoch}';
  }

  // ── Get last sync time (for display in settings) ──────────────────────────
  static Future<DateTime?> get lastSyncTime async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ── Reset (for testing) ───────────────────────────────────────────────────
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_permGrantedKey);
    await prefs.remove(_autoSyncKey);
  }
}
