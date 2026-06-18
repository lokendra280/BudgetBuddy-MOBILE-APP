// ────────────────────────────────────────────────────────────────────────────
class CurrencyInfo {
  final String code, name, symbol, flag;
  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

const kCurrencies = <CurrencyInfo>[
  // ── Asia-Pacific ──────────────────────────────────────────────────────────
  CurrencyInfo(code: 'NPR', name: 'Nepali Rupee', symbol: 'Rs', flag: '🇳🇵'),
  CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
  CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
  CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
  CurrencyInfo(
    code: 'KRW',
    name: 'South Korean Won',
    symbol: '₩',
    flag: '🇰🇷',
  ),
  CurrencyInfo(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: 'S\$',
    flag: '🇸🇬',
  ),
  CurrencyInfo(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: 'A\$',
    flag: '🇦🇺',
  ),

  // ── Europe ────────────────────────────────────────────────────────────────
  CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
  CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
  CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),

  // ── Americas ──────────────────────────────────────────────────────────────
  CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
  CurrencyInfo(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: 'C\$',
    flag: '🇨🇦',
  ),
  CurrencyInfo(
    code: 'BRL',
    name: 'Brazilian Real',
    symbol: 'R\$',
    flag: '🇧🇷',
  ),
  CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: 'MX\$', flag: '🇲🇽'),

  // ── Middle-East / Africa ──────────────────────────────────────────────────
  CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
  CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
];

/// Returns [CurrencyInfo] for [code], falling back to USD.
CurrencyInfo currencyOf(String code) => kCurrencies.firstWhere(
  (c) => c.code == code,
  orElse: () => kCurrencies.firstWhere((c) => c.code == 'USD'),
);

// ── Language ──────────────────────────────────────────────────────────────────

class LangOption {
  final String code, flag, native, english, defaultCurrency;
  const LangOption({
    required this.code,
    required this.flag,
    required this.native,
    required this.english,
    required this.defaultCurrency,
  });
}

const kLanguages = <LangOption>[
  LangOption(
    code: 'ne',
    flag: '🇳🇵',
    native: 'नेपाली',
    english: 'Nepali',
    defaultCurrency: 'NPR',
  ),
  LangOption(
    code: 'en',
    flag: '🇺🇸',
    native: 'English',
    english: 'English (US)',
    defaultCurrency: 'USD',
  ),
  LangOption(
    code: 'hi',
    flag: '🇮🇳',
    native: 'हिन्दी',
    english: 'Hindi',
    defaultCurrency: 'INR',
  ),
  LangOption(
    code: 'pt',
    flag: '🇵🇹',
    native: 'Português',
    english: 'Portuguese (BR)',
    defaultCurrency: 'BRL',
  ),
  LangOption(
    code: 'zh',
    flag: '🇨🇳',
    native: '中文',
    english: 'Chinese (Simplified)',
    defaultCurrency: 'CNY',
  ),
];
