import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:budgetBuddy/features/buddy_chat/models/chat_message.dart';
import 'package:budgetBuddy/features/buddy_chat/services/chat_service.dart';

const _uuid = Uuid();
const _chatKey = 'buddy_chat_history';
const _chatCountKey = 'buddy_chat_question_count';
const _freeQuestions = 2;
const _rewardedQuestions = 5;

enum ChatError { none, noInternet, apiError, timeout }

// ── State ─────────────────────────────────────────────────────────────────────
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ChatError chatError;
  final String? errorMessage;
  final int questionsUsed;
  final int questionsAllowed; // free + rewarded unlocks

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.chatError = ChatError.none,
    this.errorMessage,
    this.questionsUsed = 0,
    this.questionsAllowed = _freeQuestions,
  });

  bool get hasError => chatError != ChatError.none;
  bool get canAsk => questionsUsed < questionsAllowed;
  int get questionsLeft => (questionsAllowed - questionsUsed).clamp(0, 999);
  bool get needsAd => !canAsk;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    ChatError? chatError,
    String? errorMessage,
    int? questionsUsed,
    int? questionsAllowed,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    chatError: chatError ?? ChatError.none,
    errorMessage: errorMessage,
    questionsUsed: questionsUsed ?? this.questionsUsed,
    questionsAllowed: questionsAllowed ?? this.questionsAllowed,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    _init();
  }

  Timer? _retryTimer;

  Future<void> _init() async {
    await _loadFromLocal();
    await _loadQuestionCount();
    _retryPendingIfOnline();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // ── Load question count ───────────────────────────────────────────────────
  Future<void> _loadQuestionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_chatCountKey) ?? 0;
    final allowed = prefs.getInt('${_chatCountKey}_allowed') ?? _freeQuestions;
    state = state.copyWith(questionsUsed: used, questionsAllowed: allowed);
  }

  Future<void> _saveQuestionCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chatCountKey, state.questionsUsed);
    await prefs.setInt('${_chatCountKey}_allowed', state.questionsAllowed);
  }

  // ── Called after rewarded ad is watched ──────────────────────────────────
  Future<void> unlockQuestionsAfterAd() async {
    state = state.copyWith(
      questionsAllowed: state.questionsAllowed + _rewardedQuestions,
    );
    await _saveQuestionCount();
  }

  // ── Load from SharedPreferences ───────────────────────────────────────────
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chatKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => ChatMessage.fromJson(e))
            .toList();
        state = state.copyWith(messages: list);
        return;
      }
    } catch (_) {}
    _addGreeting();
  }

  void _addGreeting() {
    final greeting = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content:
          'Hi! I\'m BudgetBuddy AI 👋\n'
          'I can see your real financial data. Ask me anything like:\n'
          '• "Can I spend \$500 on food this month?"\n'
          '• "How is my budget looking?"\n'
          '• "Where am I overspending?"\n\n'
          'You have $_freeQuestions free questions to start!',
      timestamp: DateTime.now(),
      isSynced: true,
    );
    state = state.copyWith(messages: [greeting]);
    _saveToLocal([greeting]);
  }

  Future<void> _saveToLocal(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chatKey,
        jsonEncode(messages.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'api.openai.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Block if no questions left
    if (state.needsAd) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
      isSynced: false,
    );

    final updated = [...state.messages, userMsg];
    state = state.copyWith(
      messages: updated,
      isLoading: true,
      chatError: ChatError.none,
      questionsUsed: state.questionsUsed + 1, // increment on send
    );
    await _saveToLocal(updated);
    await _saveQuestionCount();

    await _callApi(userMsg, updated);
  }

  Future<void> _callApi(
    ChatMessage userMsg,
    List<ChatMessage> currentMessages,
  ) async {
    final hasNet = await _hasInternet();
    if (!hasNet) {
      state = state.copyWith(
        isLoading: false,
        chatError: ChatError.noInternet,
        errorMessage: 'No internet connection.',
      );
      _scheduleAutoRetry(userMsg);
      return;
    }

    try {
      final reply = await ChatService.sendMessage(
        currentMessages,
      ).timeout(const Duration(seconds: 30));

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
        isSynced: true,
      );

      final synced = currentMessages
          .map((m) => m.id == userMsg.id ? m.copyWith(isSynced: true) : m)
          .toList();

      final finalMessages = [...synced, assistantMsg];
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
        chatError: ChatError.none,
      );
      await _saveToLocal(finalMessages);
      _retryTimer?.cancel();
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        chatError: ChatError.timeout,
        errorMessage: 'Request timed out.',
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        chatError: ChatError.noInternet,
        errorMessage: 'No internet connection.',
      );
      _scheduleAutoRetry(userMsg);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        chatError: ChatError.apiError,
        errorMessage: 'Something went wrong.',
      );
    }
  }

  void _scheduleAutoRetry(ChatMessage userMsg) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      final hasNet = await _hasInternet();
      if (hasNet) {
        _retryTimer?.cancel();
        await retryLastMessage();
      }
    });
  }

  Future<void> _retryPendingIfOnline() async {
    final pending = state.messages
        .where((m) => m.isUser && !m.isSynced)
        .toList();
    if (pending.isEmpty) return;
    final hasNet = await _hasInternet();
    if (!hasNet) return;
    state = state.copyWith(isLoading: true, chatError: ChatError.none);
    await _callApi(pending.last, state.messages);
  }

  Future<void> retryLastMessage() async {
    final pending = state.messages
        .where((m) => m.isUser && !m.isSynced)
        .toList();
    if (pending.isEmpty) return;
    state = state.copyWith(isLoading: true, chatError: ChatError.none);
    await _callApi(pending.last, state.messages);
  }

  Future<void> clearChat() async {
    _retryTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
    // Reset question count on clear
    await prefs.remove(_chatCountKey);
    await prefs.remove('${_chatCountKey}_allowed');
    state = const ChatState();
    _addGreeting();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
