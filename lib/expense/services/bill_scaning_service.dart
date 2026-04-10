import 'dart:io';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ── Individual line item from a bill ─────────────────────────────────────────
class BillItem {
  final String name;
  final double amount;
  final String currency;
  const BillItem({
    required this.name,
    required this.amount,
    required this.currency,
  });
}

class BillScanResult {
  final List<BillItem> items; // ALL detected line items
  final double? totalAmount; // grand total if found
  final String? merchant;
  final String rawText;
  final String detectedCurrency;

  const BillScanResult({
    required this.items,
    required this.rawText,
    required this.detectedCurrency,
    this.totalAmount,
    this.merchant,
  });

  bool get hasItems => items.isNotEmpty;
}

class BillScannerService {
  static final _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  static final _picker = ImagePicker();

  static Future<BillScanResult?> scan({bool fromCamera = true}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final recognized = await _recognizer.processImage(
      InputImage.fromFile(File(picked.path)),
    );
    final text = recognized.text;

    // Detect currency from bill text
    final detectedCurrency = _detectCurrency(text);

    return BillScanResult(
      items: _parseAllItems(text, detectedCurrency),
      totalAmount: _parseTotal(text),
      merchant: _parseMerchant(text),
      rawText: text,
      detectedCurrency: detectedCurrency,
    );
  }

  // ── Detect currency from bill ─────────────────────────────────────────────
  static String _detectCurrency(String text) {
    final t = text.toLowerCase();
    if (t.contains('\$') || t.contains('usd') || t.contains('dollar'))
      return 'USD';
    if (t.contains('£') || t.contains('gbp') || t.contains('pound'))
      return 'GBP';
    if (t.contains('€') || t.contains('eur') || t.contains('euro'))
      return 'EUR';
    if (t.contains('₹') || t.contains('inr') || t.contains('rupees'))
      return 'INR';
    if (t.contains('npr') || t.contains('rs.') || t.contains('rp'))
      return 'NPR';
    // Default to user's preferred currency
    return ExpenseService.currency;
  }

  // ── Parse ALL line items from bill (name + price pairs) ───────────────────
  static List<BillItem> _parseAllItems(String text, String currency) {
    final items = <BillItem>[];
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 2)
        .toList();

    // Pattern: "Item name ..... 150.00" or "Item name 150"
    final linePattern = RegExp(
      r'^(.{2,40?}?)\s+(?:[\$₹£€]|rs\.?|npr)?\s*([\d,]+\.?\d{0,2})\s*$',
      caseSensitive: false,
    );

    // Alternative: "Item name" on one line, price on next
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip total/subtotal/tax lines for item list (handle separately)
      if (RegExp(
        r'\b(total|subtotal|tax|vat|service|discount|grand)\b',
        caseSensitive: false,
      ).hasMatch(line))
        continue;

      final match = linePattern.firstMatch(line);
      if (match != null) {
        final name = match
            .group(1)!
            .trim()
            .replaceAll(RegExp(r'[.\-]{2,}'), '')
            .trim();
        final raw = match.group(2)!.replaceAll(',', '');
        final amount = double.tryParse(raw);
        if (amount != null &&
            amount > 0 &&
            amount < 100000 &&
            name.length > 1) {
          // Skip if name is purely numeric
          if (!RegExp(r'^\d+$').hasMatch(name)) {
            items.add(
              BillItem(
                name: _capitalize(name),
                amount: amount,
                currency: currency,
              ),
            );
          }
        }
      }
    }

    // Deduplicate
    final seen = <String>{};
    return items
        .where((item) => seen.add('${item.name}_${item.amount}'))
        .toList();
  }

  // ── Parse grand total ─────────────────────────────────────────────────────
  static double? _parseTotal(String text) {
    final patterns = [
      RegExp(
        r'(?:grand\s+total|total\s+amount|net\s+total|total)[:\s]*(?:[\$₹£€]|rs\.?|npr)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'(?:[\$₹£€]|rs\.?)\s*([\d,]+\.?\d{2})\b', caseSensitive: false),
    ];
    for (final p in patterns) {
      final match = p.firstMatch(text);
      if (match != null) {
        final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && val > 0) return val;
      }
    }
    return null;
  }

  // ── Parse merchant name (first substantial non-numeric line) ─────────────
  static String? _parseMerchant(String text) {
    for (final line
        in text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.length > 3)
            .take(6)) {
      if (!RegExp(r'^[\d\s\-/:.#]+$').hasMatch(line) &&
          !RegExp(
            r'\b(tel|phone|vat|gst|invoice|receipt|date|time)\b',
            caseSensitive: false,
          ).hasMatch(line)) {
        return line.length > 40 ? line.substring(0, 40) : line;
      }
    }
    return null;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  static void dispose() => _recognizer.close();
}
