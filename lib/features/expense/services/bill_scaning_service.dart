// lib/expense/services/bill_scaning_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:budgetBuddy/features/expense/services/expenses_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_recognition/receipt_recognition.dart';
import 'package:http/http.dart' as http;

import 'gemini_receipt_service.dart';

class BillItem {
  final String name, currency;
  final double amount;

  BillItem({required this.name, required this.amount, required this.currency});
}

class BillScanResult {
  final List<BillItem> items;
  final double? totalAmount;
  final String? merchant, detectedCurrency;

  const BillScanResult({
    required this.items,
    this.totalAmount,
    this.merchant,
    this.detectedCurrency,
  });

  bool get hasItems => items.isNotEmpty;
}

class BillScanException implements Exception {
  final String message;
  const BillScanException(this.message);

  @override
  String toString() => message;
}

// lib/expense/services/gemini_bill_scan_service.dart
//
// Replaces the OCR step in bill_scaning_service.dart with a Gemini vision
// call. Reuses BillItem / BillScanResult / BillScanException from that
// file rather than redefining them — same shape is returned either way,
// so anything downstream (review screen, ExpenseProvider) doesn't care
// which scanner produced the result.
//
// Add to pubspec.yaml:
//   dependencies:
//     http: ^1.2.0   # you likely already have this; confirm version
//
// Uses generateContent with responseSchema (structured output) so Gemini
// returns parseable JSON directly — no regex-scraping of prose like the
// ML Kit path needed.

class GeminiBillScanService {
  static final _picker = ImagePicker();

  // Check https://ai.google.dev/gemini-api/docs/models for the current
  // recommended flash model — Google deprecates these on a roughly
  // 6-month cycle (gemini-2.0-flash was shut down June 2026).
  static const _model = 'gemini-3.5-flash';

  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw const BillScanException(
        'Gemini API key not configured. Add GEMINI_API_KEY to .env.',
      );
    }
    return key;
  }

  /// Picks an image (camera or gallery) and returns it without scanning —
  /// the caller uses this to show the scanning animation over the actual
  /// captured photo before/while the Gemini call resolves.
  static Future<File?> pickImage({bool fromCamera = true}) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (e) {
      throw BillScanException(
        'Could not open ${fromCamera ? "camera" : "gallery"}.',
      );
    }

    if (picked == null) return null;

    final file = File(picked.path);
    if (!await file.exists() || await file.length() < 1000) {
      throw const BillScanException(
        'Image not found or too small. Please retake photo.',
      );
    }
    return file;
  }

  /// Sends the already-picked image to Gemini and parses the structured
  /// result. Split from pickImage() so the UI can start the scanning
  /// animation immediately after the photo is taken, rather than after
  /// the (slower) network call also completes.
  static Future<BillScanResult> scanImage(File file) async {
    debugPrint('🟢 [GeminiBillScanner] Encoding image...');
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'
      '?key=$_apiKey',
    );

    final body = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'You are reading a photo of a purchase receipt or bill. '
                  'Extract every line item with its name and price, the '
                  'total amount, the merchant/store name if visible, and '
                  'the currency (ISO code like USD, EUR, GBP, INR, NPR — '
                  'infer from symbols or context, default to NPR if '
                  'unclear). Ignore card approval codes, subtotals, tax '
                  'lines, and payment method text as line items — only '
                  'real purchased items belong in "items". If a field '
                  'genuinely cannot be read, omit it rather than guessing.',
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'merchant': {'type': 'STRING'},
            'currency': {'type': 'STRING'},
            'total': {'type': 'NUMBER'},
            'items': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'name': {'type': 'STRING'},
                  'amount': {'type': 'NUMBER'},
                },
                'required': ['name', 'amount'],
              },
            },
          },
          'required': ['items'],
        },
      },
    };

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('❌ [GeminiBillScanner] Network error: $e');
      throw const BillScanException(
        'Could not reach the scanning service. Check your connection.',
      );
    }

    if (response.statusCode != 200) {
      debugPrint(
        '❌ [GeminiBillScanner] HTTP ${response.statusCode}: ${response.body}',
      );
      throw BillScanException(
        'Scan failed (${response.statusCode}). Please try again.',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw const BillScanException('Could not read scan response.');
    }

    String? rawJsonText;
    try {
      rawJsonText =
          decoded['candidates']?[0]['content']['parts'][0]['text'] as String?;
    } catch (e) {
      rawJsonText = null;
    }

    if (rawJsonText == null || rawJsonText.isEmpty) {
      debugPrint('❌ [GeminiBillScanner] No candidate text in response');
      throw const BillScanException(
        'No readable data found. Try a clearer photo.',
      );
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(rawJsonText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [GeminiBillScanner] JSON parse failed: $e');
      throw const BillScanException('Could not parse scan result.');
    }

    final currency = (parsed['currency'] as String?)?.trim().isNotEmpty == true
        ? parsed['currency'] as String
        : ExpenseService.currency;

    final rawItems = (parsed['items'] as List?) ?? const [];
    final items = <BillItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      final amount = (raw['amount'] as num?)?.toDouble();
      if (name.isEmpty || amount == null || amount <= 0 || amount > 999999) {
        continue;
      }
      items.add(BillItem(name: name, amount: amount, currency: currency));
    }

    final total = (parsed['total'] as num?)?.toDouble();
    final merchant = (parsed['merchant'] as String?)?.trim();

    debugPrint('✅ [GeminiBillScanner] Items: ${items.length}, total: $total');

    if (items.isEmpty && total == null) {
      throw const BillScanException('No items detected. Try better lighting.');
    }

    return BillScanResult(
      items: items,
      totalAmount: total,
      merchant: (merchant?.isNotEmpty ?? false) ? merchant : null,
      detectedCurrency: currency,
    );
  }
}
