import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/bill_reminder/models/bill_reminder.dart';
import 'package:budgetBuddy/features/bill_reminder/providers/bill_reminder_provider.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BILL REMINDER SCREEN — paginated list with due-soon alerts
//
// WHERE TO SHOW IN APP:
//   1. Home screen drawer → "Bills & Reminders" menu item
//   2. Home screen → floating "Bills due soon" alert strip above FAB
//   3. App Drawer badge showing count of due-soon bills
//   4. Notifications → tapping opens this screen directly
// ─────────────────────────────────────────────────────────────────────────────
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
        title: const Text(
          'Bills & Reminders',
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
            tooltip: 'Add bill',
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
                  _AlertStrip(
                    emoji: '🚨',
                    color: kAccent,
                    message:
                        '${overdue.length} bill${overdue.length == 1 ? '' : 's'} overdue — pay now!',
                  ),

                // ── Due soon strip ──────────────────────────────────────────────
                if (dueSoon.isNotEmpty && overdue.isEmpty)
                  _AlertStrip(
                    emoji: '⏰',
                    color: kAmber,
                    message:
                        '${dueSoon.length} bill${dueSoon.length == 1 ? '' : 's'} due within ${dueSoon.first.remindDaysBefore} days',
                  ),

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
                                'Monthly Commitments',
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
                              '${state.all.length} bills',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                            Text(
                              '${state.all.where((b) => b.isActive).length} active',
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
                      ? _EmptyState(
                          onAdd: () => _showAddSheet(context, ref, sym),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          itemCount: state.paged.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _BillTile(
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
        label: const Text(
          'Add Bill',
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
        content: Text(
          '${bill.emoji} ${bill.title} will be removed.',
          style: TextStyle(color: context.c.textMuted),
        ),
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
      builder: (_) => _AddBillSheet(existing: existing, sym: sym),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD / EDIT BILL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _AddBillSheet extends ConsumerStatefulWidget {
  final BillReminder? existing;
  final String sym;
  const _AddBillSheet({this.existing, required this.sym});
  @override
  ConsumerState<_AddBillSheet> createState() => _AddState();
}

class _AddState extends ConsumerState<_AddBillSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = kBillCategories[0];
  int _dayOfMonth = 1;
  int _remindDays = 3;
  bool _isRecurring = true;
  bool _saving = false;
  DateTime? _oneTimeDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _category = e.category;
      _dayOfMonth = e.dayOfMonth;
      _remindDays = e.remindDaysBefore;
      _isRecurring = e.isRecurring;
      _oneTimeDate = e.nextDueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final notifier = ref.read(billReminderProvider.notifier);
    final sym = ref.read(currencyProvider);

    final bill = BillReminder(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      category: _category,
      dayOfMonth: _dayOfMonth,
      currency: sym,
      remindDaysBefore: _remindDays,
      isRecurring: _isRecurring,
      nextDueDate: _oneTimeDate,
      emoji: kBillEmojis[_category] ?? '📋',
    );

    widget.existing != null
        ? await notifier.update(bill)
        : await notifier.add(bill);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            const SizedBox(height: 18),

            Text(
              widget.existing != null ? 'Edit Bill' : 'Add Bill / EMI',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),

            // Title
            InputField(
              hint: 'Bill name (e.g. Netflix, Home EMI)',
              controller: _titleCtrl,
              prefix: Text(
                kBillEmojis[_category] ?? '📋',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            InputField(
              hint: 'Amount',
              controller: _amountCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              prefix: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.sym,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category picker
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kBillCategories
                    .map(
                      (cat) => GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _category == cat
                                ? AppColors.primaryColor
                                : c.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _category == cat
                                  ? AppColors.primaryColor
                                  : c.border,
                            ),
                          ),
                          child: Text(
                            '${kBillEmojis[cat]} $cat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _category == cat
                                  ? Colors.white
                                  : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recurring monthly',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isRecurring
                            ? 'Repeats every month'
                            : 'One-time payment',
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Due day (recurring) or date picker (one-time)
            if (_isRecurring) ...[
              Text(
                'Due on day of month',
                style: TextStyle(
                  fontSize: 12,
                  color: c.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 5, 7, 10, 15, 20, 25, 28]
                      .map(
                        (d) => GestureDetector(
                          onTap: () => setState(() => _dayOfMonth = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _dayOfMonth == d
                                  ? AppColors.primaryColor
                                  : c.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dayOfMonth == d
                                    ? AppColors.primaryColor
                                    : c.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$d',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _dayOfMonth == d
                                      ? Colors.white
                                      : c.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _oneTimeDate ??
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _oneTimeDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _oneTimeDate != null
                            ? DateFormat('MMM d, yyyy').format(_oneTimeDate!)
                            : 'Select due date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _oneTimeDate != null ? null : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Remind days before
            Text(
              'Remind me before',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 5, 7]
                  .map(
                    (d) => GestureDetector(
                      onTap: () => setState(() => _remindDays = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _remindDays == d ? kGreen : c.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _remindDays == d ? kGreen : c.border,
                          ),
                        ),
                        child: Text(
                          '$d day${d == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _remindDays == d
                                ? Colors.white
                                : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            AppButton(
              label: _saving
                  ? 'Saving…'
                  : (widget.existing != null
                        ? 'Update Bill'
                        : 'Add & Schedule Reminder'),
              onTap: _saving ? () {} : _save,
              icon: Icons.notifications_active_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILL TILE
// ─────────────────────────────────────────────────────────────────────────────
class _BillTile extends StatelessWidget {
  final BillReminder bill;
  final String Function(double) fmt;
  final VoidCallback onEdit, onDelete, onToggle;
  const _BillTile({
    required this.bill,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final days = bill.daysUntilDue;
    final overdue = bill.isOverdue;
    final dueSoon = bill.isDueSoon;
    final col = overdue
        ? kAccent
        : dueSoon
        ? kAmber
        : AppColors.primaryColor;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: col.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(bill.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Tag(bill.category, c.textMuted, c.border),
                    const SizedBox(width: 6),
                    _Tag(
                      bill.isRecurring ? 'Monthly' : 'One-time',
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Due date pill
                _DuePill(
                  days: days,
                  overdue: overdue,
                  dueDate: bill.computedDueDate,
                  col: col,
                ),
              ],
            ),
          ),

          // Amount + controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt(bill.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: bill.isActive ? col : c.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle active
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      bill.isActive
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      size: 18,
                      color: bill.isActive ? kGreen : c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: kAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color text2, bg;
  const _Tag(this.text, this.text2, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg.withOpacity(0.15),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, color: text2, fontWeight: FontWeight.w600),
    ),
  );
}

class _DuePill extends StatelessWidget {
  final int days;
  final bool overdue;
  final DateTime dueDate;
  final Color col;
  const _DuePill({
    required this.days,
    required this.overdue,
    required this.dueDate,
    required this.col,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.calendar_today_rounded, size: 10, color: col),
      const SizedBox(width: 4),
      Text(
        overdue
            ? 'Overdue!'
            : days == 0
            ? 'Due today!'
            : days == 1
            ? 'Due tomorrow'
            : 'Due in $days days · ${DateFormat('MMM d').format(dueDate)}',
        style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600),
      ),
    ],
  );
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

// Alert strip
class _AlertStrip extends StatelessWidget {
  final String emoji, message;
  final Color color;
  const _AlertStrip({
    required this.emoji,
    required this.message,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    color: color.withOpacity(0.08),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18, color: color),
      ],
    ),
  );
}

// Empty state
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'No bills added yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add bills, EMIs and subscriptions to\nget reminded before they\'re due.',
            style: TextStyle(
              fontSize: 13,
              color: context.c.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Add First Bill',
            onTap: onAdd,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    ),
  );
}
