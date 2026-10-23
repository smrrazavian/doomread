import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Doomread'**
  String get appTitle;

  /// No description provided for @navTonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get navTonight;

  /// No description provided for @navBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get navBooks;

  /// No description provided for @navBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get navBuilding;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @tonightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add the book you are reading'**
  String get tonightEmpty;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @tonightAddBook.
  ///
  /// In en, this message translates to:
  /// **'Add a book'**
  String get tonightAddBook;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @pagesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page left} other{{count} pages left}}'**
  String pagesLeft(int count);

  /// No description provided for @nextCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Next chapter ends on page {page}'**
  String nextCheckpoint(int page);

  /// No description provided for @booksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get booksEmpty;

  /// No description provided for @readingNow.
  ///
  /// In en, this message translates to:
  /// **'Reading now'**
  String get readingNow;

  /// No description provided for @editBook.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get editBook;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get fieldAuthor;

  /// No description provided for @fieldPages.
  ///
  /// In en, this message translates to:
  /// **'Total pages'**
  String get fieldPages;

  /// No description provided for @fieldCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'Pages where chapters end (optional)'**
  String get fieldCheckpoints;

  /// No description provided for @fieldCheckpointsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 34, 66, 98'**
  String get fieldCheckpointsHint;

  /// No description provided for @problemNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Give it a title'**
  String get problemNoTitle;

  /// No description provided for @problemNoPages.
  ///
  /// In en, this message translates to:
  /// **'How many pages does it have?'**
  String get problemNoPages;

  /// No description provided for @problemCheckpointPastEnd.
  ///
  /// In en, this message translates to:
  /// **'Chapter ends must be within the book\'s pages'**
  String get problemCheckpointPastEnd;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountSignedOutHint.
  ///
  /// In en, this message translates to:
  /// **'An account keeps your reading on all your devices. The app works fully without one.'**
  String get accountSignedOutHint;

  /// No description provided for @accountUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountUsername;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountSignUp;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}'**
  String accountSignedInAs(String username);

  /// No description provided for @accountErrorUsername.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 32 lowercase letters, digits, _ or .'**
  String get accountErrorUsername;

  /// No description provided for @accountErrorPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get accountErrorPassword;

  /// No description provided for @accountErrorTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken.'**
  String get accountErrorTaken;

  /// No description provided for @accountErrorWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get accountErrorWrong;

  /// No description provided for @accountErrorRejected.
  ///
  /// In en, this message translates to:
  /// **'The server didn\'t accept that. Try again.'**
  String get accountErrorRejected;

  /// No description provided for @accountErrorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Everything else still works; try again later.'**
  String get accountErrorUnreachable;

  /// No description provided for @changeBook.
  ///
  /// In en, this message translates to:
  /// **'Change book'**
  String get changeBook;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
