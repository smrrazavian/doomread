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
}
