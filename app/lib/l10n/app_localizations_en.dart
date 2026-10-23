// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Doomread';

  @override
  String get navTonight => 'Tonight';

  @override
  String get navBooks => 'Books';

  @override
  String get navBuilding => 'Building';

  @override
  String get navFriends => 'Friends';

  @override
  String get tonightEmpty => 'Add the book you are reading';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get tonightAddBook => 'Add a book';

  @override
  String pageOf(int page, int total) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Page $pageString of $totalString';
  }

  @override
  String pagesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pages left',
      one: '1 page left',
    );
    return '$_temp0';
  }

  @override
  String nextCheckpoint(int page) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);

    return 'Next chapter ends on page $pageString';
  }

  @override
  String get booksEmpty => 'No books yet';

  @override
  String get readingNow => 'Reading now';

  @override
  String get editBook => 'Edit book';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldAuthor => 'Author';

  @override
  String get fieldPages => 'Total pages';

  @override
  String get fieldCheckpoints => 'Pages where chapters end (optional)';

  @override
  String get fieldCheckpointsHint => 'e.g. 34, 66, 98';

  @override
  String get problemNoTitle => 'Give it a title';

  @override
  String get problemNoPages => 'How many pages does it have?';

  @override
  String get problemCheckpointPastEnd =>
      'Chapter ends must be within the book\'s pages';

  @override
  String get save => 'Save';

  @override
  String get account => 'Account';

  @override
  String get accountSignedOutHint =>
      'An account keeps your reading on all your devices. The app works fully without one.';

  @override
  String get accountUsername => 'Username';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignUp => 'Create account';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountSignedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get accountErrorUsername =>
      'Use 3 to 32 lowercase letters, digits, _ or .';

  @override
  String get accountErrorPassword => 'Use at least 8 characters.';

  @override
  String get accountErrorTaken => 'That username is taken.';

  @override
  String get accountErrorWrong => 'Wrong username or password.';

  @override
  String get accountErrorRejected =>
      'The server didn\'t accept that. Try again.';

  @override
  String get accountErrorUnreachable =>
      'Can\'t reach the server. Everything else still works; try again later.';

  @override
  String get changeBook => 'Change book';
}
