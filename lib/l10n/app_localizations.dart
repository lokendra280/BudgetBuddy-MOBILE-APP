import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

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
    Locale('ne'),
    Locale('pt'),
    Locale('zh')
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
  /// **'Share Report'**
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
  /// **'Category'**
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

  /// No description provided for @haveAnFriendsCode.
  ///
  /// In en, this message translates to:
  /// **'Have a friend\'s Code?'**
  String get haveAnFriendsCode;

  /// No description provided for @enterItToGiveThemCredit.
  ///
  /// In en, this message translates to:
  /// **'Enter it to give them credit and earn +3 streak days for yourSelf'**
  String get enterItToGiveThemCredit;

  /// No description provided for @burnRateAndRunWay.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate & RunWay'**
  String get burnRateAndRunWay;

  /// No description provided for @dailySpend.
  ///
  /// In en, this message translates to:
  /// **'Daily Spend'**
  String get dailySpend;

  /// No description provided for @monthlyRate.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rate'**
  String get monthlyRate;

  /// No description provided for @runWay.
  ///
  /// In en, this message translates to:
  /// **'Runway'**
  String get runWay;

  /// No description provided for @aiSpendingInsight.
  ///
  /// In en, this message translates to:
  /// **'Ai Spending Insight'**
  String get aiSpendingInsight;

  /// No description provided for @addMoreExpenses.
  ///
  /// In en, this message translates to:
  /// **'Add More Expenses'**
  String get addMoreExpenses;

  /// No description provided for @wellAnalysisPatternOnce.
  ///
  /// In en, this message translates to:
  /// **'We Will analyses pattern once you have more data'**
  String get wellAnalysisPatternOnce;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & Recurring'**
  String get subscriptions;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @spend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get spend;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get saved;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get achieved;

  /// No description provided for @autoCategorization.
  ///
  /// In en, this message translates to:
  /// **'Auto-Categorization'**
  String get autoCategorization;

  /// No description provided for @budgetBuddyDetects.
  ///
  /// In en, this message translates to:
  /// **'BudgetBuddy detect categories automatically from your entry title'**
  String get budgetBuddyDetects;

  /// No description provided for @nextMonthForecast.
  ///
  /// In en, this message translates to:
  /// **'Next Month Forecast'**
  String get nextMonthForecast;

  /// No description provided for @predictSpend.
  ///
  /// In en, this message translates to:
  /// **'Predicted Spend'**
  String get predictSpend;

  /// No description provided for @predictedIncome.
  ///
  /// In en, this message translates to:
  /// **'Predicated Income'**
  String get predictedIncome;

  /// No description provided for @estBalance.
  ///
  /// In en, this message translates to:
  /// **'Est.Balance'**
  String get estBalance;

  /// No description provided for @categoryForecast.
  ///
  /// In en, this message translates to:
  /// **'Category Forecast'**
  String get categoryForecast;

  /// No description provided for @addMoreExpenseAcross.
  ///
  /// In en, this message translates to:
  /// **'Add More expenses across months to see predictions'**
  String get addMoreExpenseAcross;

  /// No description provided for @incomeGrowth.
  ///
  /// In en, this message translates to:
  /// **'Income Growth'**
  String get incomeGrowth;

  /// No description provided for @logIncome.
  ///
  /// In en, this message translates to:
  /// **'Log Income entries to track growth over time'**
  String get logIncome;

  /// No description provided for @savingGoal.
  ///
  /// In en, this message translates to:
  /// **'Saving Goals'**
  String get savingGoal;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get newGoal;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get complete;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @yourAiFinancialCoach.
  ///
  /// In en, this message translates to:
  /// **'Your Ai Financial Coach'**
  String get yourAiFinancialCoach;

  /// No description provided for @personalizedTips.
  ///
  /// In en, this message translates to:
  /// **'Personalized tips from your spending pattern'**
  String get personalizedTips;

  /// No description provided for @personalAdvice.
  ///
  /// In en, this message translates to:
  /// **'Personalized Advice'**
  String get personalAdvice;

  /// No description provided for @setARealisticBudget.
  ///
  /// In en, this message translates to:
  /// **'Set a realistic budget'**
  String get setARealisticBudget;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to settings Budget and set your monthly limit'**
  String get goToSettings;

  /// No description provided for @impact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impact;

  /// No description provided for @recurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get recurringExpenses;

  /// No description provided for @noRecurringDetected.
  ///
  /// In en, this message translates to:
  /// **'No recurring Detected'**
  String get noRecurringDetected;

  /// No description provided for @repeatedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Repeated Expenses appear here'**
  String get repeatedExpenses;

  /// No description provided for @insight.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insight;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @importSms.
  ///
  /// In en, this message translates to:
  /// **'Import From SMS'**
  String get importSms;

  /// No description provided for @aiSpending.
  ///
  /// In en, this message translates to:
  /// **'AI Spending Insights'**
  String get aiSpending;

  /// No description provided for @savingGoals.
  ///
  /// In en, this message translates to:
  /// **'Saving Goals'**
  String get savingGoals;

  /// No description provided for @billReminder.
  ///
  /// In en, this message translates to:
  /// **'Bill & Reminder'**
  String get billReminder;

  /// No description provided for @monthlyCommitments.
  ///
  /// In en, this message translates to:
  /// **'Monthly Commitments'**
  String get monthlyCommitments;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noBillsAdded.
  ///
  /// In en, this message translates to:
  /// **'No bills added yet'**
  String get noBillsAdded;

  /// No description provided for @addBills.
  ///
  /// In en, this message translates to:
  /// **'Add bills, EMIs and subscriptions to get reminded before they\'re due'**
  String get addBills;

  /// No description provided for @addFirstBill.
  ///
  /// In en, this message translates to:
  /// **'Add First Bill'**
  String get addFirstBill;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get addBill;

  /// No description provided for @emi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get emi;

  /// No description provided for @addBillEmi.
  ///
  /// In en, this message translates to:
  /// **'Add Bill / EMI'**
  String get addBillEmi;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Bill name (e.g. Netflix, Home EMI)'**
  String get example;

  /// No description provided for @recurringMonthly.
  ///
  /// In en, this message translates to:
  /// **'Recurring monthly'**
  String get recurringMonthly;

  /// No description provided for @repeatsEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Repeats every month'**
  String get repeatsEveryMonth;

  /// No description provided for @dueOnDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Due on day of month'**
  String get dueOnDayOfMonth;

  /// No description provided for @remindMeBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me before'**
  String get remindMeBefore;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add & Schedule Reminder'**
  String get addSchedule;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealth;

  /// No description provided for @savingRate.
  ///
  /// In en, this message translates to:
  /// **'Saving Rate'**
  String get savingRate;

  /// No description provided for @budgetControl.
  ///
  /// In en, this message translates to:
  /// **'Budget Control'**
  String get budgetControl;

  /// No description provided for @expenseBalance.
  ///
  /// In en, this message translates to:
  /// **'Expense Balance'**
  String get expenseBalance;

  /// No description provided for @consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get consistency;

  /// No description provided for @billLoad.
  ///
  /// In en, this message translates to:
  /// **'Bill Load'**
  String get billLoad;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get goalProgress;

  /// No description provided for @burnRate.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate & Runway'**
  String get burnRate;

  /// No description provided for @nextMonthCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Next Month Cash Flow'**
  String get nextMonthCashFlow;

  /// No description provided for @billCommitments.
  ///
  /// In en, this message translates to:
  /// **'Bill Commitments'**
  String get billCommitments;

  /// No description provided for @projectedIncome.
  ///
  /// In en, this message translates to:
  /// **'Projected Income'**
  String get projectedIncome;

  /// No description provided for @projectedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Projected Expenses'**
  String get projectedExpenses;

  /// No description provided for @projectedSurplus.
  ///
  /// In en, this message translates to:
  /// **'Projected Surplus'**
  String get projectedSurplus;

  /// No description provided for @projectedShortfall.
  ///
  /// In en, this message translates to:
  /// **'Projected Shortfall'**
  String get projectedShortfall;

  /// No description provided for @committedBills.
  ///
  /// In en, this message translates to:
  /// **'Committed Bills'**
  String get committedBills;

  /// No description provided for @goalsRequired.
  ///
  /// In en, this message translates to:
  /// **'Goals Required'**
  String get goalsRequired;

  /// No description provided for @upcomingBillImpact.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bill Impact'**
  String get upcomingBillImpact;

  /// No description provided for @overdueBills.
  ///
  /// In en, this message translates to:
  /// **'Overdue — pay now'**
  String get overdueBills;

  /// No description provided for @dueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due Soon'**
  String get dueSoon;

  /// No description provided for @largestBills.
  ///
  /// In en, this message translates to:
  /// **'Largest commitments'**
  String get largestBills;

  /// No description provided for @ofIncome.
  ///
  /// In en, this message translates to:
  /// **'of income'**
  String get ofIncome;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @monthlyBills.
  ///
  /// In en, this message translates to:
  /// **'Monthly Bills'**
  String get monthlyBills;

  /// No description provided for @billsVsIncome.
  ///
  /// In en, this message translates to:
  /// **'Bills vs Income'**
  String get billsVsIncome;

  /// No description provided for @largestBillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Largest bills'**
  String get largestBillsLabel;

  /// No description provided for @goalTracker.
  ///
  /// In en, this message translates to:
  /// **'Goal Tracker'**
  String get goalTracker;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get daysLeft;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @atRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get atRisk;

  /// No description provided for @availablePerDay.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availablePerDay;

  /// No description provided for @needPerDay.
  ///
  /// In en, this message translates to:
  /// **'Need'**
  String get needPerDay;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get perDay;

  /// No description provided for @smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'Smart Alerts'**
  String get smartAlerts;

  /// No description provided for @keepTracking.
  ///
  /// In en, this message translates to:
  /// **'Keep tracking!'**
  String get keepTracking;

  /// No description provided for @addMoreDataUnlock.
  ///
  /// In en, this message translates to:
  /// **'Add more data to unlock personalised coaching.'**
  String get addMoreDataUnlock;

  /// No description provided for @disposableIncome.
  ///
  /// In en, this message translates to:
  /// **'disposable income after bills'**
  String get disposableIncome;

  /// No description provided for @basedOnIncome.
  ///
  /// In en, this message translates to:
  /// **'Based on your income'**
  String get basedOnIncome;

  /// No description provided for @needs.
  ///
  /// In en, this message translates to:
  /// **'Needs (50%)'**
  String get needs;

  /// No description provided for @wants.
  ///
  /// In en, this message translates to:
  /// **'Wants (30%)'**
  String get wants;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings (20%)'**
  String get savings;

  /// No description provided for @needsDescription.
  ///
  /// In en, this message translates to:
  /// **'Rent, food, bills, transport'**
  String get needsDescription;

  /// No description provided for @wantsDescription.
  ///
  /// In en, this message translates to:
  /// **'Entertainment, shopping, dining out'**
  String get wantsDescription;

  /// No description provided for @savingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund, investments, goals'**
  String get savingsDescription;

  /// No description provided for @savingsRateThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Savings rate this month'**
  String get savingsRateThisMonth;

  /// No description provided for @target20.
  ///
  /// In en, this message translates to:
  /// **'Target: 20%'**
  String get target20;

  /// No description provided for @billCommitmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed monthly outflows before discretionary spend'**
  String get billCommitmentSubtitle;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @displayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get displayCurrency;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get biometricLock;

  /// No description provided for @requireFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint or face to open'**
  String get requireFingerprint;

  /// No description provided for @notAvailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get notAvailableDevice;

  /// No description provided for @appBiometricProtected.
  ///
  /// In en, this message translates to:
  /// **'App is biometric-protected'**
  String get appBiometricProtected;

  /// No description provided for @monthlySpendingLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending limit'**
  String get monthlySpendingLimit;

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save Budget'**
  String get saveBudget;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @getRemindedToLog.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to log expenses'**
  String get getRemindedToLog;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// No description provided for @keepLoggingDaily.
  ///
  /// In en, this message translates to:
  /// **'Keep logging daily to maintain it'**
  String get keepLoggingDaily;

  /// No description provided for @aboutBudgetBuddy.
  ///
  /// In en, this message translates to:
  /// **'About BudgetBuddy'**
  String get aboutBudgetBuddy;

  /// No description provided for @versionMarketsLegal.
  ///
  /// In en, this message translates to:
  /// **'Version, markets, legal'**
  String get versionMarketsLegal;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'To Delete Your Account Permanently'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated'**
  String get budgetUpdated;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonth;

  /// No description provided for @tooHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high'**
  String get tooHigh;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @noSaving.
  ///
  /// In en, this message translates to:
  /// **'No Saving Goal Yet'**
  String get noSaving;

  /// No description provided for @createAGoal.
  ///
  /// In en, this message translates to:
  /// **'Create A Goal To Track Progress Towards A Target'**
  String get createAGoal;

  /// No description provided for @createMyFirst.
  ///
  /// In en, this message translates to:
  /// **'Create My First Goal'**
  String get createMyFirst;

  /// No description provided for @newSavingGoal.
  ///
  /// In en, this message translates to:
  /// **'New Saving Goal'**
  String get newSavingGoal;

  /// No description provided for @goalNam.
  ///
  /// In en, this message translates to:
  /// **'Goal name (e.g. New Phone)'**
  String get goalNam;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get targetAmount;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get createGoal;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get savingsRate;

  /// No description provided for @ofLimitUsed.
  ///
  /// In en, this message translates to:
  /// **'of limit used'**
  String get ofLimitUsed;

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get noBudgetSet;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @noIncomeLooged.
  ///
  /// In en, this message translates to:
  /// **'No income logged'**
  String get noIncomeLooged;

  /// No description provided for @ofIncomeCommitted.
  ///
  /// In en, this message translates to:
  /// **'of income committed'**
  String get ofIncomeCommitted;

  /// No description provided for @inBills.
  ///
  /// In en, this message translates to:
  /// **'in bills'**
  String get inBills;

  /// No description provided for @noActiveBills.
  ///
  /// In en, this message translates to:
  /// **'No active bills'**
  String get noActiveBills;

  /// No description provided for @noActiveGoals.
  ///
  /// In en, this message translates to:
  /// **'No active goals'**
  String get noActiveGoals;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get inProgress;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @commitments.
  ///
  /// In en, this message translates to:
  /// **'Commitments'**
  String get commitments;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @emiAndLoans.
  ///
  /// In en, this message translates to:
  /// **'EMI & Loans'**
  String get emiAndLoans;

  /// No description provided for @deleteBill.
  ///
  /// In en, this message translates to:
  /// **'Delete bill?'**
  String get deleteBill;

  /// No description provided for @deleteLoan.
  ///
  /// In en, this message translates to:
  /// **'Delete loan?'**
  String get deleteLoan;

  /// No description provided for @willBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'{title} will be removed.'**
  String willBeRemoved(Object title);

  /// No description provided for @yourLoans.
  ///
  /// In en, this message translates to:
  /// **'Your Loans'**
  String get yourLoans;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @monthlyEmis.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMIs'**
  String get monthlyEmis;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @noLoansYet.
  ///
  /// In en, this message translates to:
  /// **'No Loans Yet'**
  String get noLoansYet;

  /// No description provided for @noLoansDesc.
  ///
  /// In en, this message translates to:
  /// **'Track EMIs, monitor progress\nand get reminded before due dates.'**
  String get noLoansDesc;

  /// No description provided for @addFirstLoan.
  ///
  /// In en, this message translates to:
  /// **'Add First Loan'**
  String get addFirstLoan;

  /// No description provided for @addBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get addBillLabel;

  /// No description provided for @addLoan.
  ///
  /// In en, this message translates to:
  /// **'Add Loan'**
  String get addLoan;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @emiPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'{title} · EMI {amount}'**
  String emiPaymentHint(Object amount, Object title);

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @extraPartPayment.
  ///
  /// In en, this message translates to:
  /// **'Extra / Part Payment'**
  String get extraPartPayment;

  /// No description provided for @reducesPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Reduces principal balance'**
  String get reducesPrincipal;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @recordExtraPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Extra Payment'**
  String get recordExtraPayment;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @editLoan.
  ///
  /// In en, this message translates to:
  /// **'Edit Loan'**
  String get editLoan;

  /// No description provided for @addEmiLoan.
  ///
  /// In en, this message translates to:
  /// **'Add EMI / Loan'**
  String get addEmiLoan;

  /// No description provided for @loanNameHint.
  ///
  /// In en, this message translates to:
  /// **'Loan name (e.g. Home Loan, Car EMI)'**
  String get loanNameHint;

  /// No description provided for @lenderHint.
  ///
  /// In en, this message translates to:
  /// **'Lender / Bank name'**
  String get lenderHint;

  /// No description provided for @lenderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get lenderUnknown;

  /// No description provided for @principalAmount.
  ///
  /// In en, this message translates to:
  /// **'Principal Amount'**
  String get principalAmount;

  /// No description provided for @ratePerAnnum.
  ///
  /// In en, this message translates to:
  /// **'Rate % p.a.'**
  String get ratePerAnnum;

  /// No description provided for @tenureMonths.
  ///
  /// In en, this message translates to:
  /// **'Tenure (months)'**
  String get tenureMonths;

  /// No description provided for @autoCalcEmi.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculate EMI'**
  String get autoCalcEmi;

  /// No description provided for @autoCalcEmiSub.
  ///
  /// In en, this message translates to:
  /// **'From principal, rate & tenure'**
  String get autoCalcEmiSub;

  /// No description provided for @monthlyEmiAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI Amount'**
  String get monthlyEmiAmount;

  /// No description provided for @loanStarted.
  ///
  /// In en, this message translates to:
  /// **'Loan started:'**
  String get loanStarted;

  /// No description provided for @emiDueDay.
  ///
  /// In en, this message translates to:
  /// **'EMI Due Day'**
  String get emiDueDay;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @updateLoan.
  ///
  /// In en, this message translates to:
  /// **'Update Loan'**
  String get updateLoan;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ne', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'ne': return AppLocalizationsNe();
    case 'pt': return AppLocalizationsPt();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
