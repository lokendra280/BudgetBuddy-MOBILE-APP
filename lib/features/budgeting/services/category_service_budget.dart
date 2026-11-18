import 'package:hive_flutter/hive_flutter.dart';

/// Stores category budgets in Hive, next to your expenses and budget boxes.
/// Uses a plain (untyped) box of String → double, so no TypeAdapter or
/// build_runner step is needed. The box opens itself on first use.
class CategoryBudgetService {
  CategoryBudgetService._();

  static const _boxName = 'category_budgets';

  static Future<Box> _open() async => Hive.isBoxOpen(_boxName)
      ? Hive.box(_boxName)
      : await Hive.openBox(_boxName);

  static Future<Map<String, double>> loadAll() async {
    final box = await _open();
    return {
      for (final key in box.keys)
        key.toString(): (box.get(key) as num).toDouble(),
    };
  }

  static Future<void> save(String category, double limit) async {
    final box = await _open();
    await box.put(category, limit);
  }

  static Future<void> remove(String category) async {
    final box = await _open();
    await box.delete(category);
  }

  /// Call this when the user deletes their account or logs out.
  static Future<void> clear() async {
    final box = await _open();
    await box.clear();
  }
}
