import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/emi_loan_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmiDetailSheet — full detail + all advanced features
// Tabs: Overview · Schedule · Simulate · Payments
// ─────────────────────────────────────────────────────────────────────────────

class EmiDetailSheet extends ConsumerStatefulWidget {
  final EmiLoan loan;
  const EmiDetailSheet({super.key, required this.loan});

  @override
  ConsumerState<EmiDetailSheet> createState() => _EmiDetailSheetState();
}

class _EmiDetailSheetState extends ConsumerState<EmiDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  double _extraSim = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _extraSim = ref.read(emiLoanProvider).simulationExtra;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Watch so live updates propagate (e.g. after recording a payment)
    final loan = ref
        .watch(emiLoanProvider)
        .loans
        .firstWhere((l) => l.id == widget.loan.id, orElse: () => widget.loan);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(loan.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.title, style: context.t.h3),
                      Text(loan.lenderName, style: context.t.bodySub),
                    ],
                  ),
                ),
                _StatusBadge(loan: loan),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SheetTabBar(controller: _tabs),
          ),
          const SizedBox(height: 4),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(loan: loan, scroll: scroll),
                _ScheduleTab(loan: loan, scroll: scroll),
                _SimulateTab(
                  loan: loan,
                  extra: _extraSim,
                  scroll: scroll,
                  onExtraChanged: (v) {
                    setState(() => _extraSim = v);
                    ref.read(emiLoanProvider.notifier).setSimulationExtra(v);
                  },
                ),
                _PaymentsTab(loan: loan, scroll: scroll),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _SheetTabBar extends StatelessWidget {
  final TabController controller;
  const _SheetTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.caption,
        labelColor: Colors.white,
        unselectedLabelColor: c.textMuted,
        tabs: [
          Tab(text: AppLocalizations.of(context)!.overView),
          Tab(text: 'Schedule'),
          Tab(text: 'Simulate'),
          Tab(text: 'Payments'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final EmiLoan loan;
  final ScrollController scroll;
  const _OverviewTab({required this.loan, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = loan.isOverdue ? kAccent : AppColors.primaryColor;
    final fmt = NumberFormat('#,##0.00');

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Progress hero ──────────────────────────────────────────────────
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Loan Progress', style: context.t.h4),
                  Text(
                    '${(loan.progressRatio * 100).toStringAsFixed(0)}%',
                    style: AppTypography.h3.colored(color),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: loan.progressRatio,
                  minHeight: 10,
                  backgroundColor: c.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ProgItem('Paid', '${loan.emisPaid} EMIs', kGreen),
                  _ProgItem('Remaining', '${loan.emisRemaining} EMIs', kAmber),
                  _ProgItem('Missed', '${loan.missedPayments}', kAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Amount breakdown ───────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount Breakdown', style: context.t.h4),
              const SizedBox(height: 12),
              _BreakRow(
                'Principal',
                fmt.format(loan.principalAmount),
                c.textMuted,
              ),
              _BreakRow(
                'Total Interest',
                fmt.format(loan.totalInterest),
                kAmber,
              ),
              _BreakRow(
                'Total Payable',
                fmt.format(loan.totalPayable),
                context.textPrimary,
              ),
              Divider(color: c.border, height: 20),
              _BreakRow(
                'Remaining Balance',
                fmt.format(loan.remainingBalance),
                kAccent,
              ),
              _BreakRow(
                'Interest Paid',
                fmt.format(loan.interestPaidSoFar),
                kAmber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Principal vs Interest donut ────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interest vs Principal', style: context.t.h4),
              const SizedBox(height: 12),
              _InterestPrincipalBar(loan: loan),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Key dates ──────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key Dates', style: context.t.h4),
              const SizedBox(height: 12),
              _DateRow(
                'Started',
                DateFormat('MMM d, yyyy').format(loan.startDate),
              ),
              _DateRow(
                'Next EMI',
                DateFormat('MMM d, yyyy').format(loan.nextDueDate),
              ),
              _DateRow(
                'Est. Closure',
                DateFormat('MMM yyyy').format(loan.estimatedEndDate),
              ),
              _DateRow('Rate', '${loan.interestRate}% p.a.'),
              _DateRow('Day of Month', 'Every ${_ordinal(loan.dayOfMonth)}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ProgItem(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTypography.labelLarge.colored(color)),
      Text(label, style: AppTypography.caption),
    ],
  );
}

class _BreakRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _BreakRow(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.t.bodySmall),
        Text(value, style: AppTypography.amountSmall.colored(valueColor)),
      ],
    ),
  );
}

class _DateRow extends StatelessWidget {
  final String label, value;
  const _DateRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.t.bodySmall),
        Text(value, style: context.t.labelLarge),
      ],
    ),
  );
}

