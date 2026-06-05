import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/widgets/custom_appbar.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/heatmap/providers/heatmap_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  Color _color(double intensity, BuildContext ctx) {
    if (intensity <= 0) return ctx.c.card;
    if (intensity < 0.25) return kGreen.withOpacity(0.35);
    if (intensity < 0.5) return kAmber.withOpacity(0.55);
    if (intensity < 0.75) return kAccent.withOpacity(0.65);
    return kAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmap = ref.watch(heatmapProvider);
    final topDays = ref.watch(topSpendDaysProvider);
    final fmt = ref.watch(fmtProvider);
    final now = DateTime.now();
    final maxSpend = heatmap.values.isEmpty
        ? 1.0
        : heatmap.values.reduce((a, b) => a > b ? a : b);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: CustomAppBar(
        backgroundColor: c.surface,

        title: 'Spending Heatmap',
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Legend
          Row(
            children: [
              Text('Low', style: TextStyle(fontSize: 11, color: c.textMuted)),
              const SizedBox(width: 8),
              ...List.generate(
                5,
                (i) => Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _color(i / 4, context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('High', style: TextStyle(fontSize: 11, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 18),

          // 6-month calendar grid
          ...List.generate(6, (mi) {
            final d = DateTime(now.year, now.month - (5 - mi));
            final days = DateTime(d.year, d.month + 1, 0).day;
            final startWd = DateTime(d.year, d.month, 1).weekday % 7;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(d),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                      .map(
                        (lbl) => Expanded(
                          child: Center(
                            child: Text(
                              lbl,
                              style: TextStyle(fontSize: 8, color: c.textMuted),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: startWd + days,
                  itemBuilder: (_, i) {
                    if (i < startWd) return const SizedBox.shrink();
                    final day = i - startWd + 1;
                    final date = DateTime(d.year, d.month, day);
                    final spend = heatmap[date] ?? 0;
                    final isToday =
                        date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                    return Tooltip(
                      message: spend > 0
                          ? '${DateFormat('MMM d').format(date)}: ${fmt(spend)}'
                          : '',
                      child: Container(
                        decoration: BoxDecoration(
                          color: _color(
                            maxSpend > 0 ? spend / maxSpend : 0,
                            context,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          border: isToday
                              ? Border.all(
                                  color: AppColors.primaryColor,
                                  width: 1.5,
                                )
                              : Border.all(color: c.border.withOpacity(0.4)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
            );
          }),

          // Top spend days
          if (topDays.isNotEmpty) ...[
            const SectionLabel('Highest Spend Days'),
            const SizedBox(height: 10),
            ...topDays.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(e.key),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        fmt(e.value),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
