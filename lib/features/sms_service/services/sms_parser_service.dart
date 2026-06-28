import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SMS TRANSACTION
// ─────────────────────────────────────────────────────────────────────────────
class SmsTransaction {
  final String raw;
  final String title;
  final double amount;
  final bool isIncome;
  final String currency;
  final String category;
  final DateTime date;
  final String bank;
  final double? balance;

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
// Pre-compiled regex patterns — compiled once, reused on every parse call
// ─────────────────────────────────────────────────────────────────────────────
class _Rx {
  // Amounts
  static final nprAmount = RegExp(r'(?:Rs\.?|NPR)\s*([\d,]+\.?\d*)', caseSensitive: false);
  static final inrAmount = RegExp(r'(?:INR|₹|Rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false);
  static final gbpAmount = RegExp(r'£([\d,]+\.?\d*)');
  static final usdAmount = RegExp(r'\$([\d,]+\.?\d*)');
  static final anyAmount = RegExp(r'(?:Rs\.?|INR|NPR|£|\$|€|₹)\s*([\d,]+\.?\d*)', caseSensitive: false);

  // Credit / debit signals
  static final credit = RegExp(r'credit(?:ed)?|received|deposited|paid[\s\-]in|added', caseSensitive: false);
  static final debit  = RegExp(r'debit(?:ed)?|paid|withdrawn|deducted|purchase|spent|sent|transferred', caseSensitive: false);

  // Merchant / narration extraction
  static final toFrom    = RegExp(r'(?:to|from)\s+([A-Za-z0-9 &\-]+?)(?:\s+(?:via|from|on)|\s*[.,]|$)', caseSensitive: false);
  static final atMerch   = RegExp(r'(?:at|from|to)\s+([A-Z][A-Za-z0-9 &.\-]+?)(?:\s+on|\s*[.,]|$)');
  static final narration = RegExp(r'(?:narration|particulars|remarks|ref|info|upi|for)[:\s]+([A-Za-z0-9 /\-&]+?)(?:[.,]|avl|bal|$)', caseSensitive: false);

  // Balance
  static final balance   = RegExp(r'(?:avl[\s\-]?bal|bal(?:ance)?)[:\s]*(?:Rs\.?|INR|NPR|₹|£|\$)?\s*([\d,]+\.?\d*)', caseSensitive: false);
  static final gbpBal    = RegExp(r'balance[:\s]*£([\d,]+\.?\d*)', caseSensitive: false);
  static final usdBal    = RegExp(r'(?:balance|avail)[:\s]*\$([\d,]+\.?\d*)', caseSensitive: false);

  // Dates
  static final dateDMY   = RegExp(r'(\d{2})[-/](\d{2})[-/](\d{4})');
  static final dateMonth = RegExp(r'(\d{1,2})[\s\-]?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s\-,]*(\d{4})?', caseSensitive: false);

  // Bank SMS keywords
  static final nepalKeywords  = RegExp(r'esewa|e-sewa|khalti|nic asia|nabil|himalayan|laxmi sunrise|nmb|everest bank|prabhu|nepal bank|rastriya banijya|citizens bank|sanima|mega bank|siddhartha', caseSensitive: false);
  static final indiaKeywords  = RegExp(r'hdfc|icici|sbi|axis|kotak|paytm|phonepe|gpay|google pay|union bank|yes bank|idfc|indusind|pnb|bob|canara', caseSensitive: false);
  static final indiaSignals   = RegExp(r'inr|₹|debited|credited', caseSensitive: false);
  static final ukKeywords     = RegExp(r'barclays|natwest|monzo|revolut|starling|lloyds|halifax|hsbc|santander|nationwide', caseSensitive: false);
  static final usaKeywords    = RegExp(r'chase|bank of america|wells fargo|citi(?:bank)?|venmo|cash app|zelle|discover|amex|american express', caseSensitive: false);
  static final genericSignals = RegExp(r'debited|credited|paid|received|spent|withdrawn|deposited|purchase|transaction', caseSensitive: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Month lookup — avoids rebuilding map on every date parse
// ─────────────────────────────────────────────────────────────────────────────
const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
  'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
  'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY KEYWORDS — defined once as const maps
// ─────────────────────────────────────────────────────────────────────────────
const _expenseCategories = <String, List<String>>{
  'Food':          ['food', 'swiggy', 'zomato', 'foodmandu', 'pizza', 'kfc', 'mcdonalds', 'mcd', 'restaurant', 'cafe', 'burger', 'sushi', 'dhaba', 'dine', 'lunch', 'dinner', 'breakfast', 'eat', 'hungry', 'dominos'],
  'Transport':     ['uber', 'ola', 'bolt', 'rapido', 'taxi', 'bus', 'metro', 'fuel', 'petrol', 'diesel', 'parking', 'toll', 'grab', 'lyft'],
  'Shopping':      ['amazon', 'flipkart', 'myntra', 'daraz', 'okdam', 'mall', 'shop', 'store', 'market', 'purchase', 'buy', 'retail'],
  'Health':        ['hospital', 'clinic', 'pharmacy', 'medical', 'health', 'doctor', 'medicine', 'lab', 'diagnostic'],
  'Bills':         ['electricity', 'water', 'gas', 'internet', 'wifi', 'broadband', 'rent', 'emi', 'loan', 'insurance', 'subscription', 'netflix', 'spotify', 'youtube', 'prime'],
  'Entertainment': ['cinema', 'movie', 'game', 'entertainment', 'sport', 'gym', 'fitness', 'club', 'bar', 'pub'],
};

const _incomeCategories = <String, List<String>>{
  'Salary':     ['salary', 'payroll', 'employer'],
  'Freelance':  ['freelance', 'upwork', 'fiverr'],
  'Investment': ['dividend', 'interest', 'invest'],
};

// ─────────────────────────────────────────────────────────────────────────────
// SMS PARSER SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class SmsParserService {

  // ── Public API ─────────────────────────────────────────────────────────────
  static SmsTransaction? parse(String body, String sender, DateTime received) {
    final cleaned = body.trim().replaceAll(RegExp(r'\s+'), ' ');

    final tx =
        _tryNepal(cleaned, sender, received) ??
        _tryIndia(cleaned, sender, received) ??
        _tryUK(cleaned, sender, received) ??
        _tryUSA(cleaned, sender, received) ??
        _tryGeneric(cleaned, sender, received);

    if (tx == null) return null;
    if (tx.amount <= 0 || tx.amount > 10_000_000) return null;
    return tx;
  }

  static List<SmsTransaction> parseAll(
    List<({String body, String sender, DateTime date})> messages,
  ) {
    final results = <SmsTransaction>[];
    for (final m in messages) {
      final tx = parse(m.body, m.sender, m.date);
      if (tx != null) results.add(tx);
    }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  // ── NEPAL ──────────────────────────────────────────────────────────────────
  static SmsTransaction? _tryNepal(String body, String sender, DateTime date) {
    if (!_Rx.nepalKeywords.hasMatch(body)) return null;
    final lower = body.toLowerCase();

    if (lower.contains('esewa') || lower.contains('e-sewa')) {
      return _parseEsewa(body, sender, date);
    }
    if (lower.contains('khalti')) {
      return _parseKhalti(body, sender, date);
    }
    return _parseNepalBank(body, sender, date);
  }

  static SmsTransaction? _parseEsewa(String body, String sender, DateTime date) {
    final amounts = _extractAmounts(_Rx.nprAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    if (!isIncome && !_Rx.debit.hasMatch(body)) return null;

    final merchant = _Rx.toFrom.firstMatch(body)?.group(1)?.trim() ?? 'eSewa';
    return _build(
      raw: body, title: merchant, amount: amounts.first,
      isIncome: isIncome, currency: 'NPR',
      bank: 'eSewa', date: date,
      balance: amounts.length > 1 ? amounts.last : null,
    );
  }

  static SmsTransaction? _parseKhalti(String body, String sender, DateTime date) {
    final amounts = _extractAmounts(_Rx.nprAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    final merchant = _Rx.toFrom.firstMatch(body)?.group(1)?.trim() ?? 'Khalti';
    return _build(
      raw: body, title: merchant, amount: amounts.first,
      isIncome: isIncome, currency: 'NPR',
      bank: 'Khalti', date: date,
      balance: amounts.length > 1 ? amounts.last : null,
    );
  }

  static SmsTransaction? _parseNepalBank(String body, String sender, DateTime date) {
    final amounts = _extractAmounts(_Rx.nprAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    if (!isIncome && !_Rx.debit.hasMatch(body)) return null;

    final narr = _Rx.narration.firstMatch(body)?.group(1)?.trim() ?? sender;
    final bal  = _extractBalance(_Rx.balance, body);
    final bank = _detectNepalBank(body, sender);

    return _build(
      raw: body, title: narr, amount: amounts.first,
      isIncome: isIncome, currency: 'NPR',
      bank: bank, date: date, balance: bal,
    );
  }

  // ── INDIA ──────────────────────────────────────────────────────────────────
  static SmsTransaction? _tryIndia(String body, String sender, DateTime date) {
    if (!_Rx.indiaKeywords.hasMatch(body) && !_Rx.indiaSignals.hasMatch(body)) {
      return null;
    }

    final amounts = _extractAmounts(_Rx.inrAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body) && !_Rx.debit.hasMatch(body);
    final title = _Rx.narration.firstMatch(body)?.group(1)?.trim()
        ?? _Rx.toFrom.firstMatch(body)?.group(1)?.trim()
        ?? 'Bank transaction';
    final bal = _extractBalance(_Rx.balance, body);

    return _build(
      raw: body,
      title: title.isEmpty ? 'Bank transaction' : title,
      amount: amounts.first,
      isIncome: isIncome, currency: 'INR',
      bank: _detectIndiaBank(body, sender), date: date, balance: bal,
    );
  }

  // ── UK ─────────────────────────────────────────────────────────────────────
  static SmsTransaction? _tryUK(String body, String sender, DateTime date) {
    if (!_Rx.ukKeywords.hasMatch(body)) return null;

    final amounts = _extractAmounts(_Rx.gbpAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    final merchant = _Rx.atMerch.firstMatch(body)?.group(1)?.trim() ?? 'Purchase';
    final bal = _extractBalance(_Rx.gbpBal, body);

    return _build(
      raw: body, title: merchant, amount: amounts.first,
      isIncome: isIncome, currency: 'GBP',
      bank: _detectUKBank(body, sender), date: date, balance: bal,
    );
  }

  // ── USA ─────────────────────────────────────────────────────────────────────
  static SmsTransaction? _tryUSA(String body, String sender, DateTime date) {
    if (!_Rx.usaKeywords.hasMatch(body)) return null;

    final amounts = _extractAmounts(_Rx.usdAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    final merchant = _Rx.atMerch.firstMatch(body)?.group(1)?.trim() ?? 'Purchase';
    final bal = _extractBalance(_Rx.usdBal, body);

    return _build(
      raw: body, title: merchant, amount: amounts.first,
      isIncome: isIncome, currency: 'USD',
      bank: _detectUSABank(body, sender), date: date, balance: bal,
    );
  }

  // ── GENERIC fallback ───────────────────────────────────────────────────────
  static SmsTransaction? _tryGeneric(String body, String sender, DateTime date) {
    if (!_Rx.genericSignals.hasMatch(body)) return null;

    final amounts = _extractAmounts(_Rx.anyAmount, body);
    if (amounts.isEmpty) return null;

    final isIncome = _Rx.credit.hasMatch(body);
    return _build(
      raw: body, title: sender, amount: amounts.first,
      isIncome: isIncome, currency: 'NPR',
      bank: sender, date: date,
    );
  }

  // ── Builder — always sets category to 'Bank' for imported SMS ─────────────
  static SmsTransaction _build({
    required String raw,
    required String title,
    required double amount,
    required bool isIncome,
    required String currency,
    required String bank,
    required DateTime date,
    double? balance,
  }) =>
      SmsTransaction(
        raw: raw,
        title: title,
        amount: amount,
        isIncome: isIncome,
        currency: currency,
        // ── Always 'Bank' for SMS imports so user can identify source ──────
        category: 'Bank',
        date: _parseDate(raw) ?? date,
        bank: bank,
        balance: balance,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────
  static List<double> _extractAmounts(RegExp rx, String body) => rx
      .allMatches(body)
      .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
      .where((v) => v > 0)
      .toList();

  static double? _extractBalance(RegExp rx, String body) {
    final m = rx.firstMatch(body);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }

  static DateTime? _parseDate(String body) {
    try {
      var m = _Rx.dateDMY.firstMatch(body);
      if (m != null) {
        return DateTime(
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
        );
      }
      m = _Rx.dateMonth.firstMatch(body);
      if (m != null) {
        final mo = _months[m.group(2)!.toLowerCase()] ?? 1;
        final yr = m.group(3) != null ? int.parse(m.group(3)!) : DateTime.now().year;
        return DateTime(yr, mo, int.parse(m.group(1)!));
      }
    } catch (_) {}
    return null;
  }

  // ── Bank detectors ─────────────────────────────────────────────────────────
  static String _detectNepalBank(String body, String sender) {
    final t = '$body $sender'.toLowerCase();
    if (t.contains('esewa'))      return 'eSewa';
    if (t.contains('khalti'))     return 'Khalti';
    if (t.contains('nic asia'))   return 'NIC Asia Bank';
    if (t.contains('nabil'))      return 'Nabil Bank';
    if (t.contains('himalayan'))  return 'Himalayan Bank';
    if (t.contains('laxmi'))      return 'Laxmi Sunrise Bank';
    if (t.contains('nmb'))        return 'NMB Bank';
    if (t.contains('everest'))    return 'Everest Bank';
    if (t.contains('prabhu'))     return 'Prabhu Bank';
    if (t.contains('citizens'))   return 'Citizens Bank';
    if (t.contains('sanima'))     return 'Sanima Bank';
    if (t.contains('mega'))       return 'Mega Bank';
    if (t.contains('siddhartha')) return 'Siddhartha Bank';
    return sender;
  }

  static String _detectIndiaBank(String body, String sender) {
    final t = '$body $sender'.toLowerCase();
    if (t.contains('hdfc'))         return 'HDFC Bank';
    if (t.contains('icici'))        return 'ICICI Bank';
    if (t.contains('sbi'))          return 'SBI';
    if (t.contains('axis'))         return 'Axis Bank';
    if (t.contains('kotak'))        return 'Kotak Mahindra';
    if (t.contains('paytm'))        return 'Paytm';
    if (t.contains('phonepe'))      return 'PhonePe';
    if (t.contains('google pay') || t.contains('gpay')) return 'Google Pay';
    if (t.contains('union bank'))   return 'Union Bank';
    if (t.contains('yes bank'))     return 'Yes Bank';
    if (t.contains('pnb'))          return 'PNB';
    return sender;
  }

  static String _detectUKBank(String body, String sender) {
    final t = '$body $sender'.toLowerCase();
    if (t.contains('barclays'))  return 'Barclays';
    if (t.contains('natwest'))   return 'NatWest';
    if (t.contains('monzo'))     return 'Monzo';
    if (t.contains('revolut'))   return 'Revolut';
    if (t.contains('starling'))  return 'Starling';
    if (t.contains('lloyds'))    return 'Lloyds';
    if (t.contains('halifax'))   return 'Halifax';
    if (t.contains('hsbc'))      return 'HSBC';
    return sender;
  }

  static String _detectUSABank(String body, String sender) {
    final t = '$body $sender'.toLowerCase();
    if (t.contains('chase'))           return 'Chase';
    if (t.contains('bank of america')) return 'Bank of America';
    if (t.contains('wells fargo'))     return 'Wells Fargo';
    if (t.contains('citi'))            return 'Citibank';
    if (t.contains('venmo'))           return 'Venmo';
    if (t.contains('cash app'))        return 'Cash App';
    if (t.contains('zelle'))           return 'Zelle';
    return sender;
  }
}