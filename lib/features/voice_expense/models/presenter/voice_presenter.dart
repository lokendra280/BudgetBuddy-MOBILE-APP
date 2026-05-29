import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_l10n.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_result.dart';
import 'package:budgetBuddy/features/voice_expense/providers/%20providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ── State ────────────────────────────────────────────────────────
class VoiceState {
  final bool listening, saving, available;
  final String status, transcript;
  const VoiceState({
    this.listening = false,
    this.saving = false,
    this.available = false,
    this.status = '',
    this.transcript = '',
  });
  VoiceState copyWith({
    bool? listening,
    bool? saving,
    bool? available,
    String? status,
    String? transcript,
  }) => VoiceState(
    listening: listening ?? this.listening,
    saving: saving ?? this.saving,
    available: available ?? this.available,
    status: status ?? this.status,
    transcript: transcript ?? this.transcript,
  );
}

// ── Presenter ────────────────────────────────────────────────────
class VoicePresenter extends StateNotifier<VoiceState> {
  VoicePresenter(this._ref) : super(const VoiceState()) {
    _init();
  }

  final Ref _ref;
  final _stt = SpeechToText();

  VoiceL10n get _l10n =>
      l10nMap[_ref.read(activeLangProvider)] ?? l10nMap['en']!;

  Future<void> _init() async {
    final ok = await _stt.initialize(
      onError: (e) => _set(status: 'Error: ${e.errorMsg}'),
      onStatus: (s) => _set(listening: s == 'listening'),
    );
    _set(available: ok, status: ok ? _l10n.tapToStart : 'Speech unavailable');
  }

  // Replace _set with a mounted-safe version
  void _set({
    bool? listening,
    bool? saving,
    bool? available,
    String? status,
    String? transcript,
  }) {
    if (!mounted) return; // ← guard added
    state = state.copyWith(
      listening: listening,
      saving: saving,
      available: available,
      status: status,
      transcript: transcript,
    );
  }

  Future<void> toggleListen() async {
    if (!state.available) return;
    HapticFeedback.mediumImpact();
    if (state.listening) {
      _stt.stop();
      return;
    }

    _ref.read(voiceResultProvider.notifier).state = null;
    _set(transcript: '', status: _l10n.listening);

    await _stt.listen(
      localeId: _l10n.locale,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      onResult: (r) {
        _set(transcript: r.recognizedWords);
        if (r.finalResult) _parse(r.recognizedWords);
      },
    );
  }

  void _parse(String text) {
    if (!mounted) return; // ← guard added
    final result = _parseVoice(text, _l10n);
    if (result == null) {
      _set(status: _l10n.errorAmount);
      return;
    }
    _ref.read(voiceResultProvider.notifier).state = result;
    _set(status: _l10n.confirmMsg);
  }

  Future<void> save() async {
    final result = _ref.read(voiceResultProvider);
    if (result == null) return;
    HapticFeedback.mediumImpact();
    _set(saving: true);
    await _ref
        .read(expenseProvider.notifier)
        .addExpense(
          title: result.title,
          amount: result.amount,
          category: result.category,
          isIncome: result.isIncome,
          date: DateTime.now(),
        );
    _ref.read(voiceResultProvider.notifier).state = null;
    _set(saving: false, transcript: '', status: _l10n.saved);
    HapticFeedback.heavyImpact();
  }

  void retry() {
    _ref.read(voiceResultProvider.notifier).state = null;
    _set(transcript: '', status: _l10n.tapToStart);
    toggleListen();
  }

  void onLangChanged(String code) {
    _ref.read(activeLangProvider.notifier).state = code;
    _set(status: (l10nMap[code] ?? l10nMap['en']!).tapToStart);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }
}

// ── Pure parse helper ────────────────────────────────────────────
VoiceResult? _parseVoice(String text, VoiceL10n l) {
  final lower = text.toLowerCase();

  // ── Convert Devanagari digits → ASCII ──────────────────────────
  final normalized = lower.replaceAllMapped(
    RegExp(r'[०-९]'),
    (m) => (m.group(0)!.codeUnitAt(0) - 0x0966).toString(),
  );

  // ── Extract amount ─────────────────────────────────────────────
  final amt = double.tryParse(
    RegExp(
          r'(\d[\d,]*\.?\d*)',
        ).firstMatch(normalized)?.group(1)?.replaceAll(',', '') ??
        '',
  );
  if (amt == null || amt <= 0) return null;

  // ── Income detection ───────────────────────────────────────────
  final isIncome = l.incomeWords.any(normalized.contains);

  // ── Category detection ─────────────────────────────────────────
  var cat = l.cats.entries
      .firstWhere(
        (e) => e.value.hasMatch(normalized),
        orElse: () => MapEntry('other', RegExp('')),
      )
      .key;
  if (isIncome && cat == 'other') cat = 'salary';

  // ── Title extraction ───────────────────────────────────────────
  final title =
      l.titleRx?.firstMatch(text)?.group(1)?.trim() ??
      (isIncome ? l.catNames['salary'] : l.catNames[cat]) ??
      'Other';

  return VoiceResult(
    title: title,
    category: l.catNames[cat] ?? cat,
    amount: amt,
    isIncome: isIncome,
  );
}
