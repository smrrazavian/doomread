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
  String get navBooks => 'قفسه';

  @override
  String get navBuilding => 'ساختمون';

  @override
  String get navFriends => 'دوستا';

  @override
  String get tonightEmpty =>
      'چیزی که داری می‌خونی، می‌بینی یا گوش می‌دی رو اضافه کن';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get tonightAddBook => 'یه چیز اضافه کن';

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
  String get readingNow => 'در حال خوندن';

  @override
  String get editBook => 'ویرایش';

  @override
  String get deleteWork => 'حذف';

  @override
  String workDeleted(String title) {
    return '«$title» حذف شد';
  }

  @override
  String get undo => 'برگردون';

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
      'با حساب کاربری، قفسه‌ت روی همه‌ی دستگاه‌هات باهاته. بدون حساب هم برنامه کامل کار می‌کنه.';

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
  String get changeBook => 'یه چیز دیگه';

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
      other: 'تا الان $countString شب نشستی پاش',
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
      'یه بار بشین پاش، طولانی‌ترین تمرکزت اینجا نشون داده می‌شه.';

  @override
  String stretchTrendDates(String from, String to) {
    return 'از $from تا $to.';
  }

  @override
  String get notificationAskTitle => 'تایمر رو صفحه‌ی قفل هم باشه؟';

  @override
  String get notificationAskBody =>
      'وقتی مشغولی، یه نوتیفیکیشن بی‌صدا تایمر و چیزی که داری تمومش می‌کنی رو نشون می‌ده. وقتی تموم کنی خودش می‌ره، و کار دیگه‌ای هم باهاش نداریم.';

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
  String get buildingSub => 'هر چیزی که تموم کنی، یه طبقه.';

  @override
  String get buildingEmpty =>
      'هنوز طبقه‌ای نداره. یه چیزی رو تموم کن تا اولین طبقه روشن شه.';

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
      'فعلاً فقط چراغ تو روشنه. هر شب که بشینی پاش، یه چراغ دیگه هم روشن می‌شه.';

  @override
  String get houseYours =>
      'بقیه‌ی چراغ‌های اینجا هم مال خودتن، از شب‌هایی که نشستی پاش.';

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
  String get onBreak => 'داری استراحت می‌کنی.';

  @override
  String get imBack => 'برگشتم';

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
      'برای این‌که صفحه‌ی «هنوز نه» بیاد، باز گوشی؟! از سرویس دسترس‌پذیری (Accessibility) اندروید استفاده می‌کنه تا بفهمه وسط خوندن کدوم اپ رو باز کردی. می‌بینه کدوم اپ جلوئه، و اگه امشب از یوتیوب می‌خونی یا می‌بینی، از نوع صفحه می‌فهمه شورتز بازه یا نه. هیچ‌وقت متن روی صفحه یا چیزی که تایپ می‌کنی رو نمی‌خونه. هیچ‌کدوم از اینا از گوشیت بیرون نمی‌ره و با هیچ‌کس هم به اشتراک گذاشته نمی‌شه.\n\nهر وقت بخوای می‌تونی از تنظیمات خاموشش کنی. باز گوشی؟! هیچ‌وقت جلوی خاموش کردنش یا پاک کردن هیچ اپی رو نمی‌گیره.';

  @override
  String get watchAskAgree => 'قبوله، روشنش کن';

  @override
  String get watchAskNotNow => 'الان نه';

  @override
  String get watchRestricted =>
      'اگه اندروید گفت تنظیمات محدودشده‌ست: «اطلاعات برنامه»ی باز گوشی؟! رو باز کن، منوی سه‌نقطه رو بزن، بعد «اجازه دادن به تنظیمات محدودشده»، و دوباره امتحان کن.';

  @override
  String get workAppNone => 'روی گوشی نیست';

  @override
  String get workAppPick => 'امشب کجاست؟';

  @override
  String get workAppHint =>
      'رفتن به اپش هیچ‌وقت صفحه‌ی «هنوز نه» رو نمیاره. توی یوتیوب فقط شورتز میارتش.';

  @override
  String workAppReading(String app) {
    return 'امشب با $app؛ رفتن بهش اشکالی نداره.';
  }

  @override
  String get openWorkApp => 'باز کن';

  @override
  String get workAppAsk => 'روی گوشیه؟';

  @override
  String get watchViaAccessibility => 'با دسترس‌پذیری';

  @override
  String get watchViaUsage => 'با دسترسی به داده‌های استفاده';

  @override
  String get watchViaNone => 'خاموش';

  @override
  String get watchOnUsage =>
      'روشنه، با دسترسی به داده‌های استفاده. ممکنه یکی دو ثانیه طول بکشه، و شورتز رو از بقیه‌ی یوتیوب تشخیص نمی‌ده.';

  @override
  String get watchFallback =>
      'نمی‌تونی دسترس‌پذیری رو روشن کنی، مثلاً چون «محافظت پیشرفته» روشنه؟ با دسترسی به داده‌های استفاده هم کار می‌کنه، فقط یکی دو ثانیه کندتر. دو تا اجازه لازم داره: دسترسی به داده‌های استفاده، و نمایش روی برنامه‌های دیگه، که صفحه‌ی «هنوز نه» بتونه بیاد.';

  @override
  String get watchAllowUsage => 'اجازه‌ی دسترسی به داده‌های استفاده';

  @override
  String get watchAllowOverlay => 'اجازه‌ی نمایش روی برنامه‌های دیگه';

  @override
  String get tone => 'لحن';

  @override
  String get toneChill => 'ریلکس';

  @override
  String get toneSpicy => 'تند و تیز';

  @override
  String get toneMom => 'مامان‌مود';

  @override
  String get toneHint =>
      'هر کدوم رو انتخاب کنی، وسوسه رو مسخره می‌کنه نه خودتو، و وقتی کم آوردی همیشه مهربونه.';

  @override
  String get checkpointsFormatPages =>
      'پایان فصل‌ها شماره‌ی صفحه‌ست و با ویرگول جدا می‌شن، مثلاً ۳۴، ۶۶، ۹۸';

  @override
  String get checkpointsFormatTimestamps =>
      'پایان بخش‌ها زمانه و با ویرگول جدا می‌شن، مثلاً ۴۲:۳۰، ۱:۱۵:۰۰';

  @override
  String breakCardStart(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'شروع استراحت ($minutesString دقیقه)';
  }

  @override
  String eveningOfTotal(String total) {
    return 'از $total';
  }

  @override
  String eveningStartedAtPage(int from) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'امشب از صفحه‌ی $fromString شروع کردی';
  }

  @override
  String eveningStartedAtEpisode(int from) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'امشب از قسمت $fromString شروع کردی';
  }

  @override
  String eveningStartedAtTime(String from) {
    return 'امشب از $from شروع کردی';
  }

  @override
  String get eveningFinished => 'تمومش کردم!';

  @override
  String whereIsElsewhere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'paperBook': 'کاغذی',
      'other': 'جای دیگه',
    });
    return '$_temp0';
  }

  @override
  String get whereIsPhone => 'همین گوشی';

  @override
  String get whereIsSearch => 'دنبال اپ بگرد';

  @override
  String get emptyTonight =>
      'امشب هنوز همه‌ی پنجره‌ها خاموشن. تو اولین چراغو روشن کن.';

  @override
  String get emptyLibrary =>
      'قفسه خالیه، ولی چراغش روشنه. اون کتاب یا سریال یا پادکستی که هی می‌گی تمومش می‌کنم رو اضافه کن.';

  @override
  String get emptyStory =>
      'فعلاً صفحه سفیده. بعد هر شب یه خط بنویس، داستانت همین‌جا کم‌کم شکل می‌گیره.';

  @override
  String get shareAction => 'پزش رو بده';

  @override
  String get sharePreviewTitle => 'پوسترت';

  @override
  String get shareShowNote => 'یادداشتم هم باشه';

  @override
  String get shareShowNoteHint =>
      'آخرین یادداشتت، همون‌جوری که نوشتی. خاموشش کنی، فقط مال خودت می‌مونه.';

  @override
  String get shareSend => 'بفرست';

  @override
  String get shareSendTo => 'بفرست برای';

  @override
  String shareSavedTo(String path) {
    return 'ذخیره شد توی $path';
  }

  @override
  String get shareFailed => 'نشد بفرستیمش. دوباره امتحان می‌کنی؟';

  @override
  String get sharePosterFinished => 'تمومش کردم';

  @override
  String sharePosterTitle(String title) {
    return '«$title»';
  }

  @override
  String sharePosterPages(int pages, int evenings) {
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$pagesString صفحه توی $eveningsString شب';
  }

  @override
  String sharePosterEpisodes(int episodes, int evenings) {
    final intl.NumberFormat episodesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodesString = episodesNumberFormat.format(episodes);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$episodesString قسمت توی $eveningsString شب';
  }

  @override
  String sharePosterTime(String time, int evenings) {
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    return '$time توی $eveningsString شب';
  }

  @override
  String sharePosterUrges(int count) {
    return 'بار وسوسه رو رد کردم';
  }

  @override
  String get tourSkip => 'رد کن';

  @override
  String get tourLater => 'بعداً';

  @override
  String get tourStoryTitle =>
      'تا حالا یه فیلم دو ساعت و نیمه رو با رفیقات دیدی و دستت نرفته سمت گوشی؟';

  @override
  String get tourStoryBody =>
      'وسوسه اومد، ولی محلش ندادی؛ چون بقیه هم داشتن نگاه می‌کردن.';

  @override
  String get tourStoryNext => 'آره، دقیقاً';

  @override
  String get tourCompanyTitle =>
      'تنهایی، وسوسه می‌بره. ما اون جمع رو برمی‌گردونیم.';

  @override
  String get tourCompanyBody =>
      'پنجره‌ی روشن بقیه، یه استراحت که از قبل معلومه، و ته کتاب که جلوی چشمته.';

  @override
  String get tourCompanyNext => 'پایه‌ام';

  @override
  String get tourToneTitle => 'بگو چه‌جوری باهات حرف بزنم';

  @override
  String get tourToneBody =>
      'وسط فصل، اینستاگرام صدات می‌کنه. این سه‌جور جوابیه که می‌دم. هر کدوم رو دوست داری بزن.';

  @override
  String get tourToneNext => 'همینه';

  @override
  String get tourToneLater => 'هر وقت خواستی از تنظیمات عوضش کن.';

  @override
  String get tourWorkTitle => 'چی رو می‌خوای تموم کنی؟';

  @override
  String get tourWorkBody => 'فقط اسمش و این‌که چقدره. فصل‌ها بمونه برای بعد.';

  @override
  String get tourGotIt => 'فهمیدم';

  @override
  String tourAimHint(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString دقیقه. رکوردت به‌علاوه‌ی یکی. بزنیش، بیشتر می‌شه.',
    );
    return '$_temp0';
  }

  @override
  String get tourDemoAsk =>
      'می‌خوای ببینی وقتی اینستاگرام صدات می‌کنه چی می‌شه؟';

  @override
  String get tourDemoShow => 'نشونم بده';

  @override
  String get tourNotNow => 'الان نه';

  @override
  String get tourDemoBadge => 'فقط نمایشیه. چیزی ثبت نمی‌شه.';

  @override
  String get tourUrgeHint =>
      'این صفحه‌ی «هنوز نه»ـه. برگشتن یعنی بردی، باز کردنش هم همیشه آزاده.';

  @override
  String get tourBreakHint =>
      'این استراحت یعنی ریلز قانونی. بی‌عذاب وجدان بچرخ، بعد برگرد.';

  @override
  String get tourWatchAsk =>
      'می‌خوای وقتی اینستاگرام واقعاً صدات کرد، صفحه‌ی «هنوز نه» بیاد؟';

  @override
  String get tourWatchTurnOn => 'روشنش کن';

  @override
  String get tourWatchOn => 'صفحه‌ی «هنوز نه» روشنه.';

  @override
  String get tourWatchOff =>
      'هنوز خاموشه. اشکال نداره؛ توی دسترس‌پذیری، باز گوشی؟! رو پیدا کن و روشنش کن.';

  @override
  String get tourWatchRetry => 'دوباره';

  @override
  String get tourReplay => 'دوباره دیدن معرفی';

  @override
  String get cardShareTonight => 'پز امشبو بده';

  @override
  String get cardReceiptHeading => 'رسید امشب';

  @override
  String cardReceiptWhen(String date, String from, String to) {
    return '$date، $from تا $to';
  }

  @override
  String get cardReceiptPages => 'صفحه‌ها';

  @override
  String get cardReceiptEpisodes => 'قسمت‌ها';

  @override
  String get cardReceiptTime => 'جلو رفتم';

  @override
  String get cardReceiptLongest => 'یه‌سره';

  @override
  String get cardReceiptUrges => 'وسوسه‌هایی که رد کردم';

  @override
  String get cardReceiptBreaks => 'استراحت قانونی';

  @override
  String cardReceiptSlips(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString بار حواسم پرت شد، برگشتم',
      one: 'یه بار حواسم پرت شد، برگشتم',
    );
    return '$_temp0';
  }

  @override
  String get cardReceiptTotal => 'جمع کل';

  @override
  String get cardGlowUpAction => 'گلوآپتو نشون بده';

  @override
  String get cardGlowUpHeading => 'گلوآپ تمرکزم';

  @override
  String cardGlowUpWhat(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'watching': 'طولانی‌ترین تمرکز یه‌سره، موقع دیدن',
      'other': 'طولانی‌ترین تمرکز یه‌سره، موقع خوندن',
    });
    return '$_temp0';
  }

  @override
  String get cardGlowUpFirst => 'اولش';

  @override
  String get cardGlowUpNow => 'الان';

  @override
  String get cardGlowUpSelf => 'فقط خودم با خودم، نه هیچ‌کس دیگه.';

  @override
  String get cardMonthAction => 'این ماهمو نشون بده';

  @override
  String cardMonthHeading(String month) {
    return '$month، هر شب یه پنجره';
  }

  @override
  String cardMonthLit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString شب چراغم روشن بود',
      zero: 'این ماه هنوز چراغی روشن نشده',
    );
    return '$_temp0';
  }

  @override
  String get cardMonthLegend => 'هر چی روشن‌تر، بیشتر';

  @override
  String get cardNoteAction => 'این یادداشتو نشون بده';

  @override
  String get cardMonthDark => 'چراغ خاموش';

  @override
  String get cardMonthAhead => 'هنوز نرسیده';
}
