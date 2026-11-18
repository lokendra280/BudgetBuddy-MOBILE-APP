import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/constant_assets.dart';
import 'package:budgetbuddy/common/localization/category_localization.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One transaction row, styled like the Home "Recent Transactions" list.
/// Meant to sit inside a grouped card (the parent draws dividers).
class TransactionWidget extends StatelessWidget {
  final Expense expense;

  const TransactionWidget({
    super.key,
    required this.expense,
    String? sym,
    dynamic fmt,
  });

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final isInc = e.isIncome;
    final cidx = (isInc ? kIncomeCategories : kCategories).indexOf(e.category);
    final col = isInc
        ? kGreen
        : kCatColors[cidx < 0 ? 0 : cidx % kCatColors.length];

    // Each expense uses its own saved currency — immune to global changes.
    final ownSym = currencyOf(e.currency).symbol;
    final amountStr =
        '${isInc ? '+ ' : '- '}$ownSym${NumberFormat('#,##0.##').format(e.amount)}';
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: col.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Image.asset(
                kCatEmoji[e.category] ?? Assets.noDataFound,
                width: 22,
                height: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${CategoryLocalization.getName(l10n, e.category)} · '
                  '${DateFormat('MMM d, hh:mm a').format(e.date)}',
                  style: TextStyle(fontSize: 11, color: context.c.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isInc ? kGreen : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
