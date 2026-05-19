import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SMS TRANSACTION — parsed result from a single bank SMS
// ─────────────────────────────────────────────────────────────────────────────
class SmsTransaction {
  final String raw; // original SMS body
  final String title; // merchant / narration
  final double amount;
  final bool isIncome; // credit = income, debit = expense
  final String currency;
  final String category; // auto-detected
  final DateTime date; // date from SMS or received date
  final String bank; // detected bank name
  final double? balance; // account balance after transaction (if present)

  const SmsTransaction({
    required this.raw,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.currency,
    required this.category,
    required this.date,
    required this.bank,
    this.balance,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS PARSER SERVICE
// Supports:
//  Nepal  — eSewa, Khalti, NIC Asia, Nabil, Himalayan, Laxmi Sunrise, NMB, Everest
//  India  — HDFC, ICICI, SBI, Axis, Kotak, Paytm, PhonePe, GPay
//  UK     — Barclays, NatWest, Monzo, Revolut, Starling
//  USA    — Chase, BoA, Wells Fargo, Citi, Venmo, Cash App
// ─────────────────────────────────────────────────────────────────────────────
class SmsParserService {
  // ── Public API ──────────────────────────────────────────────────────────────
  static SmsTransaction? parse(String body, String sender, DateTime received) {
    final cleaned = body.trim().replaceAll(RegExp(r'\s+'), ' ');

    final tx =
        _tryParseNepal(cleaned, sender, received) ??
        _tryParseIndia(cleaned, sender, received) ??
        _tryParseUK(cleaned, sender, received) ??
        _tryParseUSA(cleaned, sender, received) ??
        _tryParseGeneric(cleaned, sender, received);

    if (tx == null) return null;
    if (tx.amount <= 0 || tx.amount > 10_000_000) return null; // sanity filter
    return tx;
  }

  /// Filter a list of raw SMS bodies — returns only parseable bank SMS
  static List<SmsTransaction> parseAll(
    List<({String body, String sender, DateTime date})> messages,
  ) {
    final results = <SmsTransaction>[];
    for (final m in messages) {
      final tx = parse(m.body, m.sender, m.date);
      if (tx != null) results.add(tx);
    }
    // Sort newest first
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  // ── NEPAL parsers ───────────────────────────────────────────────────────────
  static SmsTransaction? _tryParseNepal(
    String body,
    String sender,
    DateTime date,
  ) {
    final lower = body.toLowerCase();

    // eSewa
    if (_contains(lower, ['esewa', 'e-sewa'])) {
      return _parseEsewa(body, sender, date);
    }
    // Khalti
    if (_contains(lower, ['khalti'])) {
      return _parseKhalti(body, sender, date);
    }
    // Nepal banks (NIC Asia, Nabil, Himalayan, Laxmi, NMB, Everest, Prabhu)
    if (_contains(lower, [
      'nic asia',
      'nabil',
      'himalayan',
      'laxmi sunrise',
      'nmb',
      'everest bank',
      'prabhu',
      'nepal bank',
      'rastriya banijya',
      'citizens bank',
      'sanima',
      'mega bank',
      'siddhartha',
    ])) {
      return _parseNepalBank(body, sender, date);
    }
    return null;
  }

  static SmsTransaction? _parseEsewa(
    String body,
    String sender,
    DateTime date,
  ) {
    // "Rs. 500.00 paid to Foodmandu via eSewa. Balance: Rs. 1,200.00"
    // "Rs. 1,000.00 received from Ramesh via eSewa."
    final amtRx = RegExp(r'Rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false);
    final creditRx = RegExp(r'received|credited|added', caseSensitive: false);
    final debitRx = RegExp(
      r'paid|debited|sent|transferred',
      caseSensitive: false,
    );
    final toFromRx = RegExp(
      r'(?:to|from)\s+([A-Za-z0-9 &\-]+?)(?:\s+via|\s+\.|$)',
      caseSensitive: false,
    );

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = creditRx.hasMatch(body);
    final isDebit = debitRx.hasMatch(body);
    if (!isIncome && !isDebit) return null;

    final merchant = toFromRx.firstMatch(body)?.group(1)?.trim() ?? 'eSewa';
    final balance = amounts.length > 1 ? amounts.last : null;

    return SmsTransaction(
      raw: body,
      title: merchant,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'NPR',
      category: _detectCategory(merchant, isIncome),
      date: _parseDate(body) ?? date,
      bank: 'eSewa',
      balance: balance,
    );
  }

  static SmsTransaction? _parseKhalti(
    String body,
    String sender,
    DateTime date,
  ) {
    // "NPR 500 paid to Netflix from Khalti. Avl Bal: NPR 2,300"
    final amtRx = RegExp(
      r'(?:NPR|Rs\.?)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final isIncome = RegExp(
      r'received|credited|added',
      caseSensitive: false,
    ).hasMatch(body);
    final toFromRx = RegExp(
      r'(?:to|from)\s+([A-Za-z0-9 &]+?)(?:\s+from|\s+via|\.|$)',
      caseSensitive: false,
    );

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final merchant = toFromRx.firstMatch(body)?.group(1)?.trim() ?? 'Khalti';
    return SmsTransaction(
      raw: body,
      title: merchant,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'NPR',
      category: _detectCategory(merchant, isIncome),
      date: _parseDate(body) ?? date,
      bank: 'Khalti',
      balance: amounts.length > 1 ? amounts.last : null,
    );
  }

  static SmsTransaction? _parseNepalBank(
    String body,
    String sender,
    DateTime date,
  ) {
    // "Dear Customer, Rs.5,000.00 has been credited to your A/C XXXX1234"
    // "Rs.1,500 debited from your account. Narration: ATM/POS Foodmandu"
    final amtRx = RegExp(
      r'(?:Rs\.?|NPR)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final creditRx = RegExp(
      r'credited|deposited|received',
      caseSensitive: false,
    );
    final debitRx = RegExp(
      r'debited|paid|withdrawn|deducted',
      caseSensitive: false,
    );
    final narRx = RegExp(
      r'(?:narration|particulars|remarks|ref|for)[:\s]+([A-Za-z0-9 /\-&]+?)(?:\.|,|$)',
      caseSensitive: false,
    );
    final balRx = RegExp(
      r'(?:bal|balance)[:\s]*(?:Rs\.?|NPR)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = creditRx.hasMatch(body);
    final isDebit = debitRx.hasMatch(body);
    if (!isIncome && !isDebit) return null;

    final narration = narRx.firstMatch(body)?.group(1)?.trim() ?? sender;
    final balMatch = balRx.firstMatch(body);
    final balance = balMatch != null
        ? double.tryParse(balMatch.group(1)!.replaceAll(',', ''))
        : null;

    return SmsTransaction(
      raw: body,
      title: narration,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'NPR',
      category: _detectCategory(narration, isIncome),
      date: _parseDate(body) ?? date,
      bank: _detectNepalBank(body, sender),
      balance: balance,
    );
  }

  // ── INDIA parsers ───────────────────────────────────────────────────────────
  static SmsTransaction? _tryParseIndia(
    String body,
    String sender,
    DateTime date,
  ) {
    final lower = body.toLowerCase();
    if (!_contains(lower, [
      'hdfc',
      'icici',
      'sbi',
      'axis',
      'kotak',
      'paytm',
      'phonepe',
      'gpay',
      'google pay',
      'union bank',
      'yes bank',
      'idfc',
      'indusind',
      'pnb',
      'bob',
      'canara',
      'debit',
      'credit',
    ]))
      return null;
    if (!_contains(lower, ['inr', '₹', 'rs.', 'rs ', 'debited', 'credited']))
      return null;

    // "INR 500.00 debited from A/c XX1234 on 12-01. Info: SWIGGY. Avl Bal INR 2,340.50"
    // "Your a/c XXXXXX1234 is credited with INR 10,000.00 on 12-Jan"
    final amtRx = RegExp(
      r'(?:INR|₹|Rs\.?)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final creditRx = RegExp(
      r'credited|credit|received|deposited',
      caseSensitive: false,
    );
    final debitRx = RegExp(
      r'debited|debit|paid|purchase|withdrawn',
      caseSensitive: false,
    );
    final infoRx = RegExp(
      r'(?:info|at|to|narr|upi|ref)[:\s]+([A-Za-z0-9 &\-/]+?)(?:\.|,|avl|bal|$)',
      caseSensitive: false,
    );
    final balRx = RegExp(
      r'(?:avl bal|bal|available)[:\s]*(?:INR|₹|Rs\.?)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = creditRx.hasMatch(body) && !debitRx.hasMatch(body);
    final title =
        infoRx.firstMatch(body)?.group(1)?.trim() ?? 'Bank transaction';
    final balMatch = balRx.firstMatch(body);
    final balance = balMatch != null
        ? double.tryParse(balMatch.group(1)!.replaceAll(',', ''))
        : null;

    return SmsTransaction(
      raw: body,
      title: title.isEmpty ? 'Bank transaction' : title,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'INR',
      category: _detectCategory(title, isIncome),
      date: _parseDate(body) ?? date,
      bank: _detectIndiaBank(body, sender),
      balance: balance,
    );
  }

  // ── UK parsers ──────────────────────────────────────────────────────────────
  static SmsTransaction? _tryParseUK(
    String body,
    String sender,
    DateTime date,
  ) {
    final lower = body.toLowerCase();
    if (!_contains(lower, [
      'barclays',
      'natwest',
      'monzo',
      'revolut',
      'starling',
      'lloyds',
      'halifax',
      'hsbc',
      'santander',
      'nationwide',
    ]))
      return null;

    // "You spent £12.50 at TESCO on 12 Jan"
    // "£500.00 has been paid into your account from EMPLOYER"
    final amtRx = RegExp(r'£([\d,]+\.?\d*)', caseSensitive: false);
    final creditRx = RegExp(
      r'paid in|received|credit|deposited',
      caseSensitive: false,
    );
    final atFromRx = RegExp(
      r'(?:at|from|to)\s+([A-Z][A-Za-z0-9 &\-]+?)(?:\s+on|\s+dated|\.|,|$)',
    );
    final balRx = RegExp(r'balance[:\s]*£([\d,]+\.?\d*)', caseSensitive: false);

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = creditRx.hasMatch(body);
    final merchant = atFromRx.firstMatch(body)?.group(1)?.trim() ?? 'Purchase';
    final balMatch = balRx.firstMatch(body);

    return SmsTransaction(
      raw: body,
      title: merchant,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'GBP',
      category: _detectCategory(merchant, isIncome),
      date: _parseDate(body) ?? date,
      bank: _detectUKBank(body, sender),
      balance: balMatch != null
          ? double.tryParse(balMatch.group(1)!.replaceAll(',', ''))
          : null,
    );
  }

  // ── USA parsers ─────────────────────────────────────────────────────────────
  static SmsTransaction? _tryParseUSA(
    String body,
    String sender,
    DateTime date,
  ) {
    final lower = body.toLowerCase();
    if (!_contains(lower, [
      'chase',
      'bank of america',
      'wells fargo',
      'citi',
      'venmo',
      'cash app',
      'zelle',
      'discover',
      'amex',
      'american express',
    ]))
      return null;

    // "Chase: $45.23 purchase at AMAZON.COM on Jan 12"
    // "A $500.00 deposit has been made to your account"
    final amtRx = RegExp(r'\$([\d,]+\.?\d*)', caseSensitive: false);
    final creditRx = RegExp(
      r'deposit|credit|received|refund|payment received',
      caseSensitive: false,
    );
    final atFromRx = RegExp(
      r'(?:at|from|to)\s+([A-Z][A-Za-z0-9 &\.\-]+?)(?:\s+on|\.|,|$)',
    );
    final balRx = RegExp(
      r'(?:balance|avail)[:\s]*\$([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = creditRx.hasMatch(body);
    final merchant = atFromRx.firstMatch(body)?.group(1)?.trim() ?? 'Purchase';
    final balMatch = balRx.firstMatch(body);

    return SmsTransaction(
      raw: body,
      title: merchant,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'USD',
      category: _detectCategory(merchant, isIncome),
      date: _parseDate(body) ?? date,
      bank: _detectUSABank(body, sender),
      balance: balMatch != null
          ? double.tryParse(balMatch.group(1)!.replaceAll(',', ''))
          : null,
    );
  }

  // ── Generic fallback ────────────────────────────────────────────────────────
  static SmsTransaction? _tryParseGeneric(
    String body,
    String sender,
    DateTime date,
  ) {
    final lower = body.toLowerCase();
    // Must have debit/credit keywords
    if (!_contains(lower, [
      'debited',
      'credited',
      'paid',
      'received',
      'spent',
      'withdrawn',
      'deposited',
      'purchase',
      'transaction',
    ]))
      return null;

    // Try any currency amount
    final amtRx = RegExp(
      r'(?:Rs\.?|INR|NPR|£|\$|€|₹)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final amounts = amtRx
        .allMatches(body)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (amounts.isEmpty) return null;

    final isIncome = RegExp(
      r'credit|received|deposit',
      caseSensitive: false,
    ).hasMatch(body);
    return SmsTransaction(
      raw: body,
      title: sender,
      amount: amounts.first,
      isIncome: isIncome,
      currency: 'NPR',
      category: isIncome ? 'Other' : 'Other',
      date: date,
      bank: sender,
      balance: null,
    );
  }

  // ── Date parser ─────────────────────────────────────────────────────────────
  static DateTime? _parseDate(String body) {
    try {
      // dd-MM-yyyy or dd/MM/yyyy
      final r1 = RegExp(r'(\d{2})[-/](\d{2})[-/](\d{4})');
      var m = r1.firstMatch(body);
      if (m != null)
        return DateTime(
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
        );

      // dd-Mon-yyyy or dd Mon yyyy
      final r2 = RegExp(
        r'(\d{1,2})[\s\-]?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s\-,]*(\d{4})?',
        caseSensitive: false,
      );
      m = r2.firstMatch(body);
      if (m != null) {
        final months = {
          'jan': 1,
          'feb': 2,
          'mar': 3,
          'apr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'aug': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dec': 12,
        };
        final mo = months[m.group(2)!.toLowerCase()] ?? 1;
        final yr = m.group(3) != null
            ? int.parse(m.group(3)!)
            : DateTime.now().year;
        return DateTime(yr, mo, int.parse(m.group(1)!));
      }
    } catch (_) {}
    return null;
  }

  // ── Category auto-detection ─────────────────────────────────────────────────
  static String _detectCategory(String text, bool isIncome) {
    if (isIncome) {
      final t = text.toLowerCase();
      if (_contains(t, ['salary', 'payroll', 'employer'])) return 'Salary';
      if (_contains(t, ['freelance', 'upwork', 'fiverr'])) return 'Freelance';
      if (_contains(t, ['dividend', 'interest', 'invest'])) return 'Investment';
      if (_contains(t, ['refund', 'cashback', 'reversal'])) return 'Other';
      return 'Other';
    }
    final t = text.toLowerCase();
    if (_contains(t, [
      'food',
      'swiggy',
      'zomato',
      'foodmandu',
      'pizza',
      'kfc',
      'mcd',
      'mcdonalds',
      'restaurant',
      'cafe',
      'burger',
      'sushi',
      'dhaba',
      'dine',
      'lunch',
      'dinner',
      'breakfast',
      'eat',
      'hungry',
      'dominos',
    ]))
      return 'Food';
    if (_contains(t, [
      'uber',
      'ola',
      'bolt',
      'rapido',
      'taxi',
      'bus',
      'metro',
      'fuel',
      'petrol',
      'diesel',
      'parking',
      'toll',
      'grab',
      'lyft',
    ]))
      return 'Transport';
    if (_contains(t, [
      'amazon',
      'flipkart',
      'myntra',
      'daraz',
      'okdam',
      'mall',
      'shop',
      'store',
      'market',
      'purchase',
      'buy',
      'retail',
    ]))
      return 'Shopping';
    if (_contains(t, [
      'hospital',
      'clinic',
      'pharmacy',
      'medical',
      'health',
      'doctor',
      'medicine',
      'lab',
      'diagnostic',
    ]))
      return 'Health';
    if (_contains(t, [
      'electricity',
      'water',
      'gas',
      'internet',
      'wifi',
      'broadband',
      'rent',
      'emi',
      'loan',
      'insurance',
      'subscription',
      'netflix',
      'spotify',
      'youtube',
      'prime',
    ]))
      return 'Bills';
    if (_contains(t, [
      'cinema',
      'movie',
      'game',
      'entertainment',
      'sport',
      'gym',
      'fitness',
      'club',
      'bar',
      'pub',
    ]))
      return 'Entertainment';
    if (_contains(t, ['atm', 'cash', 'withdraw'])) return 'Other';
    return 'Other';
  }

  // ── Bank detectors ──────────────────────────────────────────────────────────
  static String _detectNepalBank(String body, String sender) {
    final t = '${body.toLowerCase()} ${sender.toLowerCase()}';
    if (t.contains('esewa')) return 'eSewa';
    if (t.contains('khalti')) return 'Khalti';
    if (t.contains('nic asia')) return 'NIC Asia Bank';
    if (t.contains('nabil')) return 'Nabil Bank';
    if (t.contains('himalayan')) return 'Himalayan Bank';
    if (t.contains('laxmi')) return 'Laxmi Sunrise Bank';
    if (t.contains('nmb')) return 'NMB Bank';
    if (t.contains('everest')) return 'Everest Bank';
    if (t.contains('prabhu')) return 'Prabhu Bank';
    if (t.contains('citizens')) return 'Citizens Bank';
    if (t.contains('sanima')) return 'Sanima Bank';
    if (t.contains('mega')) return 'Mega Bank';
    if (t.contains('siddhartha')) return 'Siddhartha Bank';
    return sender;
  }

  static String _detectIndiaBank(String body, String sender) {
    final t = '${body.toLowerCase()} ${sender.toLowerCase()}';
    if (t.contains('hdfc')) return 'HDFC Bank';
    if (t.contains('icici')) return 'ICICI Bank';
    if (t.contains('sbi')) return 'SBI';
    if (t.contains('axis')) return 'Axis Bank';
    if (t.contains('kotak')) return 'Kotak Mahindra';
    if (t.contains('paytm')) return 'Paytm';
    if (t.contains('phonepe')) return 'PhonePe';
    if (t.contains('google pay') || t.contains('gpay')) return 'Google Pay';
    if (t.contains('union bank')) return 'Union Bank';
    if (t.contains('yes bank')) return 'Yes Bank';
    if (t.contains('pnb')) return 'PNB';
    return sender;
  }

  static String _detectUKBank(String body, String sender) {
    final t = '${body.toLowerCase()} ${sender.toLowerCase()}';
    if (t.contains('barclays')) return 'Barclays';
    if (t.contains('natwest')) return 'NatWest';
    if (t.contains('monzo')) return 'Monzo';
    if (t.contains('revolut')) return 'Revolut';
    if (t.contains('starling')) return 'Starling';
    if (t.contains('lloyds')) return 'Lloyds';
    if (t.contains('halifax')) return 'Halifax';
    if (t.contains('hsbc')) return 'HSBC';
    return sender;
  }

  static String _detectUSABank(String body, String sender) {
    final t = '${body.toLowerCase()} ${sender.toLowerCase()}';
    if (t.contains('chase')) return 'Chase';
    if (t.contains('bank of america')) return 'Bank of America';
    if (t.contains('wells fargo')) return 'Wells Fargo';
    if (t.contains('citi')) return 'Citibank';
    if (t.contains('venmo')) return 'Venmo';
    if (t.contains('cash app')) return 'Cash App';
    if (t.contains('zelle')) return 'Zelle';
    return sender;
  }

  static bool _contains(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
