import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/sms_service/providers/sms_import_provider.dart';
import 'package:budgetBuddy/features/sms_service/services/sms_parser_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});
  @override
  ConsumerState<SmsImportScreen> createState() => _State();
}

class _State extends ConsumerState<SmsImportScreen> {
  @override
  void initState() {
    super.initState();
    // Start reading SMS immediately on open
    Future.microtask(() => ref.read(smsImportProvider.notifier).readSms());
  }

  Future<void> _import() async {
    HapticFeedback.mediumImpact();
    final count = await ref.read(smsImportProvider.notifier).importSelected();
    if (!mounted) return;
    _showSuccess(count);
  }

  void _showSuccess(int count) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Import Complete 🎉',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✓', style: TextStyle(fontSize: 36, color: kGreen)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$count transactions imported',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Duplicates were automatically skipped.',
              style: TextStyle(fontSize: 12, color: context.c.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(smsImportProvider.notifier).reset();
            },
            child: Text(
              'Import more',
              style: TextStyle(color: context.c.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsImportProvider);
    final fmt = ref.watch(fmtProvider);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Import from SMS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (state.status == SmsImportStatus.parsed &&
              state.transactions.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(smsImportProvider.notifier).toggleSelectAll(),
              child: Text(
                state.hasSelected ? 'None' : 'All',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, fmt, c),
      bottomNavigationBar:
          state.status == SmsImportStatus.parsed &&
              state.transactions.isNotEmpty &&
              state.hasSelected
          ? _ImportBar(
              count: state.selectedCount,
              onImport: _import,
              loading: state.status == SmsImportStatus.importing,
            )
          : null,
    );
  }

