import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_svg_widget.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/common/constant/constant_assets.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatCard extends StatelessWidget {
  final VoidCallback onTap;

  const ChatCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CommonSvgWidget(
                svgName: Assets.chat,
                width: 24,
                height: 24,
                color: AppColors.primaryColor,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.chatWithBuddy,
                  style: context.t.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.powerByAi,
                      style: context.t.captionMuted.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
