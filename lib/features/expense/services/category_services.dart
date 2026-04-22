import 'dart:convert';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppCategory {
  final String id, name, emoji, color;
  final bool isIncome;
  const AppCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.isIncome,
  });

  factory AppCategory.fromJson(Map<String, dynamic> j) => AppCategory(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? 'Other',
    emoji: j['emoji']?.toString() ?? '📦',
    color: j['color']?.toString() ?? '#6366F1',
    isIncome: j['is_income'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'color': color,
    'is_income': isIncome,
  };
}

// ── Supabase SQL (run once) ────────────────────────────────────────────────────

class CategoryService {
  static const _key = 'categories_v1';
  static const _tsKey = 'categories_ts';
  static const _ttl = 3600000; // 1 hour in ms

  static List<AppCategory> _expense = [];
  static List<AppCategory> _income = [];

  static List<AppCategory> get expenseCategories =>
      _expense.isNotEmpty ? _expense : _fallbackExpense;
  static List<AppCategory> get incomeCategories =>
      _income.isNotEmpty ? _income : _fallbackIncome;

  static Future<void> init() async {
    await _loadCache();
    unawaited(_refresh()); // background refresh
  }

  static Future<void> _loadCache() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((j) => AppCategory.fromJson(j))
          .toList();
      _expense = list.where((c) => !c.isIncome).toList();
      _income = list.where((c) => c.isIncome).toList();
    } catch (_) {}
  }

  static Future<void> _refresh() async {
    try {
      final p = await SharedPreferences.getInstance();
      final age =
          DateTime.now().millisecondsSinceEpoch - (p.getInt(_tsKey) ?? 0);
      if (age < _ttl && _expense.isNotEmpty) return;

      final rows = await Supabase.instance.client
          .from('categories')
          .select()
          .order('sort_order');
      final list = (rows as List).map((j) => AppCategory.fromJson(j)).toList();
      _expense = list.where((c) => !c.isIncome).toList();
      _income = list.where((c) => c.isIncome).toList();
      await p.setString(_key, jsonEncode(list.map((c) => c.toJson()).toList()));
      await p.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[CategoryService] fetch error: $e');
    }
  }

  static Future<void> forceRefresh() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tsKey);
    await _refresh();
  }

  // ── Fallbacks ──────────────────────────────────────────────────────────────
  static final _fallbackExpense = [
    AppCategory(
      id: 'food',
      name: 'Food',
      emoji: Assets.food,
      color: '#6366F1',
      isIncome: false,
    ),
    AppCategory(
      id: 'trans',
      name: 'Transport',
      emoji: Assets.transport,
      color: '#F43F5E',
      isIncome: false,
    ),
    AppCategory(
      id: 'shop',
      name: 'Shopping',
      emoji: Assets.shopping,
      color: '#10B981',
      isIncome: false,
    ),
    AppCategory(
      id: 'hlth',
      name: 'Health',
      emoji: Assets.health,
      color: '#F59E0B',
      isIncome: false,
    ),
    AppCategory(
      id: 'bill',
      name: 'Bills',
      emoji: Assets.bills,
      color: '#3B82F6',
      isIncome: false,
    ),
    AppCategory(
      id: 'ent',
      name: 'Entertainment',
      emoji: Assets.entertainment,
      color: '#EC4899',
      isIncome: false,
    ),
    AppCategory(
      id: 'edu',
      name: 'Education',
      emoji: Assets.education,
      color: '#8B5CF6',
      isIncome: false,
    ),
    AppCategory(
      id: 'trav',
      name: 'Travel',
      emoji: Assets.travel,
      color: '#14B8A6',
      isIncome: false,
    ),
    AppCategory(
      id: 'groc',
      name: 'Groceries',
      emoji: Assets.groceries,
      color: '#22C55E',
      isIncome: false,
    ),
    AppCategory(
      id: 'oth',
      name: 'Other',
      emoji: Assets.other,
      color: '#64748B',
      isIncome: false,
    ),
  ];
  
  
  static final _fallbackIncome = [
    AppCategory(
      id: 'sal',
      name: 'Salary',
      emoji: Assets.salary,
      color: '#10B981',
      isIncome: true,
    ),
    AppCategory(
      id: 'frl',
      name: 'Freelance',
      emoji: Assets.freelance,
      color: '#6366F1',
      isIncome: true,
    ),
    AppCategory(
      id: 'biz',
      name: 'Business',
      emoji: Assets.business,
      color: '#F59E0B',
      isIncome: true,
    ),
    AppCategory(
      id: 'inv',
      name: 'Investment',
      emoji: Assets.investment,
      color: '#3B82F6',
      isIncome: true,
    ),
    AppCategory(
      id: 'gft',
      name: 'Gift',
      emoji: Assets.gift,
      color: '#EC4899',
      isIncome: true,
    ),
    AppCategory(
      id: 'oi',
      name: 'Other',
      emoji: '📦',
      color: '#64748B',
      isIncome: true,
    ),
  ];
}

// ignore: unused_element
Future<void> unawaited(Future<void> f) async {}
