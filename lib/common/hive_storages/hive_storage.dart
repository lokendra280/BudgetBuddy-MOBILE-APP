import 'package:budgetBuddy/features/ai_screen/models/goals_transaction.dart';
import 'package:budgetBuddy/features/ai_screen/models/goals_model.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/home/services/sync_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HiveStorage {
  HiveStorage._();

  // ── Box accessors ─────────────────────────────────────────────
  static Box<Expense> get expenses => Hive.box<Expense>('expenses');
  static Box<Budget> get budget => Hive.box<Budget>('budget');
  static Box<GoalEntry> get goals => Hive.box<GoalEntry>('goals');

  static Box<BillReminder> get billReminders =>
      Hive.box<BillReminder>('bill_reminders');
  static Box<GoalTransaction> get goalsTransaction =>
      Hive.box<GoalTransaction>('goals_transaction');
  static Box<EmiLoan> get emiLoans => Hive.box<EmiLoan>('emi_loans');
  // ── Init ──────────────────────────────────────────────────────
  static const int _schemaVersion = 6;
  static const String _versionKey = 'hive_schema_v';

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_versionKey) ?? 0;

    if (stored > 0 && stored < _schemaVersion) {
      debugPrint('[HiveStorage] Schema $stored → $_schemaVersion: wiping');
      await _wipeAndRebuild();
    } else {
      await _openWithRecovery();
    }

    await prefs.setInt(_versionKey, _schemaVersion);
    debugPrint('[HiveStorage] Ready v$_schemaVersion');
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GoalEntryAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(BillReminderAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(GoalTransactionAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(EmiPaymentAdapter()); // ← new
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(EmiLoanAdapter()); // ← new
  }

  static Future<void> _openWithRecovery() async {
    try {
      await Future.wait([
        Hive.openBox<Expense>('expenses'),
        Hive.openBox<Budget>('budget'),
        Hive.openBox<GoalEntry>('goals'),
        Hive.openBox<BillReminder>('bill_reminders'),
        Hive.openBox<GoalTransaction>('goals_transaction'),
        Hive.openBox<EmiLoan>('emi_loans'), // ← new
        //  await Hive.openBox('feedback_box');
        Hive.openBox('feedback_box'), // ← new
      ]);
    } catch (e) {
      debugPrint('[HiveStorage] Open failed: $e — wiping');
      await _wipeAndRebuild();
    }
  }

  static Future<void> _wipeAndRebuild() async {
    for (final name in [
      'expenses',
      'budget',
      'goals',
      'bill_reminders',
      'goals_transaction',
      'emi_loans',
    ]) {
      try {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      } catch (_) {}
      await Hive.deleteBoxFromDisk(name).catchError((_) {});
    }
    await Future.wait([
      Hive.openBox<Expense>('expenses'),
      Hive.openBox<Budget>('budget'),
      Hive.openBox<GoalEntry>('goals'),
      Hive.openBox<BillReminder>('bill_reminders'),
      Hive.openBox<GoalTransaction>('goals_transaction'),
      Hive.openBox<EmiLoan>('emi_loans'), // ← new
    ]);
  }

  // ── Expenses ──────────────────────────────────────────────────
  static Future<void> addExpense(Expense e) async {
    await expenses.add(e);
    SyncService.pushExpense(e); // fire & forget
  }

  static Future<void> deleteExpense(Expense e) async {
    final id = e.id;
    try {
      await e.delete();
    } catch (err) {
      debugPrint('[HiveStorage] deleteExpense error: $err');
      return; // don't sync if local delete failed
    }
    SyncService.deleteExpenseRemote(id); // fire & forget
  }

  // ── Budget ────────────────────────────────────────────────────
  static Budget ensureBudget() {
    if (budget.isEmpty) budget.add(Budget());
    return budget.getAt(0)!;
  }

  static Future<void> saveBudget(Budget b) async {
    await budget.putAt(0, b); // ← putAt instead of b.save()
    SyncService.pushBudget(b);
  }

  // ── Goals ─────────────────────────────────────────────────────
  static Future<GoalEntry> addGoal({
    required String name,
    required String emoji,
    required double target,
    required int daysLeft,
  }) async {
    final entry = GoalEntry(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      target: target,
      saved: 0,
      daysLeft: daysLeft,
      transactions: [
        GoalTransaction(id: const Uuid().v4(), amount: 0, date: DateTime.now()),
      ],
    );
    await goals.add(entry);
    SyncService.pushGoal(entry);
    return entry;
  }

  // add mount
  static Future<void> addToGoal(String id, double amount) async {
    try {
      final entries = goals.values.toList();
      final idx = entries.indexWhere((g) => g.id == id);
      if (idx < 0) {
        debugPrint('[HiveStorage] addToGoal: goal $id not found');
        return;
      }
      final g = entries[idx];
      g.transactions.add(
        GoalTransaction(
          id: const Uuid().v4(),
          amount: amount,
          date: DateTime.now(),
        ),
      );
      g.saved = (g.saved + amount).clamp(0, g.target);
      await goals.putAt(idx, g); // ← putAt instead of g.save()
      SyncService.pushGoal(g);
    } catch (e) {
      debugPrint('[HiveStorage] addToGoal error: $e');
    }
  }

  static Future<void> deleteGoal(String id) async {
    final idx = goals.values.toList().indexWhere((g) => g.id == id);
    if (idx < 0) return;
    await goals.deleteAt(idx);
    SyncService.deleteGoalRemote(id); // fire & forget
  }

  static List<GoalEntry> allGoals() => goals.values.toList();

  // ── Bill Reminders ────────────────────────────────────────────
  static Future<void> saveBillReminder(BillReminder bill) async =>
      billReminders.put(bill.id, bill);

  static Future<void> deleteBillReminder(String id) async =>
      billReminders.delete(id);

  static BillReminder? getBillReminder(String id) => billReminders.get(id);
  static List<BillReminder> allBillReminders() => billReminders.values.toList();
  static List<BillReminder> activeBillReminders() =>
      billReminders.values.where((b) => b.isActive).toList();
  // ── EMI / Loans ────────────────────────────────────────────────────────────
  static Future<void> saveEmiLoan(EmiLoan loan) async =>
      emiLoans.put(loan.id, loan);

  static Future<void> deleteEmiLoan(String id) async => emiLoans.delete(id);

  /// Returns null (not a throw) so callers can use null-check safely.
  static EmiLoan? getEmiLoan(String id) => emiLoans.get(id);

  static List<EmiLoan> allEmiLoans() => emiLoans.values.toList();
  static List<EmiLoan> activeEmiLoans() =>
      emiLoans.values.where((l) => l.isActive).toList();
}