  Widget _buildBody(
    SmsImportState state,
    String Function(double) fmt,
    AppColors c,
  ) {
    switch (state.status) {
      // ── Loading / Reading ──────────────────────────────────────────────────
      case SmsImportStatus.idle:
      case SmsImportStatus.requestingPermission:
      case SmsImportStatus.reading:
        return _LoadingView(
          message: state.status == SmsImportStatus.requestingPermission
              ? 'Requesting SMS permission…'
              : state.status == SmsImportStatus.reading
              ? 'Reading bank messages…'
              : 'Starting…',
        );

      // ── Permission denied ──────────────────────────────────────────────────
      case SmsImportStatus.permissionDenied:
        return _PermissionDeniedView(
          message: state.error ?? 'SMS permission required.',
          onRetry: () => ref.read(smsImportProvider.notifier).readSms(),
          onSettings: openAppSettings,
        );

      // ── Error ──────────────────────────────────────────────────────────────
      case SmsImportStatus.error:
        return _ErrorView(
          message: state.error ?? 'Something went wrong.',
          onRetry: () => ref.read(smsImportProvider.notifier).readSms(),
        );

      // ── Importing ─────────────────────────────────────────────────────────
      case SmsImportStatus.importing:
        return const _LoadingView(message: 'Importing transactions…');

      // ── Done ──────────────────────────────────────────────────────────────
      case SmsImportStatus.done:
        return _DoneView(
          count: state.importedCount,
          onReset: () => ref.read(smsImportProvider.notifier).reset(),
        );

      // ── Parsed — main list ─────────────────────────────────────────────────
      case SmsImportStatus.parsed:
        if (state.transactions.isEmpty) {
          return _EmptyView(
            message: state.error ?? 'No bank SMS found.',
            onRetry: () => ref.read(smsImportProvider.notifier).readSms(),
          );
        }
        return _ParsedView(state: state, fmt: fmt);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PARSED VIEW — filter chips + transaction list
// ─────────────────────────────────────────────────────────────────────────────
class _ParsedView extends ConsumerWidget {
  final SmsImportState state;
  final String Function(double) fmt;
  const _ParsedView({required this.state, required this.fmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final visible = state.visible;
    final n = ref.read(smsImportProvider.notifier);

    return Column(
      children: [
        // ── Summary bar ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          color: c.surface,
          child: Row(
            children: [
              Text(
                '${state.transactions.length} found',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (state.hasSelected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.selectedCount} selected',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Filter chips ───────────────────────────────────────────────────────
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Income / Expense toggles
                _FilterChip(
                  'Income',
                  state.filterIncome,
                  kGreen,
                  n.toggleFilterIncome,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  'Expense',
                  state.filterExpense,
                  kAccent,
                  n.toggleFilterExpense,
                ),
                const SizedBox(width: 6),
                // Bank chips
                if (state.banks.length > 1) ...[
                  _FilterChip(
                    'All Banks',
                    state.filterBank.isEmpty,
                    AppColors.primaryColor,
                    () => n.setFilterBank(''),
                  ),
                  const SizedBox(width: 6),
                  ...state.banks.map(
                    (bank) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        bank,
                        state.filterBank == bank,
                        AppColors.primaryColor,
                        () => n.setFilterBank(bank),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Divider(color: c.border, height: 1),

        // ── Transaction list ───────────────────────────────────────────────────
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        'No transactions match filters',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final tx = visible[i];
                    final globalIdx = state.transactions.indexOf(tx);
                    final isSel = state.selected.contains(globalIdx);
                    return _SmsTile(
                      tx: tx,
                      fmt: fmt,
                      selected: isSel,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(smsImportProvider.notifier)
                            .toggleOne(globalIdx);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE SMS TILE
// ─────────────────────────────────────────────────────────────────────────────
class _SmsTile extends StatelessWidget {
  final SmsTransaction tx;
  final String Function(double) fmt;
  final bool selected;
  final VoidCallback onTap;
  const _SmsTile({
    required this.tx,
    required this.fmt,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = tx.isIncome ? kGreen : kAccent;
    final catEmoji = _emoji(tx.category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor.withOpacity(0.06) : c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryColor : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryColor : c.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Category emoji
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: col.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(catEmoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            // Title + bank + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.border.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.bank,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(tx.date),
                        style: TextStyle(fontSize: 10, color: c.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + type badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isIncome ? '+' : '-'}${tx.currency == 'NPR' ? 'Rs.' : ''
                            '${tx.currency == 'INR' ? '₹' : ''
                                      '${tx.currency == 'GBP' ? '£' : ''
                                                '${tx.currency == 'USD' ? '\$' : tx.currency} '}'}'}${tx.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: col,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.category,
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

  String _emoji(String category) {
    const m = {
      'Food': '🍜',
      'Transport': '🚗',
      'Shopping': '🛍',
      'Health': '💊',
      'Bills': '⚡',
      'Entertainment': '🎬',
      'Salary': '💼',
      'Freelance': '💻',
      'Investment': '📈',
      'Gift': '🎁',
      'Other': '📦',
    };
    return m[category] ?? '📦';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPORT BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ImportBar extends StatelessWidget {
  final int count;
  final VoidCallback onImport;
  final bool loading;
  const _ImportBar({
    required this.count,
    required this.onImport,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    decoration: BoxDecoration(
      color: context.c.surface,
      border: Border(top: BorderSide(color: context.c.border)),
    ),
    child: AppButton(
      label: loading
          ? 'Importing…'
          : 'Import $count transaction${count == 1 ? '' : 's'}',
      onTap: loading ? () {} : onImport,
      icon: loading ? Icons.hourglass_top_rounded : Icons.download_rounded,
      color: AppColors.primaryColor,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE VIEWS
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color: AppColors.primaryColor,
          strokeWidth: 2,
        ),
        const SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(fontSize: 14, color: context.c.textMuted),
        ),
      ],
    ),
  );
}

class _PermissionDeniedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry, onSettings;
  const _PermissionDeniedView({
    required this.message,
    required this.onRetry,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🔒', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'SMS Permission Required',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: context.c.textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Try Again',
          onTap: onRetry,
          icon: Icons.refresh_rounded,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('Open Settings'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SpendSense only reads bank transaction SMS. '
                  'Your messages are processed on-device and never uploaded.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.c.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📭', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'No Bank SMS Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: context.c.textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const _TipsCard(),
        const SizedBox(height: 24),
        AppButton(
          label: 'Scan Again',
          onTap: onRetry,
          icon: Icons.refresh_rounded,
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'Something went wrong',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: context.c.textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Retry', onTap: onRetry, icon: Icons.refresh_rounded),
      ],
    ),
  );
}

class _DoneView extends StatelessWidget {
  final int count;
  final VoidCallback onReset;
  const _DoneView({required this.count, required this.onReset});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('✓', style: TextStyle(fontSize: 44, color: kGreen)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '$count transactions imported!',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Your expenses and income have been added to SpendSense.',
          style: TextStyle(
            fontSize: 13,
            color: context.c.textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Import More',
          onTap: onReset,
          icon: Icons.refresh_rounded,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Back to Home'),
        ),
      ],
    ),
  );
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.c.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips to get bank SMS working',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...const [
          '• Enable SMS alerts in your bank app or internet banking',
          '• Make sure your registered mobile number receives transaction SMS',
          '• Supported: eSewa, Khalti, NIC Asia, Nabil, HDFC, ICICI, SBI, Barclays, Chase and more',
          '• SMS from the last 6 months are scanned',
        ].map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 11,
                color: context.c.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.active, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.12) : context.c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color : context.c.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : context.c.textMuted,
        ),
      ),
    ),
  );
}
