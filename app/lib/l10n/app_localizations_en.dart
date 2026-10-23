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
  String get accountErrorTooMany =>
      'Too many tries. Wait a few minutes, then try again.';

  @override
  String get accountErrorRejected =>
      'The server didn\'t accept that. Try again.';

  @override
  String get accountErrorUnreachable =>
      'Can\'t reach the server. Everything else still works; try again later.';

  @override
  String get changeBook => 'Change book';

  @override
  String get startReading => 'Start reading';

  @override
  String get backToReading => 'Back to reading';

  @override
  String aim(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Aim: $minutesString minutes in one go.',
      one: 'Aim: 1 minute in one go.',
    );
    return '$_temp0';
  }

  @override
  String eveningsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At your pace, about $countString evenings left.',
      one: 'At your pace, about 1 evening left.',
    );
    return '$_temp0';
  }

  @override
  String aimToGo(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString minutes to go.',
      one: '1 minute to go.',
    );
    return '$_temp0';
  }

  @override
  String get aimReached => 'Aim reached. This is your longest stretch yet.';

  @override
  String get paused => 'Paused. Take your time, it doesn\'t count against you.';

  @override
  String get faceDown => 'Turn the phone face down.';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stopForTonight => 'Stop for tonight';

  @override
  String get newBestStretch => 'New best stretch';

  @override
  String inOneGoTonight(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString minutes in one go tonight.',
      one: '1 minute in one go tonight.',
      zero: 'Under a minute in one go tonight.',
    );
    return '$_temp0';
  }

  @override
  String get whichPage => 'Which page did you stop at?';

  @override
  String ofStartedAt(int total, int from) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'of $totalString, started at $fromString';
  }

  @override
  String get whatHappened => 'In a sentence, what happened?';

  @override
  String get saveAndLightsOut => 'Save and turn off the light';

  @override
  String get problemNoPage => 'Which page? Just the number.';

  @override
  String problemPageOutOfRange(int from, int total) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'A page from $fromString to $totalString';
  }
}
