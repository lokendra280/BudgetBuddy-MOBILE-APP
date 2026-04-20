import 'package:expensetracker/ai_screen/pages/widget/shared_wdiget.dart';
import 'package:expensetracker/ai_screen/providers/ai_providers.dart';
import 'package:expensetracker/ai_screen/services/ai_services.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsTab extends ConsumerStatefulWidget {
  const GoalsTab({super.key});
  @override
  ConsumerState<GoalsTab> createState() => _GoalsState();
}

class _GoalsState extends ConsumerState<GoalsTab> {
  static const _emojis = [
    '🎯',
    '🏠',
    '🚗',
    '✈️',
    '💍',
    '📱',
    '🎓',
    '💰',
    '🏖️',
    '🎮',
  ];

  // ── Add goal bottom sheet ──────────────────────────────────────────────────
  void _showAdd() {
    final name = TextEditingController();
    final target = TextEditingController();
    final days = TextEditingController(text: '90');
    final sym = ref.read(symbolProvider);
    String emoji = '🎯';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Savings Goal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Emoji picker
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ss(() => emoji = e);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: emoji == e
                                ? AppColors.primaryColor.withOpacity(0.12)
                                : ctx.c.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: emoji == e
                                  ? AppColors.primaryColor
                                  : ctx.c.border,
                              width: emoji == e ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),

              // Name field
              _Field(name, ctx, 'Goal name (e.g. New Phone)'),
              const SizedBox(height: 10),

              // Target + Days row
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      target,
                      ctx,
                      'Target amount',
                      prefix: sym,
                      type: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      days,
                      ctx,
                      'Days to save',
                      suffix: 'days',
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Create button
              AppButton(
                label: 'Create Goal',
                icon: Icons.add_rounded,
                onTap: () async {
                  if (name.text.isEmpty || target.text.isEmpty) return;
                  final t = double.tryParse(target.text) ?? 0;
                  if (t <= 0) return;
                  // ✅ Saves to Hive immediately, Supabase sync happens in background
                  await ref
                      .read(goalsNotifierProvider.notifier)
                      .add(
                        name.text.trim(),
                        emoji,
                        t,
                        int.tryParse(days.text) ?? 90,
                      );
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add savings amount bottom sheet ───────────────────────────────────────
  void _showAddAmount(SavingsGoal g) {
    final ctrl = TextEditingController();
    final sym = ref.read(symbolProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to "${g.name}"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _Field(
              ctrl,
              context,
              'Amount saved',
              prefix: sym,
              type: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onTap: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt <= 0) return;
                // ✅ Updates Hive immediately, Supabase sync in background
                await ref
                    .read(goalsNotifierProvider.notifier)
                    .addAmount(g.id, amt);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(
      goalsNotifierProvider,
    ); // reactive from Hive listenable
    final sym = ref.watch(symbolProvider);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Savings Goals'),
            GestureDetector(
              onTap: _showAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'New Goal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Empty state
        if (goals.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  'No savings goals yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a goal to track progress towards a target.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Create my first goal',
                  icon: Icons.add_rounded,
                  onTap: _showAdd,
                ),
              ],
            ),
          )
        // Goal cards
        else
          ...goals.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + delete
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              g.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${g.daysLeft} days · Save $sym${g.dailySuggestion.toStringAsFixed(0)}/day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: c.textMuted,
                          ),
                          // ✅ Deletes from Hive, Supabase delete in background
                          onPressed: () => ref
                              .read(goalsNotifierProvider.notifier)
                              .delete(g.id),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$sym${g.saved.toStringAsFixed(0)} saved',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Target: $sym${g.target.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress bar
                    ProgressBar(
                      g.progress,
                      g.progress >= 1 ? kGreen : AppColors.primaryColor,
                      height: 10,
                      clip: 6,
                    ),
                    const SizedBox(height: 6),

                    // Completion % + add savings button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(g.progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 11,
                            color: g.progress >= 1 ? kGreen : c.textMuted,
                            fontWeight: g.progress >= 1
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (g.progress < 1)
                          GestureDetector(
                            onTap: () => _showAddAmount(g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '+ Add savings',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Text field helper ──────────────────────────────────────────────────────────
Widget _Field(
  TextEditingController c,
  BuildContext ctx,
  String hint, {
  String? prefix,
  String? suffix,
  TextInputType? type,
  bool autofocus = false,
}) => TextField(
  controller: c,
  keyboardType: type,
  autofocus: autofocus,
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: ctx.c.textMuted),
    prefixText: prefix,
    suffixText: suffix,
    filled: true,
    fillColor: ctx.c.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ctx.c.border),
    ),
  ),
);
