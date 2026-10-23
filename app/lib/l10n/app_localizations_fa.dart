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

  @override
  String get account => 'حساب کاربری';

  @override
  String get accountSignedOutHint =>
      'با حساب کاربری، کتاب‌خوندنت روی همه‌ی دستگاه‌هات باهاته. بدون حساب هم برنامه کامل کار می‌کنه.';

  @override
  String get accountUsername => 'نام کاربری';

  @override
  String get accountPassword => 'رمز';

  @override
  String get accountSignIn => 'ورود';

  @override
  String get accountSignUp => 'ثبت‌نام';

  @override
  String get accountSignOut => 'خروج';

  @override
  String accountSignedInAs(String username) {
    return 'با $username وارد شدی';
  }

  @override
  String get accountErrorUsername =>
      'نام کاربری باید ۳ تا ۳۲ حرف کوچیک انگلیسی، عدد، _ یا . باشه.';

  @override
  String get accountErrorPassword => 'رمز حداقل ۸ تا کاراکتر باشه.';

  @override
  String get accountErrorTaken => 'این نام کاربری قبلاً گرفته شده.';

  @override
  String get accountErrorWrong => 'نام کاربری یا رمز اشتباهه.';

  @override
  String get accountErrorTooMany =>
      'زیادی پشت سر هم امتحان کردی. چند دقیقه صبر کن، بعد دوباره امتحان کن.';

  @override
  String get accountErrorRejected => 'سرور قبولش نکرد. دوباره امتحان کن.';

  @override
  String get accountErrorUnreachable =>
      'به سرور وصل نمی‌شه. بقیهٔ برنامه کار می‌کنه؛ بعداً دوباره امتحان کن.';

  @override
  String get changeBook => 'عوض کردن کتاب';

  @override
  String get startReading => 'شروع خوندن';

  @override
  String get backToReading => 'برگرد سراغ خوندن';

  @override
  String aim(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'هدف: $minutesString دقیقه یه‌سره.';
  }

  @override
  String eveningsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'با سرعت خودت، حدوداً $countString شب دیگه.';
  }

  @override
  String aimToGo(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString دقیقه‌ی دیگه.';
  }

  @override
  String get aimReached => 'به هدفت رسیدی. این طولانی‌ترین تمرکزت تا حالاست.';

  @override
  String get paused => 'مکث کردی. عجله نکن، این به حسابت نمیاد.';

  @override
  String get faceDown => 'گوشی رو برگردون رو به پایین.';

  @override
  String get pause => 'مکث';

  @override
  String get resume => 'ادامه';

  @override
  String get stopForTonight => 'برای امشب بسه';

  @override
  String get newBestStretch => 'بهترین تمرکزت تا حالا';

  @override
  String inOneGoTonight(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'امشب $minutesString دقیقه یه‌سره خوندی.',
      zero: 'امشب کمتر از یه دقیقه یه‌سره خوندی.',
    );
    return '$_temp0';
  }

  @override
  String get whichPage => 'تا کدوم صفحه خوندی؟';

  @override
  String ofStartedAt(int total, int from) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'از $totalString، از صفحه‌ی $fromString شروع کردی';
  }

  @override
  String get whatHappened => 'تو یه جمله، چی شد؟';

  @override
  String get saveAndLightsOut => 'ذخیره کن و چراغ رو خاموش کن';

  @override
  String get problemNoPage => 'کدوم صفحه؟ فقط عددش رو بنویس.';

  @override
  String problemPageOutOfRange(int from, int total) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'یه صفحه از $fromString تا $totalString';
  }

  @override
  String get readingWeekTitle => 'این هفته';

  @override
  String readingWeekCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تا الان $countString شب خوندی',
      zero: 'یه هفته‌ی تازه',
    );
    return '$_temp0';
  }

  @override
  String stretchTrendGrew(int from, int to) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return 'طولانی‌ترین تمرکزت از $fromString دقیقه رسیده به $toString دقیقه.';
  }

  @override
  String stretchTrendSoFar(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'طولانی‌ترین تمرکزت تا الان $minutesString دقیقه‌ست.',
      zero: 'طولانی‌ترین تمرکزت تا الان کمتر از یه دقیقه‌ست.',
    );
    return '$_temp0';
  }

  @override
  String get stretchTrendEmpty =>
      'یه بار بخون، طولانی‌ترین تمرکزت اینجا نشون داده می‌شه.';

  @override
  String stretchTrendDates(String from, String to) {
    return 'از $from تا $to.';
  }

  @override
  String get notificationAskTitle => 'تایمر رو صفحه‌ی قفل هم باشه؟';

  @override
  String get notificationAskBody =>
      'وقتی داری می‌خونی، یه نوتیفیکیشن بی‌صدا تایمر و کتابت رو نشون می‌ده. وقتی تموم کنی خودش می‌ره، و کار دیگه‌ای هم باهاش نداریم.';

  @override
  String get notificationAskAllow => 'باشه';

  @override
  String get notificationAskNotNow => 'الان نه';

  @override
  String notificationPaused(String time) {
    return 'رو $time مکث کردی';
  }

  @override
  String get buildingTitle => 'ساختمون تو';

  @override
  String get buildingSub => 'هر کتابی که تموم کنی، یه طبقه.';

  @override
  String get buildingEmpty =>
      'هنوز طبقه‌ای نداره. یه کتاب رو تموم کن تا اولین طبقه روشن شه.';

  @override
  String floorDetails(int pages, int evenings) {
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$pagesString صفحه، $eveningsString شب';
  }

  @override
  String finishedTitle(String title) {
    return '«$title» رو تموم کردی.';
  }

  @override
  String finishedSub(int pages, int evenings) {
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$pagesString صفحه توی $eveningsString شب. ساختمونت یه طبقه بلندتر شد.';
  }

  @override
  String minutesShort(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString دقیقه';
  }

  @override
  String get longestStretchLabel => 'طولانی‌ترین تمرکز';

  @override
  String notesWritten(int count) {
    return 'یادداشت';
  }

  @override
  String get readTheStory => 'داستان رو به زبون خودت بخون';

  @override
  String get seeYourBuilding => 'ساختمونت رو ببین';

  @override
  String get storySoFar => 'داستان تا اینجا، به زبون خودت';

  @override
  String get storyEmpty =>
      'بعد از هر شب، جمله‌ای که درباره‌ش می‌نویسی اینجا میاد.';

  @override
  String get bookFinished => 'تمومش کردی، تا صفحه‌ی آخر.';

  @override
  String pageRange(int from, int to) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return 'ص $fromString تا $toString';
  }

  @override
  String nextBreakAtCheckpoint(int chapter, int minutes) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'استراحتت: آخر فصل $chapterString، حدوداً $minutesString دقیقه‌ی دیگه.';
  }

  @override
  String nextBreakAtPage(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'استراحتت: حدوداً $minutesString دقیقه‌ی دیگه، آخر همون صفحه‌ای که هستی.';
  }

  @override
  String breakDueAtCheckpoint(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'آخر فصل $chapterString وقت استراحته.';
  }

  @override
  String get breakDueAtPage => 'وقت استراحته. این صفحه رو تموم کن.';

  @override
  String get takeBreak => 'رسیدم';

  @override
  String get nudgeBreak => 'بعداً';

  @override
  String onBreakUntil(String time) {
    return 'تا $time استراحتی.';
  }

  @override
  String get showBreak => 'تایمر رو نشون بده';

  @override
  String chapterDone(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'فصل $chapterString تموم شد';
  }

  @override
  String get breakHere => 'وقت استراحتت رسید.';

  @override
  String breakAnything(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString دقیقه ریلز، پیام، هر چی دلت خواست.';
  }

  @override
  String backToChapterAt(int chapter, String time) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'ساعت $time برمی‌گردیم سراغ فصل $chapterString.';
  }

  @override
  String backToBookAt(String time) {
    return 'ساعت $time برمی‌گردیم سراغ کتاب.';
  }

  @override
  String bestTonight(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'بهترین تمرکز امشبت $minutesString دقیقه بوده.',
      zero: 'بهترین تمرکز امشبت هنوز زیر یه دقیقه‌ست.',
    );
    return '$_temp0';
  }

  @override
  String startMyBreak(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString دقیقه‌م رو شروع کن';
  }

  @override
  String get keepReading => 'نه، ادامه می‌دم';

  @override
  String get onBreak => 'داری استراحت می‌کنی.';

  @override
  String get imBack => 'برگشتم';

  @override
  String get breakOver => 'استراحت تموم شد.';

  @override
  String chapterWaiting(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'فصل $chapterString منتظرته.';
  }

  @override
  String workWaiting(String title) {
    return '«$title» منتظرته.';
  }
}
