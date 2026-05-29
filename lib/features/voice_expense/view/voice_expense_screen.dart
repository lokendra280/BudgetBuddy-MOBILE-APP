import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_l10n.dart';
import 'package:budgetBuddy/features/voice_expense/providers/%20providers.dart';
import 'package:budgetBuddy/features/voice_expense/view/widgets/examples_box.dart';
import 'package:budgetBuddy/features/voice_expense/view/widgets/mic_button.dart';
import 'package:budgetBuddy/features/voice_expense/view/widgets/result_card.dart';
import 'package:budgetBuddy/features/voice_expense/view/widgets/transcript_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceExpenseScreen extends ConsumerWidget {
  const VoiceExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final fmt = ref.watch(fmtProvider);
    final lang = ref.watch(activeLangProvider);
    final l10n = l10nMap[lang] ?? l10nMap['en']!;
    final p = ref.watch(voicePresenterProvider.notifier);
    final state = ref.watch(voicePresenterProvider);
    final result = ref.watch(voiceResultProvider);
      
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            initialValue: lang,
            onSelected: p.onLangChanged,
            child: Chip(
              label: Text(
                lang.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              visualDensity: VisualDensity.compact,
            ),
            itemBuilder: (_) => l10nMap.entries
                .map(
                  (e) =>
                      PopupMenuItem(value: e.key, child: Text(e.value.title)),
                )
                .toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            MicButton(listening: state.listening, onTap: p.toggleListen),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                state.status,
                key: ValueKey(state.status),
                style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            if (state.transcript.isNotEmpty) ...[
              const SizedBox(height: 16),
              TranscriptBox(text: state.transcript),
            ],
            if (result != null) ...[
              const SizedBox(height: 24),
              ResultCard(result: result, fmt: fmt, l10n: l10n),
              const SizedBox(height: 14),
              AppButton(
                label: state.saving ? l10n.saving : l10n.confirm,
                onTap: state.saving ? () {} : p.save,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: p.retry,
                child: Text(l10n.retry, style: TextStyle(color: kAccent)),
              ),
            ],
            const SizedBox(height: 32),
            ExamplesBox(l10n: l10n),
          ],
        ),
      ),
    );
  }
}
