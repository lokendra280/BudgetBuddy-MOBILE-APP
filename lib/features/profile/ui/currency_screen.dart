import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/common/common_widget.dart';
import 'package:budgetBuddy/common/constant/app_typography.dart';
import 'package:budgetBuddy/features/auth/services/user_profile_service.dart';
import 'package:budgetBuddy/features/dashboard/pages/dashboard_page.dart';
import 'package:budgetBuddy/features/expense/models/expense.dart';
import 'package:budgetBuddy/features/expense/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Step 2 — Currency Screen
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyScreen extends ConsumerStatefulWidget {
  final String suggestedCurrency;
  const CurrencyScreen({super.key, required this.suggestedCurrency});
  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  late String _sel;

  @override
  void initState() {
    super.initState();
    final stored = ref.read(currencyProvider);
    _sel = stored.isNotEmpty ? stored : widget.suggestedCurrency;
  }

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    await ref.read(expenseProvider.notifier).updateBudget(currency: _sel);
    UserProfileService.saveProfile(currency: _sel);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final selInfo = currencyOf(_sel);

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _StepBar(step: 2, total: 2),
              const SizedBox(height: 24),

              const Text('💱', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Choose your currency', style: context.t.h1),
              const SizedBox(height: 6),
              Text(
                'All amounts will be shown in your preferred currency.',
                style: context.t.bodySub,
              ),

              const SizedBox(height: 20),

              // ── Currency grid ─────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.65,
                  ),
                  itemCount: kCurrencies.length,
                  itemBuilder: (_, i) {
                    final cur = kCurrencies[i];
                    final isSel = _sel == cur.code;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sel = cur.code);
                      },
                      child: _CurrencyCard(info: cur, selected: isSel),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── Preview banner ─────────────────────────────────────────────
              _CurrencyPreviewBanner(info: selInfo),

              const SizedBox(height: 14),

              AppButton(
                label: 'Get Started',
                onTap: _confirm,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings — Currency Picker Page
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyPickerPage extends ConsumerWidget {
  const CurrencyPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final selectedCode = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Select Currency', style: context.t.appBarTitle),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: kCurrencies.length,
        itemBuilder: (_, i) {
          final cur = kCurrencies[i];
          final selected = cur.code == selectedCode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.selectionClick();
                await ref
                    .read(expenseProvider.notifier)
                    .updateBudget(currency: cur.code);
                UserProfileService.saveProfile(currency: cur.code);
                if (context.mounted) Navigator.pop(context);
              },
              child: _CurrencyListTile(info: cur, selected: selected),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared private widgets — reused by both screens
// ─────────────────────────────────────────────────────────────────────────────

/// Grid card used in onboarding CurrencyScreen.
class _CurrencyCard extends StatelessWidget {
  final CurrencyInfo info;
  final bool selected;
  const _CurrencyCard({required this.info, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor.withOpacity(0.08) : c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primaryColor : c.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: !context.isDark && !selected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(info.flag, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              if (selected)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${info.name} (${info.code})',
            style: context.t.caption.colored(
              selected ? AppColors.primaryColor : context.c.textSub,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// List row used in settings CurrencyPickerPage.
class _CurrencyListTile extends StatelessWidget {
  final CurrencyInfo info;
  final bool selected;
  const _CurrencyListTile({required this.info, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor.withOpacity(0.08) : c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primaryColor : c.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(info.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.name} (${info.code})',
                  style: context.t.labelLarge.colored(
                    selected ? AppColors.primaryColor : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Symbol: ${info.symbol}', style: context.t.labelMuted),
              ],
            ),
          ),
          _SelectionDot(selected: selected),
        ],
      ),
    );
  }
}

/// Green check dot / empty circle indicator.
class _SelectionDot extends StatelessWidget {
  final bool selected;
  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.c.border, width: 1.5),
      ),
    );
  }
}

/// Bottom preview banner showing selected currency.
class _CurrencyPreviewBanner extends StatelessWidget {
  final CurrencyInfo info;
  const _CurrencyPreviewBanner({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: kGreen, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${info.flag} ${info.name} · Amounts shown as ${info.symbol}1,000',
              style: context.t.labelLarge.colored(kGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step progress bar (shared with language_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int step, total;
  const _StepBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            total,
            (i) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < step ? AppColors.primaryColor : c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Step $step of $total', style: context.t.overline),
      ],
    );
  }
}
