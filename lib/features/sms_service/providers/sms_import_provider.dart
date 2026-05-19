import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/sms_service/services/sms_parser_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────
enum SmsImportStatus {
  idle,
  requestingPermission,
  permissionDenied,
  reading,
  parsed,
  importing,
  done,
  error,
}

class SmsImportState {
  final SmsImportStatus status;
  final List<SmsTransaction> transactions; // all parsed
  final Set<int> selected; // indices selected for import
  final int importedCount;
  final String? error;
  final String filterBank; // '' = all banks
  final bool filterIncome;
  final bool filterExpense;

  const SmsImportState({
    this.status = SmsImportStatus.idle,
    this.transactions = const [],
    this.selected = const {},
    this.importedCount = 0,
    this.error,
    this.filterBank = '',
    this.filterIncome = true,
    this.filterExpense = true,
  });

  SmsImportState copyWith({
    SmsImportStatus? status,
    List<SmsTransaction>? transactions,
    Set<int>? selected,
    int? importedCount,
    String? error,
    String? filterBank,
    bool? filterIncome,
    bool? filterExpense,
  }) => SmsImportState(
    status: status ?? this.status,
    transactions: transactions ?? this.transactions,
    selected: selected ?? this.selected,
    importedCount: importedCount ?? this.importedCount,
    error: error ?? this.error,
    filterBank: filterBank ?? this.filterBank,
    filterIncome: filterIncome ?? this.filterIncome,
    filterExpense: filterExpense ?? this.filterExpense,
  );

  // Visible after applying filters
  List<SmsTransaction> get visible => transactions.where((t) {
    if (!filterIncome && t.isIncome) return false;
    if (!filterExpense && !t.isIncome) return false;
    if (filterBank.isNotEmpty && t.bank != filterBank) return false;
    return true;
  }).toList();

  // All unique banks detected
  List<String> get banks =>
      transactions.map((t) => t.bank).toSet().toList()..sort();

  bool get hasSelected => selected.isNotEmpty;
  int get selectedCount => selected.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class SmsImportNotifier extends Notifier<SmsImportState> {
  @override
  SmsImportState build() => const SmsImportState();

  // ── Step 1: Request permission + read SMS ─────────────────────────────────
  Future<void> readSms() async {
    state = state.copyWith(status: SmsImportStatus.requestingPermission);

    // Request READ_SMS permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      state = state.copyWith(
        status: SmsImportStatus.permissionDenied,
        error: status.isPermanentlyDenied
            ? 'SMS permission permanently denied. Enable in phone Settings → Apps → SpendSense → Permissions.'
            : 'SMS permission denied. Please allow to import transactions.',
      );
      return;
    }

    state = state.copyWith(status: SmsImportStatus.reading);

    try {
      final telephony = Telephony.instance;

      // Read last 500 inbox SMS — filter by common bank sender patterns
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(
          // Last 6 months only
          DateTime.now()
              .subtract(const Duration(days: 180))
              .millisecondsSinceEpoch
              .toString(),
        ),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      if (messages == null || messages.isEmpty) {
        state = state.copyWith(
          status: SmsImportStatus.parsed,
          transactions: [],
          error: 'No SMS messages found in the last 6 months.',
        );
        return;
      }

      // Parse all messages through SmsParserService
      final rawList = messages
          .map(
            (m) => (
              body: m.body ?? '',
              sender: m.address ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(m.date ?? 0),
            ),
          )
          .where((m) => m.body.isNotEmpty)
          .toList();

      final parsed = SmsParserService.parseAll(rawList);

      // Pre-select all by default
      final allIdx = Set<int>.from(List.generate(parsed.length, (i) => i));

      state = state.copyWith(
        status: SmsImportStatus.parsed,
        transactions: parsed,
        selected: allIdx,
        error: parsed.isEmpty
            ? 'No bank transactions found in SMS. Make sure you receive SMS alerts from your bank.'
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SmsImportStatus.error,
        error: 'Failed to read SMS: $e',
      );
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────
  void toggleOne(int idx) {
    final s = Set<int>.from(state.selected);
    s.contains(idx) ? s.remove(idx) : s.add(idx);
    state = state.copyWith(selected: s);
  }

  void selectAll() {
    final visible = state.visible;
    final allIdx = state.transactions
        .asMap()
        .entries
        .where((e) => visible.contains(e.value))
        .map((e) => e.key)
        .toSet();
    state = state.copyWith(selected: allIdx);
  }

  void deselectAll() => state = state.copyWith(selected: {});

  void toggleSelectAll() => state.hasSelected ? deselectAll() : selectAll();

  // ── Filters ───────────────────────────────────────────────────────────────
  void setFilterBank(String bank) => state = state.copyWith(filterBank: bank);
  void toggleFilterIncome() =>
      state = state.copyWith(filterIncome: !state.filterIncome);
  void toggleFilterExpense() =>
      state = state.copyWith(filterExpense: !state.filterExpense);

  // ── Step 2: Import selected into Hive via expenseProvider ────────────────
  Future<int> importSelected() async {
    if (!state.hasSelected) return 0;
    state = state.copyWith(status: SmsImportStatus.importing);

    final notifier = ref.read(expenseProvider.notifier);
    final existing = ref.read(expenseProvider).all;
    int count = 0;

    for (final idx in state.selected) {
      final tx = state.transactions[idx];

      // Duplicate check: same amount + same date (within 1 minute) + same type
      final isDuplicate = existing.any(
        (e) =>
            e.amount == tx.amount &&
            e.isIncome == tx.isIncome &&
            e.date.difference(tx.date).inMinutes.abs() < 2,
      );

      if (isDuplicate) continue;

      await notifier.addExpense(
        title: tx.title,
        amount: tx.amount,
        category: tx.category,
        isIncome: tx.isIncome,
        date: tx.date,
      );
      count++;
    }

    state = state.copyWith(
      status: SmsImportStatus.done,
      importedCount: count,
      selected: {},
    );
    return count;
  }

  void reset() => state = const SmsImportState();
}

final smsImportProvider = NotifierProvider<SmsImportNotifier, SmsImportState>(
  SmsImportNotifier.new,
);
