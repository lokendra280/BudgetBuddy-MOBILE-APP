import 'package:expensetracker/common/common_svg_widget.dart';
import 'package:expensetracker/common/constant/constant_assets.dart';
import 'package:expensetracker/features/auth/providers/auth_provider.dart';
import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/common_widget.dart';
import 'package:expensetracker/features/profile/services/refers_service.dart';
import 'package:expensetracker/features/social/providers/social_provider.dart';
import 'package:expensetracker/features/social/services/share_service.dart';
import 'package:expensetracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteTab extends ConsumerStatefulWidget {
  const InviteTab();
  @override
  ConsumerState<InviteTab> createState() => _InviteState();
}

class _InviteState extends ConsumerState<InviteTab> {
  final _codeCtrl = TextEditingController();
  bool _applying = false;
  String? _applyMsg;
  bool _applySuccess = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Apply a friend's referral code ─────────────────────────────────────────
  Future<void> _applyCode() async {
    final input = _codeCtrl.text.trim().toUpperCase();
    if (input.isEmpty) {
      setState(() {
        _applyMsg = 'Enter a code first';
        _applySuccess = false;
      });
      return;
    }

    setState(() {
      _applying = true;
      _applyMsg = null;
    });

    final result = await ref.read(referralProvider.notifier).applyCode(input);

    String msg;
    bool ok = false;
    switch (result) {
      case ApplyResult.success:
        msg = '🎉 Code applied! You got +3 bonus streak days.';
        ok = true;
        _codeCtrl.clear();
        break;
      case ApplyResult.alreadyUsed:
        msg = 'You already used a referral code.';
        break;
      case ApplyResult.ownCode:
        msg = 'You can\'t use your own code.';
        break;
      case ApplyResult.notFound:
        msg = 'Code not found. Check and try again.';
        break;
      case ApplyResult.notLoggedIn:
        msg = 'Sign in to apply a referral code.';
        break;
      case ApplyResult.error:
        msg = 'Something went wrong. Try again.';
        break;
    }

    setState(() {
      _applying = false;
      _applyMsg = msg;
      _applySuccess = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref2 = ref;
    final state = ref2.watch(referralProvider);
    final auth = ref2.watch(authProvider);
    final c = context.c;
    final code = state.code;
    final count = state.count;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // ── Hero invite card ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.14),
                AppColors.primaryColor.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(Assets.gift, height: 60),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.inviteFriends,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.bothGetBonus,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 18),

              if (state.isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              else if (code != null) ...[
                // ── Your code ───────────────────────────────────────────────────
                Text(
                  AppLocalizations.of(context)!.yourCode,
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
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
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Copy button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                            backgroundColor: kGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Share invite + share report row
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: AppLocalizations.of(context)!.shareInvite,
                        icon: Icons.share_rounded,
                        onTap: () =>
                            ref2.read(referralProvider.notifier).share(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ShareService.shareReport(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: kGreen.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: kGreen,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Apply a friend's code card ──────────────────────────────────────────
        // Only shown if: logged in AND hasn't already used a code
        if (auth.isLoggedIn && !state.hasUsedCode)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔑', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Have a friend\'s code?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter it to give them credit and earn +3 streak days for yourself.',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Code input + Apply button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                        onChanged: (_) => setState(() => _applyMsg = null),
                        decoration: InputDecoration(
                          hintText: 'XXXXXX',
                          hintStyle: TextStyle(
                            color: c.border,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                          filled: true,
                          fillColor: c.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: c.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _applying
                        ? const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _applyCode,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                  ],
                ),

                // Apply result message
                if (_applyMsg != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_applySuccess ? kGreen : kAccent).withOpacity(
                        0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_applySuccess ? kGreen : kAccent).withOpacity(
                          0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _applySuccess ? '✅' : '⚠️',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _applyMsg!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: _applySuccess ? kGreen : kAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Already used code banner
        if (auth.isLoggedIn && state.hasUsedCode) ...[
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('✅', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referral code applied!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kGreen,
                        ),
                      ),
                      Text(
                        'You earned +3 bonus streak days.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Not logged in — prompt
        if (!auth.isLoggedIn) ...[
          AppCard(
            child: Row(
              children: [
                const Text('🔑', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.signIntoApply,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── Share report ───────────────────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CommonSvgWidget(
                  svgName: Assets.share,
                  height: 18,
                  width: 18,
                  color: kGreen,
                ),
                // child: const Icon(
                //   Icons.ios_share_rounded,
                //   color: kGreen,
                //   size: 20,
                // ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.shareReport,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.shareMonthly,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ShareService.shareReport(context),
                child: Text(
                  AppLocalizations.of(context)!.share,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Friend count ───────────────────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              CommonSvgWidget(
                svgName: Assets.social,
                height: 20,
                width: 20,
                color: AppColors.primaryColor,
              ),

              // const Text('👥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count friend${count == 1 ? '' : 's'} invited',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.keepSharing,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${count * 3} streak days',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── How it works ───────────────────────────────────────────────────────
        SectionLabel(AppLocalizations.of(context)!.howItWork),
        const SizedBox(height: 12),
        ...[
          ('1️⃣', '${AppLocalizations.of(context)!.shareYourCode}'),
          ('2️⃣', '${AppLocalizations.of(context)!.friendDownloads}'),
          ('3️⃣', '${AppLocalizations.of(context)!.theyGoToCommunity}'),
          ('4️⃣', '${AppLocalizations.of(context)!.bothGetBonus}'),
          ('5️⃣', '${AppLocalizations.of(context)!.completeTogether}'),
        ].map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.$2,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
