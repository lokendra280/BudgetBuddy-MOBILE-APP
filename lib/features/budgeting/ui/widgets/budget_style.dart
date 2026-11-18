import 'package:budgetbuddy/common/app_theme.dart'; // kCatColors, kAccent, kAmber, kGreen
import 'package:budgetbuddy/features/budgeting/models/budget_plan.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
// kCategories — same import HomeScreen uses.
import 'package:budgetbuddy/features/expense/services/category_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension BudgetHealthStyle on BudgetHealth {
  Color get color => switch (this) {
    BudgetHealth.over => kAccent,
    BudgetHealth.warning => kAmber,
    BudgetHealth.onTrack => kGreen,
    BudgetHealth.notSet => AppColors.primaryColor,
  };

  IconData get icon => switch (this) {
    BudgetHealth.over => Icons.error_outline_rounded,
    BudgetHealth.warning => Icons.warning_amber_rounded,
    BudgetHealth.onTrack => Icons.check_circle_outline_rounded,
    BudgetHealth.notSet => Icons.info_outline_rounded,
  };
}

/// Month name in the app's current language, e.g. "November", "नोभेम्बर", "十一月".
String localizedMonthName(BuildContext context, DateTime month) =>
    DateFormat.MMMM(Localizations.localeOf(context).toString()).format(month);

/// Same color logic as _RecentTransactions._colorFor on Home.
Color categoryColor(String category) {
  final idx = kCategories.indexOf(category);
  return kCatColors[idx < 0 ? 0 : idx % kCatColors.length];
}

IconData categoryIcon(String category) {
  final n = category.toLowerCase();
  if (n.contains('food') || n.contains('grocer') || n.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (n.contains('transport') || n.contains('travel') || n.contains('fuel')) {
    return Icons.directions_car_rounded;
  }
  if (n.contains('shop')) return Icons.shopping_bag_rounded;
  if (n.contains('bill') || n.contains('rent') || n.contains('utilit')) {
    return Icons.receipt_long_rounded;
  }
  if (n.contains('health') || n.contains('medic')) {
    return Icons.favorite_rounded;
  }
  if (n.contains('entertain') || n.contains('movie') || n.contains('fun')) {
    return Icons.movie_rounded;
  }
  if (n.contains('educat') || n.contains('school')) {
    return Icons.school_rounded;
  }
  return Icons.category_rounded;
}

class CategoryIconTile extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIconTile({super.key, required this.category, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(categoryIcon(category), color: color, size: size * 0.55),
    );
  }
}
