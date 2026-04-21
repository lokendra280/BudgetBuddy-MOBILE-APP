import 'package:expensetracker/common/app_theme.dart';
import 'package:flutter/material.dart';

class OnBoardingButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;
  const OnBoardingButton({required this.isLast, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      width: isLast ? 172 : 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: isLast
            ? const Text(
                'Get Started 🚀',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    ),
  );
}
