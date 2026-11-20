import 'package:budgetbuddy/common/app_theme.dart';
import 'package:budgetbuddy/common/constant/app_typography.dart';
import 'package:budgetbuddy/common/language_screen.dart';
import 'package:budgetbuddy/common/widgets/brand_widgets.dart';
import 'package:budgetbuddy/common/widgets/piggy_mascot.dart';
import 'package:budgetbuddy/features/auth/services/user_profile_service.dart';
import 'package:budgetbuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetbuddy/features/expense/models/expense.dart';
import 'package:budgetbuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding step 2 — choose currency, then go to the dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyScreen extends ConsumerStatefulWidget {
  final String suggestedCurrency;
  const CurrencyScreen({super.key, required this.suggestedCurrency});
  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  late String _sel = widget.suggestedCurrency;
  bool _saving = false;

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);
    UserProfileService.saveProfile(currency: _sel);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardPage(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      resizeToAvoidBottomInset: true,
      body: _CurrencyBody(
        selected: _sel,
        suggested: widget.suggestedCurrency,
        header: OnboardingStepHeader(
          step: 2,
          total: 2,
          mascot: PiggyMascot(size: 54),
          bubble: '${currencyOf(_sel).symbol} ready!',
          title: 'Pick your currency',
          subtitle: 'Every amount in the app will use it.',
        ),
        onSelect: (code) {
          HapticFeedback.selectionClick();
          setState(() => _sel = code);
        },
        cta: BottomCta(label: 'Get Started', busy: _saving, onTap: _confirm),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings — same design; picking a currency saves and closes.
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyPickerPage extends ConsumerStatefulWidget {
  const CurrencyPickerPage({super.key});
  @override
  ConsumerState<CurrencyPickerPage> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends ConsumerState<CurrencyPickerPage> {
  late String _sel = ref.read(currencyProvider);
  bool _saving = false;

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);
    UserProfileService.saveProfile(currency: _sel);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currencyProvider);
    return Scaffold(
      backgroundColor: context.c.bg,
      body: _CurrencyBody(
        selected: _sel,
        suggested: current,
        suggestedLabel: 'Current',
        header: OnboardingStepHeader(
          step: 1,
          total: 1,
          showSteps: false,
          onBack: () => Navigator.pop(context),
          mascot: PiggyMascot(size: 50),
          bubble: '${currencyOf(_sel).symbol} it is!',
          title: 'Currency',
          subtitle: 'New entries use this currency. Past entries keep theirs.',
        ),
        onSelect: (code) {
          HapticFeedback.selectionClick();
          setState(() => _sel = code);
        },
        cta: BottomCta(
          label: _sel == current ? 'Done' : 'Save',
          busy: _saving,
          onTap: _sel == current ? () => Navigator.pop(context) : _save,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared body: header · search · suggested · list · preview · CTA
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyBody extends StatefulWidget {
  final String selected;
  final String suggested;
  final String suggestedLabel;
  final Widget header;
  final Widget cta;
  final ValueChanged<String> onSelect;

  const _CurrencyBody({
    required this.selected,
    required this.suggested,
    required this.header,
    required this.cta,
    required this.onSelect,
    this.suggestedLabel = 'Suggested for you',
  });

  @override
  State<_CurrencyBody> createState() => _CurrencyBodyState();
}

class _CurrencyBodyState extends State<_CurrencyBody> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final filtered = kCurrencies.where((c) {
      if (q.isEmpty) return c.code != widget.suggested;
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();
    final suggestedInfo = kCurrencies
        .where((c) => c.code == widget.suggested)
        .firstOrNull;

    return Column(
      children: [
        widget.header,
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: _SearchField(onChanged: (v) => setState(() => _q = v)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _PreviewCard(info: currencyOf(widget.selected)),
              const SizedBox(height: 18),
              if (q.isEmpty && suggestedInfo != null) ...[
                SectionHeader(widget.suggestedLabel),
                _CurrencyTile(
                  info: suggestedInfo,
                  selected: widget.selected == suggestedInfo.code,
                  onTap: () => widget.onSelect(suggestedInfo.code),
                ),
                const SizedBox(height: 18),
                const SectionHeader('All currencies'),
              ],
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No currency matches "$_q"',
                      style: context.t.bodySub,
                    ),
                  ),
                ),
              for (final cur in filtered) ...[
                _CurrencyTile(
                  info: cur,
                  selected: widget.selected == cur.code,
                  onTap: () => widget.onSelect(cur.code),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        widget.cta,
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.t.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search currency or code',
        hintStyle: context.t.bodySub,
        prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
        filled: true,
        fillColor: c.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kMidGreen, width: 1.4),
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final CurrencyInfo info;
  final bool selected;
  final VoidCallback onTap;
  const _CurrencyTile({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Text(info.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: context.t.labelLarge.weighted(FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(info.code, style: context.t.labelMuted),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            margin: const EdgeInsets.only(right: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? kMidGreen
                  : (context.isDark ? context.c.cardElevated : kMint),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              info.symbol,
              style: context.t.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : kMidGreen,
              ),
            ),
          ),
          SelectionCheck(selected: selected),
        ],
      ),
    );
  }
}

/// Mini balance card that shows how amounts will look.
class _PreviewCard extends StatelessWidget {
  final CurrencyInfo info;
  const _PreviewCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final n = NumberFormat('#,##0');
    return BrandHeroCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: context.heroLabel),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: FittedBox(
                    key: ValueKey(info.code),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${info.symbol}${n.format(24580)}',
                      style: context.heroValue,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Spent today ${info.symbol}${n.format(450)}',
                  style: context.heroBody,
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(info.flag, style: const TextStyle(fontSize: 26)),
          ),
        ],
      ),
    );
  }
}
