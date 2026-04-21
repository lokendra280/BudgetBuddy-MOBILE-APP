import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/common/localization/category_localization.dart';
import 'package:expensetracker/expense/models/expense.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionWidget extends StatelessWidget {
  final Expense expense;

  const TransactionWidget({required this.expense, String? sym, dynamic fmt});

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final isInc = e.isIncome;
    final cidx = (isInc ? kIncomeCategories : kCategories).indexOf(e.category);
    final col = isInc
        ? kGreen
        : kCatColors[cidx < 0 ? 0 : cidx % kCatColors.length];

    // ✅ Each expense uses its own saved currency — immune to global changes
    final ownSym = currencyOf(e.currency).symbol;
    final amountStr =
        '${isInc ? '+' : '-'}$ownSym${e.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: col.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  kCatEmoji[e.category] ?? Assets.nodata,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + category · date
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
                  Row(
                    children: [
                      Text(
                        '${CategoryLocalization.getName(AppLocalizations.of(context)!, e.category)} · ${DateFormat('MMM d, yyyy').format(e.date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.c.textMuted,
                        ),
                      ),
                      // Show currency code badge if it differs from global setting
                      // so the user knows this expense was in a different currency
                      if (e.currency.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            e.currency,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: context.c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount + income/expense badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: col,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isInc
                        ? '${AppLocalizations.of(context)!.income}'
                        : '${AppLocalizations.of(context)!.expense}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: col,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
