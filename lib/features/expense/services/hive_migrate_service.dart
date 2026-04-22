import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

/// REAL DEVICE CRASH FIX
///
/// Why emulator works, real device crashes:
///   Emulator = fresh install, no old Hive files.
///   Real device from Play Store = Hive binary files already on disk
///   written by an older adapter version. The new adapter tries to
///   read binary fields that don't exist → type cast exception → crash.
///
/// Why opening raw (no adapters) doesn't work on real devices:
///   Raw mode returns the actual typed objects (Expense instances),
///   not plain Maps. So `v is Map` is always false → export is empty
///   → migration does nothing.
///
/// CORRECT FIX:
///   1. Always register adapters FIRST (they have ?? fallbacks on every field)
///   2. Try to open boxes normally
///   3. If ANY exception — catch it, wipe the box files, open fresh
///   4. Cloud sync via Supabase restores all data on next login
///
/// This is safe because:
///   - The adapters are null-safe: every field has a default value
///   - If reading an old box throws, we wipe + let cloud restore
///   - We never lose data that was synced to Supabase

class HiveMigrationService {
  static const int _schemaVersion = 4;
  static const String _versionKey = 'hive_schema_v4';

  static Future<void> initSafely() async {
    await Hive.initFlutter();

    // ALWAYS register adapters first — they handle null fields gracefully
    _register();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_versionKey) ?? 0;

    if (stored > 0 && stored < _schemaVersion) {
      // Schema changed — wipe old boxes to avoid binary format mismatch
      debugPrint('[Hive] Schema $stored → $_schemaVersion: wiping old boxes');
      await _wipe();
    } else {
      // Normal open with crash recovery
      await _openWithRecovery();
    }

    await prefs.setInt(_versionKey, _schemaVersion);
    debugPrint('[Hive] Ready v$_schemaVersion');
  }

  static void _register() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(BudgetAdapter());
  }

  static Future<void> _openWithRecovery() async {
    try {
      await Hive.openBox<Expense>('expenses');
      await Hive.openBox<Budget>('budget');
    } catch (e) {
      // Binary format mismatch or corruption — wipe and start fresh
      debugPrint('[Hive] Open failed ($e) — wiping and recreating');
      await _wipe();
    }
  }

  static Future<void> _wipe() async {
    // Close any open boxes first
    for (final name in ['expenses', 'budget']) {
      try {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      } catch (_) {}
      // Also try typed close
      try {
        if (name == 'expenses' && Hive.isBoxOpen(name)) {
          await Hive.box<Expense>(name).close();
        } else if (name == 'budget' && Hive.isBoxOpen(name)) {
          await Hive.box<Budget>(name).close();
        }
      } catch (_) {}
    }

    // Delete from disk
    await Hive.deleteBoxFromDisk('expenses').catchError((_) {});
    await Hive.deleteBoxFromDisk('budget').catchError((_) {});

    // Open fresh empty boxes
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Budget>('budget');

    debugPrint(
      '[Hive] Fresh boxes ready. Supabase sync will restore cloud data.',
    );
  }
}
