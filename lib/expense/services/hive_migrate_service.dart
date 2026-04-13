import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

/// Handles safe Hive initialization + schema migration.
///
/// ROOT CAUSE of Play Store crash:
///   When you add new HiveFields (e.g. field 5 = isIncome, field 6 = currency)
///   and publish a new APK, existing users have old Hive boxes on disk that
///   were written by an older adapter. On first open the new adapter tries to
///   read fields that don't exist → type-cast exception → crash.
///
/// CACHE-CLEAR FIX:
///   Clearing app cache deletes the Hive .hive files → fresh start → no crash.
///   That's why it works after cache clear.
///
/// PROPER FIX (this file):
///   1. Record a "schema version" in SharedPreferences.
///   2. On every launch, compare current version to stored version.
///   3. If version changed, export all data to plain Maps BEFORE registering
///      adapters, delete the old boxes, then re-import into fresh boxes.
///   4. The adapter's read() already uses ???? fallbacks for every field,
///      so forward-compatibility is guaranteed for future fields.

class HiveMigrationService {
  // Increment this every time you add/change a HiveField
  static const int _currentSchemaVersion = 3;
  static const String _versionKey = 'hive_schema_version';

  static Future<void> initSafely() async {
    await Hive.initFlutter();

    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_versionKey) ?? 0;
    final needsMigration = storedVersion < _currentSchemaVersion;

    if (needsMigration && storedVersion > 0) {
      debugPrint(
        '[Hive] Schema changed $storedVersion → $_currentSchemaVersion, migrating…',
      );
      await _migrate(prefs);
    } else {
      // Normal init
      _registerAdapters();
      await _openBoxes();
    }

    await prefs.setInt(_versionKey, _currentSchemaVersion);
    debugPrint('[Hive] Ready. Schema v$_currentSchemaVersion');
  }

  // ── Register adapters ────────────────────────────────────────────────────
  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(BudgetAdapter());
  }

  // ── Open boxes ───────────────────────────────────────────────────────────
  static Future<void> _openBoxes() async {
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Budget>('budget');
  }

  // ── Migration: export raw → delete old boxes → re-import ─────────────────
  static Future<void> _migrate(SharedPreferences prefs) async {
    // Step 1: Open boxes WITHOUT typed adapters (raw mode) to safely read old data
    final rawExpenses = await Hive.openBox('expenses');
    final rawBudget = await Hive.openBox('budget');

    // Step 2: Export to plain maps
    final expenseMaps = rawExpenses.values
        .map((v) {
          if (v is Map) return Map<String, dynamic>.from(v as Map);
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();

    Map<String, dynamic>? budgetMap;
    if (rawBudget.isNotEmpty) {
      final v = rawBudget.getAt(0);
      if (v is Map) budgetMap = Map<String, dynamic>.from(v as Map);
    }

    // Step 3: Close and delete old boxes
    await rawExpenses.close();
    await rawBudget.close();
    await Hive.deleteBoxFromDisk('expenses');
    await Hive.deleteBoxFromDisk('budget');

    // Step 4: Open fresh typed boxes
    _registerAdapters();
    await _openBoxes();

    // Step 5: Re-import expenses
    final expBox = Hive.box<Expense>('expenses');
    for (final m in expenseMaps) {
      try {
        expBox.add(
          Expense(
            id: m['id']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            category: m['category']?.toString() ?? 'Other',
            date: m['date'] is DateTime
                ? m['date'] as DateTime
                : DateTime.tryParse(m['date']?.toString() ?? '') ??
                      DateTime.now(),
            isIncome: m['isIncome'] as bool? ?? false,
            currency: m['currency']?.toString() ?? 'NPR',
          ),
        );
      } catch (e) {
        debugPrint('[Hive] Skipped corrupt expense: $e');
      }
    }

    // Step 6: Re-import budget
    final budgetBox = Hive.box<Budget>('budget');
    if (budgetMap != null) {
      try {
        budgetBox.add(
          Budget(
            monthlyLimit:
                (budgetMap['monthlyLimit'] as num?)?.toDouble() ?? 10000,
            streakDays: budgetMap['streakDays'] as int? ?? 0,
            lastActiveDate: budgetMap['lastActiveDate']?.toString() ?? '',
            referralCode: budgetMap['referralCode']?.toString(),
            referralCount: budgetMap['referralCount'] as int? ?? 0,
            currency: budgetMap['currency']?.toString() ?? 'NPR',
          ),
        );
      } catch (e) {
        debugPrint('[Hive] Could not migrate budget: $e — using defaults');
        budgetBox.add(Budget());
      }
    }

    debugPrint(
      '[Hive] Migration complete. ${expBox.length} expenses restored.',
    );
  }
}
