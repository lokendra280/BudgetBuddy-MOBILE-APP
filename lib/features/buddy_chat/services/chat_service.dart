// import 'dart:convert';
// import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:budgetBuddy/features/buddy_chat/models/chat_message.dart';
// import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
// import 'package:budgetBuddy/features/expense/services/expenses_service.dart';

// class ChatService {
//   static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
//   static const String _model = 'gpt-4o-mini';

//   static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

//   // ── Build financial context ───────────────────────────────────────────────
//   static String buildFinancialContext() {
//     try {
//       final budget = AiService.smartBudget();
//       final health = AiService.healthScore();
//       final burn = AiService.burnRate();
//       final pred = AiService.predict();
//       final bills = AiService.billHealthSummary();
//       final goals = AiService.goalInsights();
//       final cash = AiService.cashFlowForecast();
//       final alerts = AiService.alerts();
//       final subs = AiService.detectSubscriptions();

//       final now = DateTime.now();
//       final currency = ExpenseService.budget.currency;
//       final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
//       final daysLeft = daysInMonth - now.day;
//       final remaining =
//           (ExpenseService.budget.monthlyLimit - budget.currentSpend).clamp(
//             0,
//             double.infinity,
//           );
//       final safeDaily = daysLeft > 0 ? remaining / daysLeft : 0.0;

//       // ── Bills ─────────────────────────────────────────────────────────────
//       final allBills = HiveStorage.allBillReminders();
//       final activeBills = allBills.where((b) => b.isActive).toList();
//       final overdueBills = activeBills.where((b) => b.isOverdue).toList();
//       final dueSoonBills = activeBills.where((b) => b.isDueSoon).toList();
//       final recurringBills = activeBills.where((b) => b.isRecurring).toList();
//       final totalBillsMonthly = recurringBills.fold(
//         0.0,
//         (s, b) => s + b.amount,
//       );

//       final billsDetail = recurringBills.isEmpty
//           ? 'None'
//           : recurringBills
//                 .map(
//                   (b) =>
//                       '${b.title}: $currency${b.amount.toStringAsFixed(2)}'
//                       '${b.isOverdue
//                           ? " ⚠️OVERDUE"
//                           : b.isDueSoon
//                           ? " ⏰DUE SOON"
//                           : ""}',
//                 )
//                 .join(', ');

//       // ── EMI / Loans ───────────────────────────────────────────────────────
//       final allLoans = HiveStorage.allEmiLoans();
//       final activeLoans = allLoans.where((l) => l.isActive).toList();
//       final overdueLoans = activeLoans.where((l) => l.isOverdue).toList();
//       final dueSoonLoans = activeLoans.where((l) => l.isDueSoon).toList();
//       final totalMonthlyEmi = activeLoans.fold(0.0, (s, l) => s + l.emiAmount);
//       final totalOutstanding = activeLoans.fold(
//         0.0,
//         (s, l) => s + l.remainingBalance,
//       );

//       final loansDetail = activeLoans.isEmpty
//           ? 'None'
//           : activeLoans
//                 .map(
//                   (l) =>
//                       '${l.lenderName}: EMI $currency${l.emiAmount.toStringAsFixed(2)}/mo, '
//                       'outstanding $currency${l.remainingBalance.toStringAsFixed(2)}'
//                       '${l.isOverdue
//                           ? " ⚠️OVERDUE"
//                           : l.isDueSoon
//                           ? " ⏰DUE SOON"
//                           : ""}',
//                 )
//                 .join(' | ');

//       // ── Total fixed obligations ───────────────────────────────────────────
//       final totalFixed = totalBillsMonthly + totalMonthlyEmi;
//       final disposable = (budget.income - totalFixed).clamp(0, double.infinity);

//       // ── Goals ─────────────────────────────────────────────────────────────
//       final goalsSummary = goals.isEmpty
//           ? 'No active goals'
//           : goals
//                 .map(
//                   (g) =>
//                       '${g.emoji} ${g.name}: ${(g.progress * 100).toInt()}% done, '
//                       '${g.daysLeft}d left, ${g.onTrack ? "on track" : "at risk"}',
//                 )
//                 .join(' | ');

