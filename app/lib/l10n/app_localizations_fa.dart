// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'باز گوشی؟!';

  @override
  String get navTonight => 'امشب';

  @override
  String get navBooks => 'کتاب‌ها';

  @override
  String get navBuilding => 'ساختمون';

  @override
  String get navFriends => 'دوستا';

  @override
  String get tonightEmpty => 'کتابی که داری می‌خونی رو اضافه کن';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get tonightAddBook => 'یه کتاب اضافه کن';

  @override
  String pageOf(int page, int total) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'صفحه‌ی $pageString از $totalString';
  }

  @override
  String pagesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString صفحه مونده';
  }

  @override
  String nextCheckpoint(int page) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);

    return 'فصل بعدی صفحه‌ی $pageString تموم می‌شه';
  }

  @override
  String get booksEmpty => 'هنوز کتابی نداری';

  @override
  String get readingNow => 'در حال خوندن';

  @override
  String get editBook => 'ویرایش کتاب';

  @override
  String get fieldTitle => 'عنوان';

  @override
  String get fieldAuthor => 'نویسنده';

  @override
  String get fieldPages => 'تعداد صفحه‌ها';

  @override
  String get fieldCheckpoints => 'صفحه‌هایی که فصل‌ها تموم می‌شن (اختیاری)';

  @override
  String get fieldCheckpointsHint => 'مثلاً ۳۴، ۶۶، ۹۸';

  @override
  String get problemNoTitle => 'یه عنوان بنویس';

  @override
  String get problemNoPages => 'چند صفحه‌ست؟';

  @override
  String get problemCheckpointPastEnd =>
      'پایان فصل‌ها باید توی صفحه‌های کتاب باشه';

  @override
  String get save => 'ذخیره';
}
