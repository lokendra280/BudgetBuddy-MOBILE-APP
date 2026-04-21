import 'package:expensetracker/l10n/app_localizations.dart';

class CategoryLocalization {
  static String getName(AppLocalizations l10n, String key) {
    switch (key.toLowerCase()) {
      case 'food':
        return l10n.food;
      case 'transport':
        return l10n.transport;
      case 'shopping':
        return l10n.shopping;
      case 'health':
        return l10n.health;
      case 'bill':
      case 'bills':
        return l10n.bill;
      case 'entertainment':
        return l10n.entertainment;
      case 'education':
        return l10n.education;
      case 'travel':
        return l10n.travel;
      case 'groceries':
        return l10n.groceries;
      case 'salary':
        return l10n.salary;
      case 'investment':
        return l10n.investment;
      case 'gift':
        return l10n.gift;
      case 'freelance':
        return l10n.freelance;
      case 'business':
        return l10n.business;
      case 'other':
        return l10n.other;
      default:
        return key;
    }
  }
}
