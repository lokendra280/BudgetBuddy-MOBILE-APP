import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/common/widgets/empty_widget.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/models/emi_loan.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/emi_loan_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/pages/emi_payment_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/add_biill_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/add_emi_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_strip_alert.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_title.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/emi_detail_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/emi_title.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommitmentsScreen  —  Bills tab + EMI & Loans tab
// ─────────────────────────────────────────────────────────────────────────────

class CommitmentsScreen extends ConsumerStatefulWidget {
  /// Pass 1 to open directly on the EMI tab (e.g. from a deep-link).
  final int initialTab;
  const CommitmentsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends ConsumerState<CommitmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tab.addListener(() => setState(() {})); // rebuild for FAB swap
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sym = ref.watch(symbolProvider);

    return Scaffold(
      backgroundColor: c.bg,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.commitments,
          style: context.t.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
            onPressed: () => _tab.index == 0
                ? _showAddBillSheet(context, ref, sym)
                : _showAddEmiSheet(context, ref),
          ),
        ],
        // ── Tab bar embedded in AppBar bottom ─────────────────────────────
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _CommitmentsTabBar(controller: _tab),
        ),
      ),

      // ── Tab views ──────────────────────────────────────────────────────────
      body: TabBarView(
        controller: _tab,
        children: const [_BillsTab(), _EmiTab()],
      ),

      // ── FAB swaps per tab ──────────────────────────────────────────────────
      floatingActionButton: _tab.index == 0
          ? _BillFab(sym: sym)
          : const _EmiFab(),
    );
  }

  // ── Sheet launchers (shared so AppBar + FAB both call the same thing) ──────

  static void _showAddBillSheet(
    BuildContext context,
    WidgetRef ref,
    String sym, {
    BillReminder? existing,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddBillSheet(existing: existing, sym: sym),
  );

  static void _showAddEmiSheet(
    BuildContext context,
    WidgetRef ref, {
    EmiLoan? existing,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddEmiSheet(existing: existing),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _CommitmentsTabBar extends StatelessWidget {
  final TabController controller;
  const _CommitmentsTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: c.bg,
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
          labelStyle: AppTypography.buttonSmall,
          unselectedLabelStyle: AppTypography.labelLarge,
          labelColor: Colors.white,
          unselectedLabelColor: c.textMuted,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 14),
                  SizedBox(width: 6),
                  Text(AppLocalizations.of(context)!.bill),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_rounded, size: 14),
                  SizedBox(width: 6),
                  Text(AppLocalizations.of(context)!.emiAndLoans),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Bills
// ─────────────────────────────────────────────────────────────────────────────

class _BillsTab extends ConsumerWidget {
  const _BillsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billReminderProvider);
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final dueSoon = state.dueSoon;
    final overdue = state.overdue;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    return Column(
      children: [
        // ── Alert strip ──────────────────────────────────────────────────
        if (overdue.isNotEmpty)
          BillAlertStrip(
            overdue: overdue,
            dueSoon: dueSoon,
            fmt: fmt,
            onTap: () {},
          ),
        if (dueSoon.isNotEmpty && overdue.isEmpty)
          BillAlertStrip(
            overdue: const [],
            dueSoon: dueSoon,
            fmt: fmt,
            onTap: () {},
          ),

        // ── Summary card ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SummaryCard(
            leftLabel: l10n.monthlyCommitments,
            leftValue: fmt(state.monthlyTotal),
            leftColor: kAccent,
            rightTop: '${state.all.length} ${l10n.bill}',
            rightBottom:
                '${state.all.where((b) => b.isActive).length} ${l10n.active}',
            rightBottomColor: kGreen,
          ),
        ),
        const SizedBox(height: 10),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: state.all.isEmpty
              ? EmptyState(onAdd: () => _showSheet(context, ref, sym))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: state.paged.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => BillTile(
                    bill: state.paged[i],
                    fmt: fmt,
                    onEdit: () =>
                        _showSheet(context, ref, sym, existing: state.paged[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, state.paged[i]),
                    onToggle: () => ref
                        .read(billReminderProvider.notifier)
                        .toggleActive(state.paged[i].id),
                  ),
                ),
        ),

        // ── Pagination ────────────────────────────────────────────────────
        if (state.totalPages > 1)
          _PaginationBar(
            page: state.page,
            totalPages: state.totalPages,
            hasPrev: state.hasPrevPage,
            hasNext: state.hasNextPage,
            onPrev: () => ref.read(billReminderProvider.notifier).prevPage(),
            onNext: () => ref.read(billReminderProvider.notifier).nextPage(),
            onDot: (i) => ref.read(billReminderProvider.notifier).goToPage(i),
          ),
      ],
    );
  }

  static void _showSheet(
    BuildContext context,
    WidgetRef ref,
    String sym, {
    BillReminder? existing,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddBillSheet(existing: existing, sym: sym),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BillReminder bill,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        title: Text(
          AppLocalizations.of(context)!.deleteBill,
          style: AppTypography.h3,
        ),
        content: Text(
          ' ${AppLocalizations.of(context)!.willBeRemoved(bill.title)}',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.body,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTypography.body.colored(kAccent),
            ),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(billReminderProvider.notifier).delete(bill.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — EMI & Loans
// ─────────────────────────────────────────────────────────────────────────────

class _EmiTab extends ConsumerWidget {
  const _EmiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emiLoanProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (state.loans.isEmpty) {
      return _EmiEmptyState(
        onAdd: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: c.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const AddEmiSheet(),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // ── Alert strip ────────────────────────────────────────────────
        if (state.overdueLoans.isNotEmpty || state.dueSoonLoans.isNotEmpty)
          SliverToBoxAdapter(
            child: BillAlertStrip(
              overdue: state.overdueLoans,
              dueSoon: state.dueSoonLoans,
              fmt: fmt,
              onTap: () {},
            ),
          ),

        // ── Summary card ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _EmiSummaryCard(state: state, fmt: fmt),
          ),
        ),

        // ── Section label ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppLocalizations.of(context)!.yourLoans,
              style: context.t.h4,
            ),
          ),
        ),

        // ── Loan tiles ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList.separated(
            itemCount: state.loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final loan = state.loans[i];
              return EmiTile(
                loan: loan,
                fmt: fmt,
                onTap: () => _showDetail(context, loan),
                onEdit: () => _showEdit(context, loan),
                onDelete: () => _confirmDelete(context, ref, loan),
                onToggle: () =>
                    ref.read(emiLoanProvider.notifier).toggleActive(loan.id),
                onPay: () => _showPaySheet(context, ref, loan, fmt),
              );
            },
          ),
        ),
      ],
    );
  }

  static void _showDetail(BuildContext context, EmiLoan loan) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.c.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => EmiDetailSheet(loan: loan),
      );

  static void _showEdit(BuildContext context, EmiLoan loan) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.c.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => AddEmiSheet(existing: loan),
      );

  static void _showPaySheet(
    BuildContext context,
    WidgetRef ref,
    EmiLoan loan,
    String Function(double) fmt,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RecordPaymentSheet(loanId: loan.id, fmt: fmt),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmiLoan loan,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        title: Text(
          AppLocalizations.of(context)!.deleteLoan,
          style: AppTypography.h3,
        ),
        content: Text(
          '${AppLocalizations.of(context)!.willBeRemoved(loan.title)}',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.body,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTypography.body.colored(kAccent),
            ),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(emiLoanProvider.notifier).deleteLoan(loan.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String leftLabel, leftValue;
  final Color leftColor;
  final String rightTop, rightBottom;
  final Color rightBottomColor;

  const _SummaryCard({
    required this.leftLabel,
    required this.leftValue,
    required this.leftColor,
    required this.rightTop,
    required this.rightBottom,
    required this.rightBottomColor,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel, style: context.t.labelMuted),
              const SizedBox(height: 4),
              Text(
                leftValue,
                style: AppTypography.amountLarge.colored(leftColor),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(rightTop, style: context.t.labelMuted),
            Text(
              rightBottom,
              style: AppTypography.labelLarge.colored(rightBottomColor),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMI summary card (3-stat layout)
// ─────────────────────────────────────────────────────────────────────────────

class _EmiSummaryCard extends StatelessWidget {
  final EmiLoanState state;
  final String Function(double) fmt;
  const _EmiSummaryCard({required this.state, required this.fmt});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          children: [
            _DashTile(
              AppLocalizations.of(context)!.outstanding,
              fmt(state.totalOutstanding),
              kAccent,
              Icons.account_balance_rounded,
            ),
            const SizedBox(width: 12),
            _DashTile(
              AppLocalizations.of(context)!.monthlyEmis,
              fmt(state.totalMonthlyEmi),
              AppColors.primaryColor,
              Icons.calendar_month_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: context.c.border, height: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatPill(
              '${state.activeLoans.length}',
              AppLocalizations.of(context)!.active,
              AppColors.primaryColor,
            ),
            _StatPill(
              '${state.overdueLoans.length}',
              AppLocalizations.of(context)!.overdue,
              kAccent,
            ),
            _StatPill(
              '${state.totalMissedPayments}',
              AppLocalizations.of(context)!.missed,
              kAmber,
            ),
          ],
        ),
      ],
    ),
  );
}

class _DashTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _DashTile(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.amount.colored(color)),
          Text(
            label,
            style: AppTypography.captionMuted.colored(context.c.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTypography.h3.colored(color)),
      Text(label, style: context.t.captionMuted),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMI empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmiEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmiEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏦', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noLoansYet, style: context.t.h2),
          const SizedBox(height: 8),
          Text(
            'Track EMIs, monitor progress\nand get reminded before due dates.',
            style: context.t.bodySub,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Add First Loan',
            onTap: onAdd,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FABs (one per tab)
// ─────────────────────────────────────────────────────────────────────────────

class _BillFab extends ConsumerWidget {
  final String sym;
  const _BillFab({required this.sym});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FloatingActionButton.extended(
        heroTag: 'fab_bill',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: context.c.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => AddBillSheet(sym: sym),
        ),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Bill',
          style: AppTypography.buttonSmall.colored(Colors.white),
        ),
      );
}

class _EmiFab extends ConsumerWidget {
  const _EmiFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FloatingActionButton.extended(
        heroTag: 'fab_emi',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: context.c.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const AddEmiSheet(),
        ),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.account_balance_rounded, color: Colors.white),
        label: Text(
          'Add Loan',
          style: AppTypography.buttonSmall.colored(Colors.white),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar (generic, used by Bills tab)
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int page, totalPages;
  final bool hasPrev, hasNext;
  final VoidCallback onPrev, onNext;
  final void Function(int) onDot;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    required this.onDot,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(Icons.chevron_left_rounded, hasPrev, onPrev),
          const SizedBox(width: 12),
          ...List.generate(
            totalPages,
            (i) => GestureDetector(
              onTap: () => onDot(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == page ? AppColors.primaryColor : c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PageBtn(Icons.chevron_right_rounded, hasNext, onNext),
          const SizedBox(width: 12),
          Text('${page + 1} / $totalPages', style: context.t.labelMuted),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn(this.icon, this.enabled, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primaryColor.withOpacity(0.1)
            : context.c.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? AppColors.primaryColor.withOpacity(0.3)
              : context.c.border,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled ? AppColors.primaryColor : context.c.textMuted,
      ),
    ),
  );
}
