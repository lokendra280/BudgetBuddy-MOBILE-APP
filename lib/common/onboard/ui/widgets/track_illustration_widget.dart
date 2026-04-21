import 'dart:math' as math;

import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/onboard/ui/widgets/expense_row_widget.dart';
import 'package:expensetracker/common/onboard/ui/widgets/phone_mokup.dart';
import 'package:flutter/material.dart';

class TrackIllustration extends StatelessWidget {
  final double t;
  const TrackIllustration({required this.t});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final f1 = math.sin(t * math.pi) * 8; // float offset card 1
    final f2 =
        math.sin(t * math.pi + math.pi) * 6; // float card 2 opposite phase

    return Stack(
      children: [
        // ── Top expense card ─────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.13 + f1,
          left: 20,
          right: 20,
          child: ExpenseRow(
            emoji: Assets.food,
            title: 'Dinner',
            sub: 'Food · Just now',
            amount: '− Rs. 450',
            catColor: AppColors.primaryColor,
            amtColor: AppColors.secondaryColor,
          ),
        ),

        // ── Phone mockup ─────────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.20,
          left: 0,
          right: 0,
          child: Center(child: PhoneMockup(scanProgress: 0.35 + t * 0.30)),
        ),

        // ── Scan bill badge ───────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.39 - f2,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.45),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Scan Bill',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Salary income card ────────────────────────────────────────────────
        Positioned(
          top: size.height * 0.47 + f1 * 0.6,
          left: 20,
          right: 20,
          child: ExpenseRow(
            emoji: Assets.salary,
            title: 'Salary',
            sub: 'Income · Monthly',
            amount: '+ Rs. 85K',
            catColor: AppColors.primaryColor,
            amtColor: AppColors.secondaryColor,
          ),
        ),
      ],
    );
  }
}
