import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/widgets/empty_widget.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/add_biill_sheet.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_strip_alert.dart';
import 'package:budgetBuddy/features/bill_reminder/ui/widgets/bill_title.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillReminderScreen extends ConsumerWidget {
  const BillReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billReminderProvider);
    final fmt = ref.watch(fmtProvider);
    final sym = ref.watch(symbolProvider);
    final c = context.c;
    final dueSoon = state.dueSoon;
    final overdue = state.overdue;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.billReminder,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
            tooltip: AppLocalizations.of(context)!.addBill,
            onPressed: () => _showAddSheet(context, ref, sym),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2,
              ),
            )
          : Column(
              children: [
                // ── Overdue alert strip ─────────────────────────────────────────
                if (overdue.isNotEmpty)
                  BillAlertStrip(
                    overdue: overdue,
                    dueSoon: dueSoon,
                    fmt: fmt,
                    onTap: () {},
                  ),

                // ── Due soon strip ──────────────────────────────────────────────
                if (dueSoon.isNotEmpty && overdue.isEmpty)
                  BillAlertStrip(
                    overdue: [],
                    dueSoon: dueSoon,
                    fmt: fmt,
                    onTap: () {},
                  ),

                // ── Due soon strip ──────────────────────────────────────────────
                // if (dueSoon.isNotEmpty && overdue.isEmpty)
                //   BillAlertStrip(
                //     overdue: [],
                //     dueSoon: dueSoon,
                //     fmt: (double p1) {},
                //     onTap: () {},
                //   ),

                // ── Monthly commitment summary ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.monthlyCommitments,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmt(state.monthlyTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: kAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${state.all.length} ${AppLocalizations.of(context)!.bill}',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                            Text(
                              '${state.all.where((b) => b.isActive).length} ${AppLocalizations.of(context)!.active}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Paginated bill list ─────────────────────────────────────────
                Expanded(
                  child: state.all.isEmpty
                      ? EmptyState(
                          onAdd: () => _showAddSheet(context, ref, sym),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          itemCount: state.paged.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => BillTile(
                            bill: state.paged[i],
                            fmt: fmt,
                            onEdit: () => _showAddSheet(
                              context,
                              ref,
                              sym,
                              existing: state.paged[i],
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, state.paged[i]),
                            onToggle: () => ref
                                .read(billReminderProvider.notifier)
                                .toggleActive(state.paged[i].id),
                          ),
                        ),
                ),

                // ── Pagination controls ─────────────────────────────────────────
                if (state.totalPages > 1)
                  _PaginationBar(state: state, ref: ref),
              ],
            ),

      // ── FAB — add bill ────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, sym),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.addBill,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BillReminder bill,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        title: const Text(
          'Delete bill?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('${bill.title} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(billReminderProvider.notifier).delete(bill.id);
  }

  static void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    String sym, {
    BillReminder? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddBillSheet(existing: existing, sym: sym),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final BillReminderState state;
  final WidgetRef ref;
  const _PaginationBar({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(billReminderProvider.notifier);
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
          // Prev
          _PageBtn(
            Icons.chevron_left_rounded,
            state.hasPrevPage,
            notifier.prevPage,
          ),
          const SizedBox(width: 12),
          // Page indicator dots
          ...List.generate(
            state.totalPages,
            (i) => GestureDetector(
              onTap: () => notifier.goToPage(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == state.page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == state.page ? AppColors.primaryColor : c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next
          _PageBtn(
            Icons.chevron_right_rounded,
            state.hasNextPage,
            notifier.nextPage,
          ),
          const SizedBox(width: 12),
          Text(
            '${state.page + 1} / ${state.totalPages}',
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
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