//       // ── Subscriptions ─────────────────────────────────────────────────────
//       final subsSummary = subs.isEmpty
//           ? 'None'
//           : subs
//                 .map(
//                   (s) =>
//                       '${s.name}: $currency${s.monthlyEquivalent.toStringAsFixed(0)}/mo',
//                 )
//                 .join(', ');

//       // ── Alerts ────────────────────────────────────────────────────────────
//       final alertsSummary = alerts.isEmpty
//           ? 'None'
//           : alerts.map((a) => '${a.emoji} ${a.title}').join(' | ');

//       return '''
// === BUDGETBUDDY USER FINANCIAL DATA ===
// Date: ${now.day}/${now.month}/${now.year} | Days left: $daysLeft | Currency: $currency

// BUDGET:
// - Monthly limit: $currency${ExpenseService.budget.monthlyLimit.toStringAsFixed(2)}
// - Income this month: $currency${budget.income.toStringAsFixed(2)}
// - Spent so far: $currency${budget.currentSpend.toStringAsFixed(2)}
// - Remaining budget: $currency${remaining.toStringAsFixed(2)}
// - Safe to spend: $currency${safeDaily.toStringAsFixed(2)}/day
// - Total fixed obligations (bills + EMIs): $currency${totalFixed.toStringAsFixed(2)}/mo
// - Disposable income after fixed: $currency${disposable.toStringAsFixed(2)}/mo

// HEALTH: ${health.score}/100 (${health.grade}) — ${health.headline}

// BURN RATE:
// - Daily spend rate: $currency${burn.dailySpend.toStringAsFixed(2)}/day
// - Projected monthly: $currency${burn.monthlySpend.toStringAsFixed(2)}
// - Runway: ${burn.runwayDays} days

// NEXT MONTH FORECAST:
// - Projected income: $currency${pred.nextMonthIncome.toStringAsFixed(2)}
// - Projected expenses: $currency${pred.nextMonthExpense.toStringAsFixed(2)}
// - Projected balance: $currency${pred.futureBalance.toStringAsFixed(2)}

// BILLS (recurring monthly):
// - Total: $currency${totalBillsMonthly.toStringAsFixed(2)}/mo
// - Active: ${activeBills.length} | Overdue: ${overdueBills.length} | Due soon: ${dueSoonBills.length}
// - Detail: $billsDetail

// EMI & LOANS:
// - Total monthly EMI: $currency${totalMonthlyEmi.toStringAsFixed(2)}/mo
// - Total outstanding: $currency${totalOutstanding.toStringAsFixed(2)}
// - Active loans: ${activeLoans.length} | Overdue: ${overdueLoans.length} | Due soon: ${dueSoonLoans.length}
// - Detail: $loansDetail

// GOALS: $goalsSummary

// SUBSCRIPTIONS: $subsSummary

// ALERTS: $alertsSummary

// CASH FLOW WARNINGS: ${cash.warnings.isEmpty ? 'None' : cash.warnings.join(' | ')}
// =======================================''';
//     } catch (e) {
//       return 'Financial data unavailable.';
//     }
//   }

//   static String get _systemPrompt => '''
// You are BudgetBuddy AI, a friendly and honest personal finance assistant built into the BudgetBuddy app.
// You have access to the user's REAL financial data including expenses, bills, EMI loans, goals and subscriptions.

// Rules:
// - For spending questions ("can I spend X on Y?"), check remaining budget, safe daily spend AND fixed obligations (bills + EMIs), then answer YES ✅ or NO ❌ + short reason
// - For loan/EMI questions, use the actual outstanding balance and monthly EMI from the data
// - For bill questions, check overdue and due soon status and remind urgently if overdue
// - Keep responses under 120 words unless a detailed breakdown is requested
// - Use the user's actual currency and numbers — never generic advice
// - Be warm, encouraging, and honest
// - If data is missing, say so and suggest logging expenses

