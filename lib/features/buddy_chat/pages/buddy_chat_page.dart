import 'package:budgetBuddy/features/buddy_chat/pages/widgets/chat_bubble.dart';
import 'package:budgetBuddy/features/buddy_chat/pages/widgets/chat_input.dart';
import 'package:budgetBuddy/features/buddy_chat/pages/widgets/suggestion_chips.dart';
import 'package:budgetBuddy/features/buddy_chat/pages/widgets/typing_indicator.dart';
import 'package:budgetBuddy/common/services/ads_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetBuddy/common/app_theme.dart';
import 'package:budgetBuddy/features/buddy_chat/providers/chat_provider.dart';

class BuddyChatPage extends ConsumerStatefulWidget {
  const BuddyChatPage({super.key});

  @override
  ConsumerState<BuddyChatPage> createState() => _BuddyChatPageState();
}

class _BuddyChatPageState extends ConsumerState<BuddyChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send — checks ad gate first ───────────────────────────────────────────
  void _send(String text) {
    if (text.trim().isEmpty) return;

    if (ref.read(chatProvider).needsAd) {
      _showAdGate();
      return;
    }

    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  // ── Rewarded ad gate ──────────────────────────────────────────────────────
  void _showAdGate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdGateSheet(
        onWatchAd: () {
          Navigator.pop(context);
          ref
              .read(adServiceProvider)
              .showRewarded(
                onRewarded: () async {
                  await ref
                      .read(chatProvider.notifier)
                      .unlockQuestionsAfterAd();
                  ref.read(adServiceProvider).preloadRewarded();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🎉 5 more questions unlocked!'),
                        backgroundColor: AppColors.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                onNotAvailable: () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ad not ready, please try again in a moment',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
        },
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('All messages will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).clearChat();
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    final showSuggestions = state.messages.length <= 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BudgetBuddy AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    state.isLoading ? 'Thinking...' : 'Your financial advisor',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // ── Questions left badge ──────────────────────────────────────
            if (!state.needsAd)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.questionsLeft} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            else
              // ── Watch ad badge when exhausted ─────────────────────────
              GestureDetector(
                onTap: _showAdGate,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: 12,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Watch ad',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Error / offline banner ──────────────────────────────────────
          if (state.hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: state.chatError == ChatError.noInternet
                  ? Colors.orange.withOpacity(0.12)
                  : Colors.red.withOpacity(0.10),
              child: Row(
                children: [
                  Icon(
                    state.chatError == ChatError.noInternet
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    size: 14,
                    color: state.chatError == ChatError.noInternet
                        ? Colors.orange
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage ?? 'Something went wrong.',
                      style: TextStyle(
                        fontSize: 12,
                        color: state.chatError == ChatError.noInternet
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  if (!state.isLoading)
                    GestureDetector(
                      onTap: () =>
                          ref.read(chatProvider.notifier).retryLastMessage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Messages ────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  return const TypingIndicator();
                }
                return ChatBubble(message: state.messages[index]);
              },
            ),
          ),

          // ── Suggestion chips ─────────────────────────────────────────────
          if (showSuggestions) ...[
            const SizedBox(height: 8),
            SuggestionChips(onTap: _send),
            const SizedBox(height: 8),
          ],

          // ── Input ────────────────────────────────────────────────────────
          ChatInput(
            controller: _controller,
            isLoading: state.isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Ad gate bottom sheet ──────────────────────────────────────────────────────
class _AdGateSheet extends StatelessWidget {
  final VoidCallback onWatchAd;
  const _AdGateSheet({required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Free questions used up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short ad to unlock 5 more questions.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onWatchAd,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text(
                'Watch Ad — Get 5 Questions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe later',
              style: TextStyle(color: Colors.grey.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
