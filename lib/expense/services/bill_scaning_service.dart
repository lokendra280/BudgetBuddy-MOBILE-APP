// // lib/expense/services/bill_scaning_service.dart
// import 'dart:io';
// import 'package:expensetracker/expense/services/expenses_service.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:receipt_recognition/receipt_recognition.dart';

// class BillItem {
//   final String name, currency;
//   final double amount;

//   BillItem({required this.name, required this.amount, required this.currency});
// }

// class BillScanResult {
//   final List<BillItem> items;
//   final double? totalAmount;
//   final String? merchant, detectedCurrency;

//   const BillScanResult({
//     required this.items,
//     this.totalAmount,
//     this.merchant,
//     this.detectedCurrency,
//   });

//   bool get hasItems => items.isNotEmpty;
// }

// class BillScanException implements Exception {
//   final String message;
//   const BillScanException(this.message);

//   @override
//   String toString() => message;
// }

// class BillScannerService {
//   static final _picker = ImagePicker();

//   static Future<BillScanResult?> scan({bool fromCamera = true}) async {
//     debugPrint("🟢 [BillScanner] START scan");

//     XFile? picked;

//     try {
//       picked = await _picker.pickImage(
//         source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//         imageQuality: 92,
//         maxWidth: 1920,
//         maxHeight: 2560,
//       );

//       debugPrint("📸 [BillScanner] Image picked: ${picked?.path}");
//     } catch (e) {
//       debugPrint("❌ [BillScanner] Picker error: $e");

//       throw BillScanException(
//         'Could not open ${fromCamera ? "camera" : "gallery"}.',
//       );
//     }

//     if (picked == null) {
//       debugPrint("⚠️ [BillScanner] User cancelled");
//       return null;
//     }

//     final file = File(picked.path);

//     if (!await file.exists() || await file.length() < 1000) {
//       debugPrint("❌ [BillScanner] Invalid image file");
//       throw const BillScanException(
//         'Image not found or too small. Please retake photo.',
//       );
//     }

//     debugPrint("📂 [BillScanner] File OK: ${file.path}");

//     final inputImage = InputImage.fromFilePath(file.path);

//     final options = ReceiptOptions.fromLayeredJson({
//       'extend': {
//         'totalLabels': {
//           'TOTAL': 'Total',
//           'GRAND TOTAL': 'Total',
//           'AMOUNT DUE': 'Total',
//         },
//         'ignoreKeywords': ['APPROVED', 'VISA', 'MASTERCARD', 'INVOICE'],
//       },
//       'override': {
//         'stopKeywords': [
//           'TOTAL',
//           'SUBTOTAL',
//           'TAX',
//           'GST',
//           'VAT',
//           'CASH',
//           'CARD',
//         ],
//       },
//       'tuning': {
//         'optimizerConfidenceThreshold': 30,
//         'optimizerStabilityThreshold': 20,
//       },
//     });

//     ReceiptRecognizer? recognizer;
//     dynamic snapshot;

//     try {
//       recognizer = ReceiptRecognizer(options: options);

//       debugPrint("🧠 [BillScanner] Running OCR...");

//       snapshot = await recognizer.processImage(inputImage);

//       debugPrint("✅ [BillScanner] OCR completed");
//       debugPrint("📊 Valid: ${snapshot.isValid}");
//       debugPrint("📊 Confirmed: ${snapshot.isConfirmed}");

//       final receipt = snapshot is RecognizedReceipt
//           ? snapshot
//           : snapshot.receiptData ?? snapshot;

//       if (receipt == null) {
//         debugPrint("❌ [BillScanner] Receipt is NULL");
//         throw const BillScanException(
//           "Receipt recognition failed. Try clearer image.",
//         );
//       }

//       debugPrint("🏪 Store: ${receipt.store?.value}");
//       debugPrint("💰 Total: ${receipt.total?.formattedValue}");
//       debugPrint("📦 Positions: ${receipt.positions.length}");

//       final currency = _detectCurrency(receipt);
//       final items = _mapItems(receipt.positions, currency);
//       final total = _parseTotal(receipt.total?.formattedValue);
//       final merchant = receipt.store?.value?.toString().trim();

//       debugPrint("💵 Parsed Items: ${items.length}");
//       debugPrint("💰 Parsed Total: $total");
//       debugPrint("🏪 Merchant: $merchant");

//       if (items.isEmpty && total == null) {
//         throw const BillScanException(
//           'No items detected. Try better lighting.',
//         );
//       }

//       return BillScanResult(
//         items: items,
//         totalAmount: total,
//         merchant: merchant,
//         detectedCurrency: currency,
//       );
//     } catch (e) {
//       debugPrint("❌ [BillScanner] ERROR: $e");

//       throw BillScanException(
//         'Could not read receipt. Make sure image is clear.\n'
//         'Error: ${e.toString().split('\n').first}',
//       );
//     } finally {
//       recognizer?.close();
//       debugPrint("🧹 [BillScanner] recognizer closed");
//     }
//   }

//   // ───────────────────────── Helpers ─────────────────────────

//   static List<BillItem> _mapItems(List<dynamic> positions, String currency) {
//     final items = <BillItem>[];

//     for (final pos in positions) {
//       final name = (pos.product?.formattedValue ?? '').toString().trim();

//       final rawPrice = (pos.price?.formattedValue ?? '')
//           .replaceAll(RegExp(r'[^\d.,\-]'), '')
//           .replaceAll(',', '.');

//       double? amount = double.tryParse(rawPrice);

//       if (amount == null) continue;
//       if (amount <= 0 || amount > 99999) continue;
//       if (name.isEmpty) continue;

//       items.add(
//         BillItem(name: _titleCase(name), amount: amount, currency: currency),
//       );
//     }

//     return items;
//   }

//   static double? _parseTotal(String? raw) {
//     if (raw == null) return null;

//     final cleaned = raw.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');

//     return double.tryParse(cleaned);
//   }

//   static String _detectCurrency(dynamic receipt) {
//     final text =
//         '''
//       ${receipt.store?.value ?? ''}
//       ${receipt.total?.formattedValue ?? ''}
//     '''
//             .toLowerCase();

//     if (text.contains(r'$') || text.contains('usd')) return 'USD';
//     if (text.contains('€') || text.contains('eur')) return 'EUR';
//     if (text.contains('£') || text.contains('gbp')) return 'GBP';
//     if (text.contains('₹') || text.contains('inr')) return 'INR';
//     if (text.contains('npr') || text.contains('rs')) return 'NPR';

//     return ExpenseService.currency;
//   }

//   static String _titleCase(String s) {
//     return s
//         .split(' ')
//         .map(
//           (w) => w.isEmpty
//               ? w
//               : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
//         )
//         .join(' ');
//   }
// }
