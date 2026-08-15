// lib/expense/services/gemini_receipt_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'bill_scaning_service.dart';

/// Parses the raw OCR text of a receipt into structured [BillScanResult]
/// data using Gemini. Used as the "further work" step after ML Kit has
/// already extracted the raw text — this does NOT touch the image, only
/// the text, so it's cheap and works even when [ReceiptRecognizer]'s own
/// layout-based parser can't make sense of a receipt.
class GeminiReceiptParser {
  GeminiReceiptParser._();

  static const _model = 'gemini-flash-latest';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Reads GEMINI_API_KEY from the .env file loaded via flutter_dotenv.
  /// Throws [BillScanException] with a clear message if it's missing, so
  /// the caller can surface something actionable instead of a raw 401.
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.trim().isEmpty) {
      throw const BillScanException(
        'Gemini API key not configured. Add GEMINI_API_KEY to your .env file.',
      );
    }
    return key.trim();
  }

  /// Sends [rawText] (the raw OCR dump from the receipt photo) to Gemini
  /// and asks it to return structured JSON, which is then mapped into a
  /// [BillScanResult]. [fallbackCurrency] is used when Gemini can't find a
  /// currency marker in the text.
  static Future<BillScanResult> parseReceiptText(
    String rawText, {
    required String fallbackCurrency,
  }) async {
    if (rawText.trim().isEmpty) {
      throw const BillScanException('No text to send to Gemini.');
    }

    debugPrint('🤖 [Gemini] Parsing ${rawText.length} chars of OCR text...');

    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _buildPrompt(rawText)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
      },
    });

    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      debugPrint('❌ [Gemini] Network error: $e');
      throw const BillScanException(
        'Could not reach Gemini. Check your internet connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      debugPrint('❌ [Gemini] HTTP ${response.statusCode}: ${response.body}');
      throw BillScanException(
        response.statusCode == 400 || response.statusCode == 403
            ? 'Gemini rejected the request. Check that GEMINI_API_KEY is valid.'
            : 'Gemini request failed (${response.statusCode}). Try again.',
      );
    }

    final text = _extractText(response.body);
    if (text == null || text.trim().isEmpty) {
      debugPrint('❌ [Gemini] Empty response body: ${response.body}');
      throw const BillScanException(
        'Gemini returned no data for this receipt. Try a clearer photo.',
      );
    }

    debugPrint('🤖 [Gemini] Raw model output: $text');

    final parsed = _parseJsonLoosely(text);
    if (parsed == null) {
      throw const BillScanException(
        "Couldn't understand Gemini's response. Try again.",
      );
    }

    return _mapToResult(parsed, fallbackCurrency: fallbackCurrency);
  }

  static String _buildPrompt(String rawText) {
    return '''
You are a receipt-parsing engine. Given the raw OCR text below from a
photographed receipt, extract structured data.

Respond with ONLY valid JSON — no markdown fences, no commentary — matching
exactly this shape:
{
  "merchant": string or null,
  "currency": one of "USD","EUR","GBP","INR","NPR" or null,
  "total": number or null,
  "items": [ { "name": string, "amount": number } ]
}

Rules:
- "amount" is each line item's own price (its line total, not a unit price
  if quantity and unit price are both printed separately).
- Skip lines that are not purchasable items: subtotal, tax, tip, change,
  card/payment details, loyalty numbers, barcodes, disclaimers.
- If you cannot confidently identify a grand total, set "total" to null
  rather than guessing.
- Only set "currency" if a symbol or code is clearly present in the text;
  otherwise null.
- If nothing usable is found, return {"merchant": null, "currency": null,
  "total": null, "items": []}.

OCR TEXT:
"""
$rawText
"""
''';
  }

  /// Pulls the text out of Gemini's response envelope
  /// (candidates[0].content.parts[0].text).
  static String? _extractText(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      return parts.first['text'] as String?;
    } catch (e) {
      debugPrint('❌ [Gemini] Failed to unwrap response envelope: $e');
      return null;
    }
  }

  /// Gemini is asked to return raw JSON, but strips fenced code blocks
  /// defensively in case a model still wraps it in ```json ... ```.
  static Map<String, dynamic>? _parseJsonLoosely(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'```\s*$'), '')
          .trim();
    }

    try {
      final decoded = jsonDecode(cleaned);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('❌ [Gemini] JSON decode failed: $e');
      return null;
    }
  }

  static BillScanResult _mapToResult(
    Map<String, dynamic> json, {
    required String fallbackCurrency,
  }) {
    final currency = (json['currency'] as String?)?.trim();
    final resolvedCurrency = (currency == null || currency.isEmpty)
        ? fallbackCurrency
        : currency;

    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = <BillItem>[];

    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      final amount = _asDouble(raw['amount']);
      if (name.isEmpty || amount == null || amount <= 0 || amount > 99999) {
        continue;
      }
      items.add(
        BillItem(name: name, amount: amount, currency: resolvedCurrency),
      );
    }

    final total = _asDouble(json['total']);
    final merchant = (json['merchant'] as String?)?.trim();

    if (items.isEmpty && total == null) {
      throw const BillScanException(
        'Gemini could not find any items or a total on this receipt.',
      );
    }

    return BillScanResult(
      items: items,
      totalAmount: total,
      merchant: (merchant == null || merchant.isEmpty) ? null : merchant,
      detectedCurrency: resolvedCurrency,
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }
}
