// // import 'package:expensetracker/expense/models/expense.dart';
// // import 'package:hive_flutter/hive_flutter.dart';

// // class HiveStorage {
// //   // ── Singleton ─────────────────────────────
// //   HiveStorage._();
// //   static final HiveStorage instance = HiveStorage._();

// //   // ── Box Names ─────────────────────────────
// //   static const String expenseBox = 'expenses';
// //   static const String budgetBox = 'budget';
// //   static const String onboardingBox = 'onboarding';
// //   static const String languageBox = 'language';
// //   static const String authBox = 'auth';

// //   // ── Init (Call once in main) ──────────────
// //   Future<void> init() async {
// //     await Hive.initFlutter();

// //     // Register adapters safely (avoid crash)
// //     if (!Hive.isAdapterRegistered(0)) {
// //       Hive.registerAdapter(ExpenseAdapter());
// //     }
// //     if (!Hive.isAdapterRegistered(1)) {
// //       Hive.registerAdapter(BudgetAdapter());
// //     }

// //     // Open boxes in parallel 🚀
// //     await Future.wait([
// //       Hive.openBox<Expense>(expenseBox),
// //       Hive.openBox<Budget>(budgetBox),
// //       Hive.openBox<bool>(onboardingBox),
// //       Hive.openBox<bool>(languageBox),
// //     ]);
// //   }

// //   // ── Getters ───────────────────────────────
// //   Box<Expense> get expenses => Hive.box<Expense>(expenseBox);
// //   Box<Budget> get budgets => Hive.box<Budget>(budgetBox);
// //   Box<bool> get onboarding => Hive.box<bool>(onboardingBox);
// //   Box<bool> get language => Hive.box<bool>(languageBox);

// //   // ── Expense Methods ───────────────────────
// //   Future<void> addExpense(Expense expense) async {
// //     await expenses.add(expense);
// //   }

// //   List<Expense> getAllExpenses() {
// //     return expenses.values.toList();
// //   }

// //   Future<void> deleteExpense(int index) async {
// //     await expenses.deleteAt(index);
// //   }

// //   Future<void> clearExpenses() async {
// //     await expenses.clear();
// //   }

// //   // ── Budget Methods ────────────────────────
// //   Future<void> setBudget(Budget budget) async {
// //     await budgets.put('main', budget);
// //   }

// //   Budget? getBudget() {
// //     return budgets.get('main');
// //   }

// //   Future<void> clearBudget() async {
// //     await budgets.delete('main');
// //   }

// //   // ── Onboarding ────────────────────────────
// //   bool isOnboardingCompleted() {
// //     return onboarding.get('completed', defaultValue: false)!;
// //   }

// //   Future<void> setOnboardingCompleted() async {
// //     await onboarding.put('completed', true);
// //   }

// //   Future<void> resetOnboarding() async {
// //     await onboarding.put('completed', false);
// //   }

// //   // ── Language ──────────────────────────────
// //   bool isLanguageSelected() {
// //     return language.get('selected', defaultValue: false)!;
// //   }

// //   Future<void> setLanguageSelected() async {
// //     await language.put('selected', true);
// //   }

// //   Future<void> resetLanguage() async {
// //     await language.put('selected', false);
// //   }

// //   Box<bool> get auth => Hive.box<bool>(authBox);

// //   bool isBiometricEnabled() {
// //     return auth.get('biometric_enabled', defaultValue: false)!;
// //   }

// //   Future<void> enableBiometric() async {
// //     await auth.put('biometric_enabled', true);
// //   }

// //   Future<void> disableBiometric() async {
// //     await auth.put('biometric_enabled', false);
// //   }

// //   // ── Clear All ─────────────────────────────
// //   Future<void> clearAll() async {
// //     await Future.wait([
// //       expenses.clear(),
// //       budgets.clear(),
// //       onboarding.clear(),
// //       language.clear(),
// //     ]);
// //   }
// // }

// import 'package:hive_flutter/hive_flutter.dart';

// class HiveStorage {
//   Future<void> init() async {
//     await Hive.initFlutter();
//     await Hive.openBox<bool>('onboarding');
//     await Hive.openBox<bool>('language');
//   }

//   Future<bool> checkOnboardingCompleted() async {
//     await Hive.openBox<bool>('onboarding');
//     final box = Hive.box<bool>('onboarding');
//     return box.get('completed', defaultValue: false)!;
//   }

//   Future<void> markOnboardingCompleted() async {
//     await Hive.openBox<bool>('onboarding');
//     final box = Hive.box<bool>('onboarding');
//     await box.put('completed', true);
//   }

//   Future<bool> checkLanguageSelected() async {
//     await Hive.openBox<bool>('language');
//     final box = Hive.box<bool>('language');
//     return box.get('selected', defaultValue: false)!;
//   }

//   Future<void> markLanguageSelected() async {
//     final box = Hive.box<bool>('language');
//     await box.put('selected', true);
//   }
//     Box<bool> get auth => Hive.box<bool>(authBox);

//   bool isBiometricEnabled() {
//     return auth.get('biometric_enabled', defaultValue: false)!;
//   }

//   Future<void> enableBiometric() async {
//     await auth.put('biometric_enabled', true);
//   }

//   Future<void> disableBiometric() async {
//     await auth.put('biometric_enabled', false);
//   }
// }
