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
  String get houseEmpty =>
      'فعلاً فقط چراغ تو روشنه. هر شب که بخونی، یه چراغ دیگه هم روشن می‌شه.';

  @override
  String get houseYours =>
      'بقیه‌ی چراغ‌های اینجا هم مال خودتن، از شب‌هایی که خوندی.';

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

  @override
  String widgetEvenings(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'حدوداً $countString شب دیگه مونده';
  }

  @override
  String get widgetLit => 'امشب پنجره‌ت روشنه';

  @override
  String get widgetDark => 'امشب پنجره‌ت هنوز خاموشه';

  @override
  String get kindPaperBook => 'کتاب';

  @override
  String get kindEbook => 'ای‌بوک';

  @override
  String get kindSeries => 'سریال';

  @override
  String get kindFilm => 'فیلم';

  @override
  String get kindPodcast => 'پادکست';

  @override
  String get fieldCreator => 'سازنده';

  @override
  String get fieldEpisodes => 'تعداد قسمت‌ها';

  @override
  String get fieldDuration => 'مدتش';

  @override
  String get fieldDurationHint => 'مثلاً ۲:۴۱:۰۰';

  @override
  String get fieldTimestamps => 'جاهایی که هر بخش تموم می‌شه (اختیاری)';

  @override
  String get fieldTimestampsHint => 'مثلاً ۴۲:۳۰، ۱:۱۵:۰۰';

  @override
  String get problemNoEpisodes => 'چند قسمته؟';

  @override
  String get problemNoDuration => 'چقدر طول می‌کشه؟ مثلاً ۲:۴۱:۰۰';

  @override
  String get problemTimestampPastEnd => 'زمان‌ها باید توی مدتش باشن';

  @override
  String episodeOf(int episode, int total) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'قسمت $episodeString از $totalString';
  }

  @override
  String timeOf(String time, String total) {
    return '$time از $total';
  }

  @override
  String episodesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString قسمت مونده';
  }

  @override
  String timeLeft(String time) {
    return '$time مونده';
  }

  @override
  String nextEpisode(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'قسمت بعدی: $episodeString';
  }

  @override
  String nextTimestamp(String time) {
    return 'بخش بعدی $time تموم می‌شه';
  }

  @override
  String startWork(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'شروع دیدن',
      'film': 'شروع دیدن',
      'podcast': 'شروع گوش دادن',
      'other': 'شروع خوندن',
    });
    return '$_temp0';
  }

  @override
  String backToWork(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'برگرد سراغ دیدن',
      'film': 'برگرد سراغ دیدن',
      'podcast': 'برگرد سراغ گوش دادن',
      'other': 'برگرد سراغ خوندن',
    });
    return '$_temp0';
  }

  @override
  String workNow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'در حال دیدن',
      'film': 'در حال دیدن',
      'podcast': 'در حال گوش دادن',
      'other': 'در حال خوندن',
    });
    return '$_temp0';
  }

  @override
  String get whichEpisode => 'تا کدوم قسمت دیدی؟';

  @override
  String get whereStopped => 'تا کجاش رفتی؟';

  @override
  String ofStartedAtTime(String total, String from) {
    return 'از $total، از $from شروع کردی';
  }

  @override
  String get problemNoEpisode => 'کدوم قسمت؟ فقط عددش رو بنویس.';

  @override
  String get problemNoTime => 'کجاش؟ مثلاً ۱:۱۲:۲۰';

  @override
  String problemEpisodeOutOfRange(int from, int total) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'یه قسمت از $fromString تا $totalString';
  }

  @override
  String problemTimeOutOfRange(String from, String total) {
    return 'یه زمان از $from تا $total';
  }

  @override
  String episodeRange(int from, int to) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return 'قسمت $fromString تا $toString';
  }

  @override
  String timeRange(String from, String to) {
    return '$from تا $to';
  }

  @override
  String finishedSubEpisodes(int episodes, int evenings) {
    final intl.NumberFormat episodesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodesString = episodesNumberFormat.format(episodes);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$episodesString قسمت توی $eveningsString شب. ساختمونت یه طبقه بلندتر شد.';
  }

  @override
  String finishedSubTime(String time, int evenings) {
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$time توی $eveningsString شب. ساختمونت یه طبقه بلندتر شد.';
  }

  @override
  String floorDetailsEpisodes(int episodes, int evenings) {
    final intl.NumberFormat episodesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodesString = episodesNumberFormat.format(episodes);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$episodesString قسمت، $eveningsString شب';
  }

  @override
  String floorDetailsTime(String time, int evenings) {
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$time، $eveningsString شب';
  }

  @override
  String get watchedFinished => 'تمومش کردی، تا آخرش.';

  @override
  String get trendReading => 'خوندن';

  @override
  String get trendWatching => 'دیدن';

  @override
  String ofStartedAtEpisode(int total, int from) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'از $totalString، از قسمت $fromString شروع کردی';
  }

  @override
  String inOneGoTonightWatched(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'امشب $minutesString دقیقه یه‌سره پاش نشستی.',
      zero: 'امشب کمتر از یه دقیقه یه‌سره پاش نشستی.',
    );
    return '$_temp0';
  }

  @override
  String nextBreakAtEpisode(int episode, int minutes) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'استراحتت: آخر قسمت $episodeString، حدوداً $minutesString دقیقه‌ی دیگه.';
  }

  @override
  String breakDueAtEpisode(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'آخر قسمت $episodeString وقت استراحته.';
  }

  @override
  String nextBreakAtTimestamp(String timestamp, int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'استراحتت: سر $timestamp، حدوداً $minutesString دقیقه‌ی دیگه.';
  }

  @override
  String breakDueAtTimestamp(String timestamp) {
    return 'سر $timestamp وقت استراحته.';
  }

  @override
  String nextBreakWatching(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'استراحتت: حدوداً $minutesString دقیقه‌ی دیگه، هر وقت این تیکه تموم شد.';
  }

  @override
  String get breakDueWatching => 'وقت استراحته. این تیکه که تموم شد، نگهش دار.';

  @override
  String episodeDone(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'قسمت $episodeString تموم شد';
  }

  @override
  String episodeWaiting(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'قسمت $episodeString منتظرته.';
  }

  @override
  String backToEpisodeAt(int episode, String time) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'ساعت $time برمی‌گردیم سراغ قسمت $episodeString.';
  }

  @override
  String backToWorkAt(String time) {
    return 'ساعت $time برمی‌گردیم سراغش.';
  }

  @override
  String get keepGoing => 'نه، ادامه می‌دم';

  @override
  String urgeTitle(String app) {
    return 'هنوز نه! $app تا استراحتت صبر می‌کنه.';
  }

  @override
  String get urgeBody => 'خودت قرار این استراحت رو گذاشتی، یادته؟';

  @override
  String get backToBook => 'باشه، برمی‌گردم سر کتاب';

  @override
  String openAnyway(String app) {
    return 'نه، $app رو باز کن';
  }

  @override
  String get openItAnyway => 'نه، بازش کن';

  @override
  String get slipTitle => 'اشکال نداره، برگرد.';

  @override
  String slipBody(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString دقیقه پشت هم جلو رفته بودی. ادامه بدیم؟';
  }

  @override
  String get backIn => 'برمی‌گردم';

  @override
  String get doneForTonight => 'بسه برای امشب';

  @override
  String get watchedApps => 'اپ‌های زیر نظر';

  @override
  String get watchedAppsHint =>
      'اگه وسط خوندن یکی از اینا رو باز کنی، صفحه‌ی «هنوز نه» میاد. بیرون از خوندن، و وسط استراحتت، هیچ اتفاقی نمی‌افته.';

  @override
  String get watchOff => 'صفحه‌ی «هنوز نه» خاموشه.';

  @override
  String get watchTurnOn => 'روشنش کن';

  @override
  String get watchAskTitle => 'باز گوشی؟! از دسترس‌پذیری استفاده می‌کنه';

  @override
  String get watchAskBody =>
      'برای این‌که صفحه‌ی «هنوز نه» بیاد، باز گوشی؟! از سرویس دسترس‌پذیری (Accessibility) اندروید استفاده می‌کنه تا بفهمه وسط خوندن کدوم اپ رو باز کردی. فقط می‌بینه کدوم اپ جلوئه. هیچ‌وقت چیزی که رو صفحه‌ست یا چیزی که تایپ می‌کنی رو نمی‌خونه. هیچ‌کدوم از اینا از گوشیت بیرون نمی‌ره و با هیچ‌کس هم به اشتراک گذاشته نمی‌شه.\n\nهر وقت بخوای می‌تونی از تنظیمات خاموشش کنی. باز گوشی؟! هیچ‌وقت جلوی خاموش کردنش یا پاک کردن هیچ اپی رو نمی‌گیره.';

  @override
  String get watchAskAgree => 'قبوله، روشنش کن';

  @override
  String get watchAskNotNow => 'الان نه';

  @override
  String get urgeTitleAnyApp => 'هنوز نه! بذارش برای استراحتت.';

  @override
  String get watchRestricted =>
      'اگه اندروید گفت تنظیمات محدودشده‌ست: «اطلاعات برنامه»ی باز گوشی؟! رو باز کن، منوی سه‌نقطه رو بزن، بعد «اجازه دادن به تنظیمات محدودشده»، و دوباره امتحان کن.';
}
