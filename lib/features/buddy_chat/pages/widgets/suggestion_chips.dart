import 'package:flutter/material.dart';
import 'package:budgetBuddy/common/app_theme.dart';

class SuggestionChips extends StatelessWidget {
  final void Function(String) onTap;
  const SuggestionChips({super.key, required this.onTap});

  static const _suggestions = [
    'Can I spend \$500 on food?',
    'How is my budget?',
    'Where am I overspending?',
    'How much can I spend today?',
    'Am I saving enough?',
    'Review my subscriptions',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(_suggestions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.25),
              ),
            ),
            child: Text(
              _suggestions[i],
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