// ${buildFinancialContext()}''';

//   // ── Send message to OpenAI ────────────────────────────────────────────────
//   static Future<String> sendMessage(List<ChatMessage> history) async {
//     if (_apiKey.isEmpty) throw Exception('OPENAI_API_KEY not set in .env');

//     final messages = [
//       {'role': 'system', 'content': _systemPrompt},
//       ...history.map((m) => m.toApiMap()),
//     ];

//     final response = await http
//         .post(
//           Uri.parse(_baseUrl),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $_apiKey',
//           },
//           body: jsonEncode({
//             'model': _model,
//             'messages': messages,
//             'max_completion_tokens': 500,
//             'temperature': 0.7,
//           }),
//         )
//         .timeout(const Duration(seconds: 30));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['choices'][0]['message']['content'] as String;
//     } else if (response.statusCode == 401) {
//       throw Exception('Invalid OpenAI API key — check your .env file.');
//     } else if (response.statusCode == 429) {
//       throw Exception('OpenAI rate limit reached — try again in a moment.');
//     } else {
//       throw Exception('OpenAI error ${response.statusCode}');
//     }
//   }
// }

import 'dart:convert';
import 'package:budgetBuddy/common/hive_storages/hive_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:budgetBuddy/features/buddy_chat/models/chat_message.dart';
import 'package:budgetBuddy/features/ai_screen/services/ai_services.dart';
import 'package:budgetBuddy/features/expense/services/expenses_service.dart';

class ChatService {
  static const String _model = 'gemini-flash-latest';
  static String get _baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String? _cachedContext;
  static DateTime? _contextBuiltAt;

  // ── Build financial context ───────────────────────────────────────────────
  static String buildFinancialContext() {
    try {
      final budget = AiService.smartBudget();
      final health = AiService.healthScore();
      final burn = AiService.burnRate();
      final pred = AiService.predict();
      final bills = AiService.billHealthSummary();
      final goals = AiService.goalInsights();
      final cash = AiService.cashFlowForecast();
      final alerts = AiService.alerts();
      final subs = AiService.detectSubscriptions();

      final now = DateTime.now();
      final currency = ExpenseService.budget.currency;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysLeft = daysInMonth - now.day;
      final remaining =
          (ExpenseService.budget.monthlyLimit - budget.currentSpend).clamp(
            0,
            double.infinity,
          );
      final safeDaily = daysLeft > 0 ? remaining / daysLeft : 0.0;

      // ── Bills ─────────────────────────────────────────────────────────────
      final allBills = HiveStorage.allBillReminders();
      final activeBills = allBills.where((b) => b.isActive).toList();
      final overdueBills = activeBills.where((b) => b.isOverdue).toList();
      final dueSoonBills = activeBills.where((b) => b.isDueSoon).toList();
      final recurringBills = activeBills.where((b) => b.isRecurring).toList();
      final totalBillsMonthly = recurringBills.fold(
        0.0,
        (s, b) => s + b.amount,
      );

      final billsDetail = recurringBills.isEmpty
          ? 'None'
          : recurringBills
                .map(
                  (b) =>
                      '${b.title}: $currency${b.amount.toStringAsFixed(2)}'
                      '${b.isOverdue
                          ? " ⚠️OVERDUE"
                          : b.isDueSoon
                          ? " ⏰DUE SOON"
                          : ""}',
                )
                .join(', ');

      // ── EMI / Loans ───────────────────────────────────────────────────────
      final allLoans = HiveStorage.allEmiLoans();
      final activeLoans = allLoans.where((l) => l.isActive).toList();
      final overdueLoans = activeLoans.where((l) => l.isOverdue).toList();
      final dueSoonLoans = activeLoans.where((l) => l.isDueSoon).toList();
      final totalMonthlyEmi = activeLoans.fold(0.0, (s, l) => s + l.emiAmount);
      final totalOutstanding = activeLoans.fold(
        0.0,
        (s, l) => s + l.remainingBalance,
      );

      final loansDetail = activeLoans.isEmpty
          ? 'None'
          : activeLoans
                .map(
                  (l) =>
                      '${l.lenderName}: EMI $currency${l.emiAmount.toStringAsFixed(2)}/mo, '
                      'outstanding $currency${l.remainingBalance.toStringAsFixed(2)}'
                      '${l.isOverdue
                          ? " ⚠️OVERDUE"
                          : l.isDueSoon
                          ? " ⏰DUE SOON"
                          : ""}',
                )
                .join(' | ');

