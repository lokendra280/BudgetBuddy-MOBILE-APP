import 'dart:ui';

import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRange extends StatelessWidget {
  final DateTime? from, to;
  final VoidCallback onTap;
  const DateRange({this.from, this.to, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.date_range_rounded,
            color: AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            from != null && to != null
                ? '${DateFormat('MMM d, yyyy').format(from!)} → ${DateFormat('MMM d, yyyy').format(to!)}'
                : 'Tap to select date range',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.edit_calendar_rounded,
            color: AppColors.primaryColor,
            size: 16,
          ),
        ],
      ),
    ),
  );
}
