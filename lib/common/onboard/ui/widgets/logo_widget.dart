import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryColor, AppColors.darkGrey],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            Assets.appIcons,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        // child: const Center(child: Text('💸', style: TextStyle(fontSize: 16))),
      ),
      const SizedBox(width: 9),
      const Text(
        'Budget Buddy',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    ],
  );
}