class _InterestPrincipalBar extends StatelessWidget {
  final EmiLoan loan;
  const _InterestPrincipalBar({required this.loan});
  @override
  Widget build(BuildContext context) {
    final total = loan.totalPayable;
    final pRatio = loan.principalAmount / total;
    final iRatio = loan.totalInterest / total;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: (pRatio * 100).round(),
                child: Container(height: 14, color: AppColors.primaryColor),
              ),
              Expanded(
                flex: (iRatio * 100).round(),
                child: Container(height: 14, color: kAmber),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendDot(
              AppColors.primaryColor,
              'Principal ${(pRatio * 100).toStringAsFixed(0)}%',
            ),
            _LegendDot(
              kAmber,
              'Interest ${(iRatio * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppTypography.caption.colored(context.c.textMuted)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Amortisation Schedule
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final EmiLoan loan;
  final ScrollController scroll;
  const _ScheduleTab({required this.loan, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final schedule = loan.amortisationSchedule;
    final fmt = NumberFormat('#,##0');

    return Column(
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              _SchCol('Month', flex: 1, header: true),
              _SchCol('EMI', flex: 2, header: true),
              _SchCol('Principal', flex: 2, header: true),
              _SchCol('Interest', flex: 2, header: true),
              _SchCol('Balance', flex: 2, header: true),
            ],
          ),
        ),
        Divider(color: c.border, height: 1),

        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: schedule.length,
            itemBuilder: (_, i) {
              final e = schedule[i];
              final isPaid = i < loan.emisPaid;
              final isCurr = i == loan.emisPaid;
              return Container(
                color: isCurr
                    ? AppColors.primaryColor.withOpacity(0.06)
                    : isPaid
                    ? c.surface
                    : Colors.transparent,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    _SchCol(
                      '${e.month}',
                      flex: 1,
                      color: isCurr ? AppColors.primaryColor : c.textMuted,
                    ),
                    _SchCol(
                      fmt.format(e.emiAmount),
                      flex: 2,
                      color: isPaid ? kGreen : context.textPrimary,
                    ),
                    _SchCol(fmt.format(e.principal), flex: 2),
                    _SchCol(fmt.format(e.interest), flex: 2, color: kAmber),
                    _SchCol(
                      fmt.format(e.balance),
                      flex: 2,
                      color: isPaid ? c.textMuted : context.textPrimary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SchCol extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  final Color? color;
  const _SchCol(
    this.text, {
    required this.flex,
    this.header = false,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: header
          ? AppTypography.caption.colored(context.c.textMuted)
          : AppTypography.caption.colored(color ?? context.textPrimary),
      textAlign: TextAlign.right,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Early Payoff Simulator
// ─────────────────────────────────────────────────────────────────────────────

class _SimulateTab extends StatelessWidget {
  final EmiLoan loan;
  final double extra;
  final ScrollController scroll;
  final ValueChanged<double> onExtraChanged;
  const _SimulateTab({
    required this.loan,
    required this.extra,
    required this.scroll,
    required this.onExtraChanged,
  });

  @override
  Widget build(BuildContext context) {
    final result = loan.simulateEarlyPayoff(extra);
    final fmt = NumberFormat('#,##0');

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Explainer
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Early Payoff Simulator', style: context.t.h4),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'See how much time and interest you save by paying extra each month.',
                style: context.t.bodySub,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Slider
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Extra per month', style: context.t.labelLarge),
                  Text(
                    '${loan.currency} ${fmt.format(extra)}',
                    style: AppTypography.amount.colored(AppColors.primaryColor),
                  ),
                ],
              ),
              Slider(
                value: extra,
                min: 0,
                max: loan.emiAmount * 2,
                divisions: 40,
                activeColor: AppColors.primaryColor,
                onChanged: onExtraChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: context.t.captionMuted),
                  Text(
                    fmt.format(loan.emiAmount * 2),
                    style: context.t.captionMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Results
        if (extra > 0) ...[
          Row(
            children: [
              Expanded(
                child: _SimResultCard(
                  icon: Icons.timer_rounded,
                  label: 'Months Saved',
                  value: '${result.monthsSaved}',
                  sub:
                      '${result.monthsSaved ~/ 12}y ${result.monthsSaved % 12}m',
                  color: kGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SimResultCard(
                  icon: Icons.savings_rounded,
                  label: 'Interest Saved',
                  value: fmt.format(result.interestSaved),
                  sub: loan.currency,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Payoff Timeline', style: context.t.h4),
                const SizedBox(height: 10),
                _TimelineRow(
                  'Original tenure',
                  '${loan.tenureMonths} months',
                  context.c.textMuted,
                ),
                _TimelineRow(
                  'New tenure',
                  '${(loan.emisRemaining - result.monthsSaved).clamp(0, loan.tenureMonths)} months remaining',
                  kGreen,
                ),
                _TimelineRow(
                  'New total interest',
                  fmt.format(loan.totalInterest - result.interestSaved),
                  kAmber,
                ),
              ],
            ),
          ),
        ] else
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Move the slider to see potential savings',
                  style: context.t.bodySub,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // 50-30-20 budget impact note
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: kAmber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your current EMI is ${(loan.emiAmount / (loan.principalAmount / loan.tenureMonths * 1.1) * 100).clamp(0, 100).toStringAsFixed(0)}% of your loan commitment. '
                  'Extra payments directly reduce your principal.',
                  style: context.t.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimResultCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _SimResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.h2.colored(color)),
        Text(sub, style: AppTypography.captionMuted),
        const SizedBox(height: 4),
        Text(label, style: context.t.labelMuted, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TimelineRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.t.bodySmall),
        Text(value, style: AppTypography.labelLarge.colored(color)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Payment History
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final EmiLoan loan;
  final ScrollController scroll;
  const _PaymentsTab({required this.loan, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final payments = loan.payments.reversed.toList();

    if (payments.isEmpty) {
      return Center(
        child: Text('No payments recorded yet.', style: context.t.bodySub),
      );
    }

    return ListView.separated(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _PaymentRow(payment: payments[i], currency: loan.currency),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final EmiPayment payment;
  final String currency;
  const _PaymentRow({required this.payment, required this.currency});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = payment.isExtraPayment ? kAmber : kGreen;
    final fmt = NumberFormat('#,##0.00');

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              payment.isExtraPayment
                  ? Icons.add_circle_rounded
                  : Icons.check_circle_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.isExtraPayment ? 'Extra Payment' : 'EMI Payment',
                  style: context.t.labelLarge,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(payment.date),
                  style: context.t.labelMuted,
                ),
                if (payment.note.isNotEmpty)
                  Text(payment.note, style: context.t.bodySub),
              ],
            ),
          ),
          Text(
            '$currency ${fmt.format(payment.amount)}',
            style: AppTypography.amountSmall.colored(color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final EmiLoan loan;
  const _StatusBadge({required this.loan});

  @override
  Widget build(BuildContext context) {
    final color = loan.isOverdue
        ? kAccent
        : loan.isDueSoon
        ? kAmber
        : kGreen;
    final label = loan.isOverdue
        ? 'Overdue'
        : loan.isDueSoon
        ? 'Due Soon'
        : 'On Track';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: AppTypography.caption.colored(color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
