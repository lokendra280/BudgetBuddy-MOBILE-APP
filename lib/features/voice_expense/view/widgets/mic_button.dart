import 'package:budgetBuddy/common/app_theme.dart';
import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;
  const MicButton({super.key, required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: listening ? kAccent : AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: (listening ? kAccent : AppColors.primaryColor).withOpacity(
              .4,
            ),
            blurRadius: listening ? 36 : 18,
            spreadRadius: listening ? 6 : 2,
          ),
        ],
      ),
      child: Icon(
        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: Colors.white,
        size: 46,
      ),
    ),
  );
}
