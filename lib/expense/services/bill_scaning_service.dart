import 'dart:io';
import 'package:expensetracker/expense/services/expenses_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

class BillScannerService {
  static final _picker = ImagePicker();

  static Future<BillScanResult?> scan({bool fromCamera = true}) async {
    // Pick image — handle permissions & cancellation
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 1920,
        maxHeight: 2560,
      );
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('permission') || err.contains('denied')) {
        throw const BillScanException(
          'Camera permission denied. Go to Settings → Apps → SpendSense → Permissions and allow Camera.',
        );
      }
      throw BillScanException(
        'Could not open ${fromCamera ? "camera" : "gallery"}. Please try again.',
      );
    }

    if (picked == null) return null; // user cancelled — no error

    final file = File(picked.path);
    if (!await file.exists()) {
      throw const BillScanException(
        'Image not found. Please try taking the photo again.',
      );
    }
    if (await file.length() < 1000) {
      throw const BillScanException(
        'Image too small or corrupted. Please retake the photo.',
      );
    }

    // Run OCR
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFile(file),
      );
      final text = recognized.text.trim();

      if (text.isEmpty) {
        throw const BillScanException(
          'No text detected in this image.\n\n'
          'Tips:\n• Make sure the bill is well-lit\n'
          '• Hold the camera steady\n• Avoid shadows on the bill',
        );
      }

      final currency = _detectCurrency(text);
      return BillScanResult(
        items: _parseItems(text, currency),
        totalAmount: _parseTotal(text),
        merchant: _parseMerchant(text),
        detectedCurrency: currency,
      );
    } finally {
      recognizer.close();
    }
  }

  static String _detectCurrency(String text) {
    final t = text.toLowerCase();
    if (t.contains('\$') || t.contains('usd') || t.contains('dollar'))
      return 'USD';
    if (t.contains('£') || t.contains('gbp') || t.contains('pound'))
      return 'GBP';
    if (t.contains('€') || t.contains('eur') || t.contains('euro'))
      return 'EUR';
    if (t.contains('₹') || t.contains('inr')) return 'INR';
    if (t.contains('npr') ||
        t.contains('rs.') ||
        t.contains('nrs') ||
        t.contains('रु'))
      return 'NPR';
    return ExpenseService.currency;
  }

  static List<BillItem> _parseItems(String text, String currency) {
    final items = <BillItem>[];
    final seen = <String>{};

    // Lines to skip (totals, metadata)
    final skipRx = RegExp(
      r'\b(total|subtotal|sub.total|grand|tax|vat|gst|service|discount|'
      r'tip|gratuity|change|cash|card|paid|balance|receipt|invoice|'
      r'table|order|server|cashier|tel|phone|thank|welcome|page)\b',
      caseSensitive: false,
    );

    // Receipt item patterns (most common → least common)
    final patterns = [
      RegExp(
        r'^(?:\d+\s*[xX×]\s*)?(.{2,40}?)\s{2,}(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d{0,2})\s*$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:\d+\s*[xX×]\s*)?(.{2,40}?)\.{2,}\s*(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d{0,2})\s*$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:\d+\s*[xX×]\s*)?(.{2,40}?)\t+(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d{0,2})\s*$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:\d+\s*[xX×]\s*)?(.{2,40}?)\s*[-:]\s*(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d{0,2})\s*$',
        caseSensitive: false,
      ),
    ];

    for (final line
        in text.split('\n').map((l) => l.trim()).where((l) => l.length > 3)) {
      if (skipRx.hasMatch(line)) continue;
      if (RegExp(r'^[\d\s\-/.:()+*=]+$').hasMatch(line)) continue;

      for (final pat in patterns) {
        final m = pat.firstMatch(line);
        if (m == null) continue;

        final rawName = m
            .group(1)!
            .trim()
            .replaceAll(RegExp(r'[-_.]{2,}'), '')
            .trim();
        final rawAmt = m.group(2)!.replaceAll(',', '');
        final amount = double.tryParse(rawAmt);

        if (amount == null || amount <= 0 || amount > 999999) continue;
        if (rawName.length < 2) continue;
        if (RegExp(r'^\d+$').hasMatch(rawName)) continue;
        if (!RegExp(r'[a-zA-Z\u0900-\u097F]').hasMatch(rawName)) continue;

        final name = _tc(rawName);
        final key = '${name.toLowerCase()}_${amount.toStringAsFixed(2)}';
        if (!seen.add(key)) continue;

        items.add(BillItem(name: name, amount: amount, currency: currency));
        break;
      }
    }
    return items;
  }

  static double? _parseTotal(String text) {
    final ps = [
      RegExp(
        r'(?:grand\s*total|total\s*amount|net\s*total|amount\s*due|net\s*payable)[:\s]*(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'\btotal\b[:\s]*(?:[\$₹£€]|rs\.?|npr|nrs)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];
    double? best;
    for (final p in ps) {
      for (final m in p.allMatches(text)) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && v > 0 && (best == null || v > best)) best = v;
      }
      if (best != null) return best;
    }
    return best;
  }

  static String? _parseMerchant(String text) {
    final skip = RegExp(
      r'(receipt|invoice|bill|tax|vat|date|time|tel|phone|page|\d{2}[/-]\d{2})',
      caseSensitive: false,
    );
    for (final l
        in text
            .split('\n')
            .map((x) => x.trim())
            .where((x) => x.length > 3)
            .take(8)) {
      if (skip.hasMatch(l)) continue;
      if (RegExp(r'^[\d\s\-/:.#()]+$').hasMatch(l)) continue;
      if (!RegExp(r'[a-zA-Z]').hasMatch(l)) continue;
      return l.length > 45 ? l.substring(0, 45) : l;
    }
    return null;
  }

  static String _tc(String s) => s
      .split(' ')
      .map(
        (w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
}