      // ── Total fixed obligations ───────────────────────────────────────────
      final totalFixed = totalBillsMonthly + totalMonthlyEmi;
      final disposable = (budget.income - totalFixed).clamp(0, double.infinity);

      // ── Goals ─────────────────────────────────────────────────────────────
      final goalsSummary = goals.isEmpty
          ? 'No active goals'
          : goals
                .map(
                  (g) =>
                      '${g.emoji} ${g.name}: ${(g.progress * 100).toInt()}% done, '
                      '${g.daysLeft}d left, ${g.onTrack ? "on track" : "at risk"}',
                )
                .join(' | ');

      // ── Subscriptions ─────────────────────────────────────────────────────
      final subsSummary = subs.isEmpty
          ? 'None'
          : subs
                .map(
                  (s) =>
                      '${s.name}: $currency${s.monthlyEquivalent.toStringAsFixed(0)}/mo',
                )
                .join(', ');

      // ── Alerts ────────────────────────────────────────────────────────────
      final alertsSummary = alerts.isEmpty
          ? 'None'
          : alerts.map((a) => '${a.emoji} ${a.title}').join(' | ');

      return '''
=== BUDGETBUDDY USER FINANCIAL DATA ===
Date: ${now.day}/${now.month}/${now.year} | Days left: $daysLeft | Currency: $currency

BUDGET:
- Monthly limit: $currency${ExpenseService.budget.monthlyLimit.toStringAsFixed(2)}
- Income this month: $currency${budget.income.toStringAsFixed(2)}
- Spent so far: $currency${budget.currentSpend.toStringAsFixed(2)}
- Remaining budget: $currency${remaining.toStringAsFixed(2)}
- Safe to spend: $currency${safeDaily.toStringAsFixed(2)}/day
- Total fixed obligations (bills + EMIs): $currency${totalFixed.toStringAsFixed(2)}/mo
- Disposable income after fixed: $currency${disposable.toStringAsFixed(2)}/mo

HEALTH: ${health.score}/100 (${health.grade}) — ${health.headline}

BURN RATE:
- Daily spend rate: $currency${burn.dailySpend.toStringAsFixed(2)}/day
- Projected monthly: $currency${burn.monthlySpend.toStringAsFixed(2)}
- Runway: ${burn.runwayDays} days

NEXT MONTH FORECAST:
- Projected income: $currency${pred.nextMonthIncome.toStringAsFixed(2)}
- Projected expenses: $currency${pred.nextMonthExpense.toStringAsFixed(2)}
- Projected balance: $currency${pred.futureBalance.toStringAsFixed(2)}

BILLS (recurring monthly):
- Total: $currency${totalBillsMonthly.toStringAsFixed(2)}/mo
- Active: ${activeBills.length} | Overdue: ${overdueBills.length} | Due soon: ${dueSoonBills.length}
- Detail: $billsDetail

EMI & LOANS:
- Total monthly EMI: $currency${totalMonthlyEmi.toStringAsFixed(2)}/mo
- Total outstanding: $currency${totalOutstanding.toStringAsFixed(2)}
- Active loans: ${activeLoans.length} | Overdue: ${overdueLoans.length} | Due soon: ${dueSoonLoans.length}
- Detail: $loansDetail

GOALS: $goalsSummary

SUBSCRIPTIONS: $subsSummary

ALERTS: $alertsSummary

CASH FLOW WARNINGS: ${cash.warnings.isEmpty ? 'None' : cash.warnings.join(' | ')}
=======================================''';
    } catch (e) {
      return 'Financial data unavailable.';
    }
  }

  // Add cache at the top of ChatService

  static String _getFinancialContext() {
    final now = DateTime.now();
    // Rebuild context at most once every 5 minutes
    if (_cachedContext == null ||
        _contextBuiltAt == null ||
        now.difference(_contextBuiltAt!).inMinutes >= 5) {
      _cachedContext = buildFinancialContext();
      _contextBuiltAt = now;
      debugPrint('[ChatService] Financial context rebuilt');
    }
    return _cachedContext!;
  }

  // Update _systemPrompt to use cached context
  //   static String get _systemPrompt => '''
  // You are BudgetBuddy AI, a friendly and honest personal finance assistant built into the BudgetBuddy app.
  // You have access to the user's REAL financial data including expenses, bills, EMI loans, goals and subscriptions.

  // Rules:
  // - For spending questions ("can I spend X on Y?"), check remaining budget, safe daily spend AND fixed obligations (bills + EMIs), then answer YES ✅ or NO ❌ + short reason
  // - For loan/EMI questions, use the actual outstanding balance and monthly EMI from the data
  // - For bill questions, check overdue and due soon status and remind urgently if overdue
  // - Keep responses under 120 words unless a detailed breakdown is requested
  // - Use the user's actual currency and numbers — never generic advice
  // - Be warm, encouraging, and honest
  // - If data is missing, say so and suggest logging expenses

  // ${_getFinancialContext()}''';
  static String get _systemPrompt => '''
You are BudgetBuddy AI, a personal finance assistant.

Rules:
- Use only the user's financial data provided.
- Never make up numbers or transactions.
- For spending questions, check budget, bills, and EMI before answering.
- Answer YES ✅ or NO ❌ with a short reason when asked if they can afford something.
- Use actual currency and values from the data.
- For overdue bills or loans, warn the user clearly.
- Give practical, friendly, and concise advice.
- If data is missing, ask the user to add financial information.
- Keep answers under 120 words.
''';
  // Call this when user logs new expenses to invalidate cache
  static void invalidateContext() {
    _cachedContext = null;
    _contextBuiltAt = null;
  }

  // ── Send message to Gemini ────────────────────────────────────────────────
  // Replace the sendMessage method with this:
  static Future<String> sendMessage(List<ChatMessage> history) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not set in .env');
    }

    final trimmed = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await _doRequest(trimmed);
      } on _RateLimitException {
        attempt++;

        if (attempt >= maxRetries) {
          throw Exception(
            'Gemini is busy right now. Please wait a moment and try again.',
          );
        }

        final delay = Duration(seconds: 2 << attempt);
        debugPrint(
          '[ChatService] Rate limited — retrying in ${delay.inSeconds}s',
        );
        debugPrint('History messages: ${trimmed.length}');
        debugPrint('System prompt length: ${_systemPrompt.length}');
        await Future.delayed(delay);
      }
    }

    throw Exception('Failed after $maxRetries attempts.');
  }

  static Future<String> _doRequest(List<ChatMessage> history) async {
    final contents = history
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.content},
            ],
          },
        )
        .toList();

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': _systemPrompt},
              ],
            },
            'contents': contents,
            'generationConfig': {'maxOutputTokens': 500, 'temperature': 0.7},
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned no response — try again.');
      }

      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      return parts.first['text'] as String;
    } else if (response.statusCode == 429) {
      throw _RateLimitException();
    } else if (response.statusCode == 400) {
      throw Exception('Invalid request — check your Gemini API key/config.');
    } else if (response.statusCode == 403) {
      throw Exception('Invalid Gemini API key — check your .env file.');
    } else {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }
  }
}

class _RateLimitException implements Exception {}
