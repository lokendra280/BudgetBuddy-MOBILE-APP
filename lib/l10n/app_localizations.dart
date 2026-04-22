import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ne')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BudgetBuddy'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @monthlybudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlybudget;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @netSaving.
  ///
  /// In en, this message translates to:
  /// **'Net Savings'**
  String get netSaving;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @addexpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense To See Chart'**
  String get addexpense;

  /// No description provided for @youHaventSpend.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t spent anything yet'**
  String get youHaventSpend;

  /// No description provided for @weeklyComparsion.
  ///
  /// In en, this message translates to:
  /// **'Week Comparison'**
  String get weeklyComparsion;

  /// No description provided for @thisweek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisweek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noEntryYet.
  ///
  /// In en, this message translates to:
  /// **'No Entries Yet'**
  String get noEntryYet;

  /// No description provided for @tapToAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add income or expense'**
  String get tapToAddIncome;

  /// No description provided for @statements.
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get statements;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @aiInsight.
  ///
  /// In en, this message translates to:
  /// **'Ai Insights'**
  String get aiInsight;

  /// No description provided for @netDeficit.
  ///
  /// In en, this message translates to:
  /// **'Net Deficit'**
  String get netDeficit;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @dataRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dataRange;

  /// No description provided for @dailyOverview.
  ///
  /// In en, this message translates to:
  /// **'Daily OverView'**
  String get dailyOverview;

  /// No description provided for @noDataPeriod.
  ///
  /// In en, this message translates to:
  /// **'No Data For This Period'**
  String get noDataPeriod;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export As Pdf'**
  String get export;

  /// No description provided for @bankStyle.
  ///
  /// In en, this message translates to:
  /// **'Bank-Style Statements 0 Transactions'**
  String get bankStyle;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @noTransaction.
  ///
  /// In en, this message translates to:
  /// **'No Transactions For This Period'**
  String get noTransaction;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'net'**
  String get net;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signinContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signinContinue;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get continueWithoutAccount;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? Create account'**
  String get newHere;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpToTrack.
  ///
  /// In en, this message translates to:
  /// **'Sign up to track and sync your finances'**
  String get signUpToTrack;

  /// No description provided for @alreadyHaveAn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAn;

  /// No description provided for @createdAccount.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get createdAccount;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'LeaderBoard'**
  String get leaderboard;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @youSpending.
  ///
  /// In en, this message translates to:
  /// **'Your Spending this Month'**
  String get youSpending;

  /// No description provided for @topSaver.
  ///
  /// In en, this message translates to:
  /// **'Top Savers This Month'**
  String get topSaver;

  /// No description provided for @loverSpending.
  ///
  /// In en, this message translates to:
  /// **'Lower Spending = better rank'**
  String get loverSpending;

  /// No description provided for @dayStirks.
  ///
  /// In en, this message translates to:
  /// **'day Streak'**
  String get dayStirks;

  /// No description provided for @activeChallenges.
  ///
  /// In en, this message translates to:
  /// **'Active Challenges'**
  String get activeChallenges;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @bothGetBonus.
  ///
  /// In en, this message translates to:
  /// **'Both get + 3 bonus streak days!'**
  String get bothGetBonus;

  /// No description provided for @yourCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR CODE'**
  String get yourCode;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// No description provided for @signIntoApply.
  ///
  /// In en, this message translates to:
  /// **'Sing in to apply a referral code and earn streak days'**
  String get signIntoApply;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share my report'**
  String get shareReport;

  /// No description provided for @shareMonthly.
  ///
  /// In en, this message translates to:
  /// **'Share monthly spending a summary as image'**
  String get shareMonthly;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @friendsInvited.
  ///
  /// In en, this message translates to:
  /// **'Friends Invited'**
  String get friendsInvited;

  /// No description provided for @keepSharing.
  ///
  /// In en, this message translates to:
  /// **'Keep Sharing to grow!'**
  String get keepSharing;

  /// No description provided for @howItWork.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWork;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share your code or spending report with friends'**
  String get shareYourCode;

  /// No description provided for @friendDownloads.
  ///
  /// In en, this message translates to:
  /// **'Friend downloads BudgetBuddy and signs up'**
  String get friendDownloads;

  /// No description provided for @theyGoToCommunity.
  ///
  /// In en, this message translates to:
  /// **'They go to Community -> Invite and enter your code'**
  String get theyGoToCommunity;

  /// No description provided for @bothGet.
  ///
  /// In en, this message translates to:
  /// **'Both get +3 bonus streak days'**
  String get bothGet;

  /// No description provided for @completeTogether.
  ///
  /// In en, this message translates to:
  /// **'Complete together on the savings leaderboard'**
  String get completeTogether;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get category;

  /// No description provided for @row.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @addAnotherItems.
  ///
  /// In en, this message translates to:
  /// **'Add Another Items'**
  String get addAnotherItems;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// No description provided for @overView.
  ///
  /// In en, this message translates to:
  /// **'OverView'**
  String get overView;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @predict.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get predict;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @coach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coach;

  /// No description provided for @saveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save Income'**
  String get saveIncome;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'ne': return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
