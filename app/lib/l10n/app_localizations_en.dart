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
  String get navBooks => 'Library';

  @override
  String get navBuilding => 'Building';

  @override
  String get navFriends => 'Friends';

  @override
  String get tonightEmpty =>
      'Add what you\'re reading, watching or listening to';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get tonightAddBook => 'Add something';

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
  String get booksEmpty => 'Nothing here yet';

  @override
  String get readingNow => 'Reading now';

  @override
  String get editBook => 'Edit';

  @override
  String get deleteWork => 'Delete';

  @override
  String workDeleted(String title) {
    return 'Deleted “$title”';
  }

  @override
  String get undo => 'Undo';

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
      'An account keeps your library on all your devices. The app works fully without one.';

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
  String get changeBook => 'Pick another';

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

  @override
  String get readingWeekTitle => 'This week';

  @override
  String readingWeekCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString nights so far',
      one: '1 night so far',
      zero: 'A fresh week',
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

    return 'Your longest stretch grew from $fromString to $toString minutes.';
  }

  @override
  String stretchTrendSoFar(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Your longest stretch so far is $minutesString minutes.',
      one: 'Your longest stretch so far is 1 minute.',
      zero: 'Your longest stretch so far is under a minute.',
    );
    return '$_temp0';
  }

  @override
  String get stretchTrendEmpty =>
      'Start once and your longest stretch shows up here.';

  @override
  String stretchTrendDates(String from, String to) {
    return 'From $from to $to.';
  }

  @override
  String get notificationAskTitle => 'Keep the timer on your lock screen?';

  @override
  String get notificationAskBody =>
      'While you\'re at it, Doomread shows one quiet notification with the timer and what you\'re on. It goes away when you stop, and that\'s all it\'s for.';

  @override
  String get notificationAskAllow => 'Allow';

  @override
  String get notificationAskNotNow => 'Not now';

  @override
  String notificationPaused(String time) {
    return 'Paused at $time';
  }

  @override
  String get buildingTitle => 'Your building';

  @override
  String get buildingSub => 'One floor for everything you finish.';

  @override
  String get buildingEmpty =>
      'No floors yet. Finish something and the first one lights up.';

  @override
  String floorDetails(int pages, int evenings) {
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pagesString pages',
      one: '1 page',
    );
    String _temp1 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String finishedTitle(String title) {
    return 'You finished $title.';
  }

  @override
  String finishedSub(int pages, int evenings) {
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pagesString pages',
      one: '1 page',
    );
    String _temp1 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$_temp0 over $_temp1. Your building grew a floor.';
  }

  @override
  String minutesShort(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String get longestStretchLabel => 'longest stretch';

  @override
  String notesWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'notes written',
      one: 'note written',
    );
    return '$_temp0';
  }

  @override
  String get readTheStory => 'Read the story in your words';

  @override
  String get seeYourBuilding => 'See your building';

  @override
  String get storySoFar => 'The story so far, in your words';

  @override
  String get storyEmpty =>
      'After each evening, the sentence you write about it lands here.';

  @override
  String get bookFinished => 'Finished, every last page.';

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

    return 'p. $fromString–$toString';
  }

  @override
  String get houseEmpty =>
      'Only your light is on for now. Each evening you show up lights another.';

  @override
  String get houseYours =>
      'Every other light here is yours too, from an evening you showed up.';

  @override
  String nextBreakAtCheckpoint(int chapter, int minutes) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Your break: the end of chapter $chapterString, in about $minutesString min.';
  }

  @override
  String nextBreakAtPage(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Your break: in about $minutesString min, at the end of the page you\'re on.';
  }

  @override
  String breakDueAtCheckpoint(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'Break time at the end of chapter $chapterString.';
  }

  @override
  String get breakDueAtPage => 'Break time. Finish the page you\'re on.';

  @override
  String get takeBreak => 'I\'m there';

  @override
  String get nudgeBreak => 'Later';

  @override
  String onBreakUntil(String time) {
    return 'On your break until $time.';
  }

  @override
  String get showBreak => 'Show the timer';

  @override
  String chapterDone(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'Chapter $chapterString done';
  }

  @override
  String get breakHere => 'Your break is here.';

  @override
  String backToChapterAt(int chapter, String time) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'Back to chapter $chapterString at $time.';
  }

  @override
  String backToBookAt(String time) {
    return 'Back to the book at $time.';
  }

  @override
  String bestTonight(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Your best stretch tonight is $minutesString minutes.',
      one: 'Your best stretch tonight is 1 minute.',
      zero: 'Your best stretch tonight is under a minute.',
    );
    return '$_temp0';
  }

  @override
  String startMyBreak(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Start my $minutesString minutes',
      one: 'Start my minute',
    );
    return '$_temp0';
  }

  @override
  String get keepReading => 'Keep reading instead';

  @override
  String get onBreak => 'On your break.';

  @override
  String get imBack => 'I\'m back';

  @override
  String chapterWaiting(int chapter) {
    final intl.NumberFormat chapterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chapterString = chapterNumberFormat.format(chapter);

    return 'Chapter $chapterString is waiting.';
  }

  @override
  String workWaiting(String title) {
    return '$title is waiting.';
  }

  @override
  String widgetEvenings(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'about $countString evenings left',
      one: 'about 1 evening left',
    );
    return '$_temp0';
  }

  @override
  String get widgetLit => 'Your window is lit tonight';

  @override
  String get widgetDark => 'Your window is still dark tonight';

  @override
  String get kindPaperBook => 'Book';

  @override
  String get kindEbook => 'Ebook';

  @override
  String get kindSeries => 'Series';

  @override
  String get kindFilm => 'Film';

  @override
  String get kindPodcast => 'Podcast';

  @override
  String get fieldCreator => 'Made by';

  @override
  String get fieldEpisodes => 'Number of episodes';

  @override
  String get fieldDuration => 'Length';

  @override
  String get fieldDurationHint => 'e.g. 2:41:00';

  @override
  String get fieldTimestamps => 'Where segments end (optional)';

  @override
  String get fieldTimestampsHint => 'e.g. 42:30, 1:15:00';

  @override
  String get problemNoEpisodes => 'How many episodes does it have?';

  @override
  String get problemNoDuration => 'How long is it? Like 2:41:00';

  @override
  String get problemTimestampPastEnd => 'Times must be within its length';

  @override
  String episodeOf(int episode, int total) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Episode $episodeString of $totalString';
  }

  @override
  String timeOf(String time, String total) {
    return '$time of $total';
  }

  @override
  String episodesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString episodes left',
      one: '1 episode left',
    );
    return '$_temp0';
  }

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String nextEpisode(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'Next up: episode $episodeString';
  }

  @override
  String nextTimestamp(String time) {
    return 'Next segment ends at $time';
  }

  @override
  String startWork(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'Start watching',
      'film': 'Start watching',
      'podcast': 'Start listening',
      'other': 'Start reading',
    });
    return '$_temp0';
  }

  @override
  String backToWork(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'Back to watching',
      'film': 'Back to watching',
      'podcast': 'Back to listening',
      'other': 'Back to reading',
    });
    return '$_temp0';
  }

  @override
  String workNow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'series': 'Watching now',
      'film': 'Watching now',
      'podcast': 'Listening now',
      'other': 'Reading now',
    });
    return '$_temp0';
  }

  @override
  String get whichEpisode => 'Which episode did you get to?';

  @override
  String get whereStopped => 'Where did you stop?';

  @override
  String ofStartedAtTime(String total, String from) {
    return 'of $total, started at $from';
  }

  @override
  String get problemNoEpisode => 'Which episode? Just the number.';

  @override
  String get problemNoTime => 'Where? Like 1:12:20';

  @override
  String problemEpisodeOutOfRange(int from, int total) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'An episode from $fromString to $totalString';
  }

  @override
  String problemTimeOutOfRange(String from, String total) {
    return 'A time from $from to $total';
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

    return 'ep. $fromString–$toString';
  }

  @override
  String timeRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String finishedSubEpisodes(int episodes, int evenings) {
    final intl.NumberFormat episodesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodesString = episodesNumberFormat.format(episodes);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      episodes,
      locale: localeName,
      other: '$episodesString episodes',
      one: '1 episode',
    );
    String _temp1 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$_temp0 over $_temp1. Your building grew a floor.';
  }

  @override
  String finishedSubTime(String time, int evenings) {
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$time over $_temp0. Your building grew a floor.';
  }

  @override
  String floorDetailsEpisodes(int episodes, int evenings) {
    final intl.NumberFormat episodesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodesString = episodesNumberFormat.format(episodes);
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      episodes,
      locale: localeName,
      other: '$episodesString episodes',
      one: '1 episode',
    );
    String _temp1 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String floorDetailsTime(String time, int evenings) {
    final intl.NumberFormat eveningsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eveningsString = eveningsNumberFormat.format(evenings);

    String _temp0 = intl.Intl.pluralLogic(
      evenings,
      locale: localeName,
      other: '$eveningsString evenings',
      one: '1 evening',
    );
    return '$time, $_temp0';
  }

  @override
  String get watchedFinished => 'Finished, right to the end.';

  @override
  String get trendReading => 'Reading';

  @override
  String get trendWatching => 'Watching';

  @override
  String ofStartedAtEpisode(int total, int from) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);

    return 'of $totalString, started at episode $fromString';
  }

  @override
  String inOneGoTonightWatched(int minutes) {
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
  String nextBreakAtEpisode(int episode, int minutes) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Your break: the end of episode $episodeString, in about $minutesString min.';
  }

  @override
  String breakDueAtEpisode(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'Break time at the end of episode $episodeString.';
  }

  @override
  String nextBreakAtTimestamp(String timestamp, int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Your break: at $timestamp, in about $minutesString min.';
  }

  @override
  String breakDueAtTimestamp(String timestamp) {
    return 'Break time at $timestamp.';
  }

  @override
  String nextBreakWatching(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Your break: in about $minutesString min, when this segment ends.';
  }

  @override
  String get breakDueWatching => 'Break time. Pause when this segment ends.';

  @override
  String episodeDone(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'Episode $episodeString done';
  }

  @override
  String episodeWaiting(int episode) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'Episode $episodeString is waiting.';
  }

  @override
  String backToEpisodeAt(int episode, String time) {
    final intl.NumberFormat episodeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String episodeString = episodeNumberFormat.format(episode);

    return 'Back to episode $episodeString at $time.';
  }

  @override
  String backToWorkAt(String time) {
    return 'Back to it at $time.';
  }

  @override
  String get keepGoing => 'Keep going instead';

  @override
  String get urgeBody => 'You planned that break yourself, remember?';

  @override
  String get backToBook => 'Back to the book';

  @override
  String openAnyway(String app) {
    return 'Open $app anyway';
  }

  @override
  String get openItAnyway => 'Open it anyway';

  @override
  String slipBody(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'You were $minutesString min in. Pick it back up?';
  }

  @override
  String get backIn => 'Back in';

  @override
  String get doneForTonight => 'Done for tonight';

  @override
  String get watchedApps => 'Watched apps';

  @override
  String get watchedAppsHint =>
      'Open one of these mid-Session and the \"not yet\" screen comes up. Outside a Session, and on your Planned break, nothing happens.';

  @override
  String get watchOff => 'The \"not yet\" screen is off.';

  @override
  String get watchTurnOn => 'Turn it on';

  @override
  String get watchAskTitle => 'Doomread uses Accessibility';

  @override
  String get watchAskBody =>
      'To bring up the \"not yet\" screen, Doomread uses Android\'s Accessibility service to see which app you open during a Session. It notices which app is in front and, when tonight\'s Work is on YouTube, whether Shorts is open, by the kind of screen showing. It never reads the text on your screen or what you type. Nothing it sees leaves your phone or is shared with anyone.\n\nYou can turn it off any time in Settings. Doomread never stops you turning it off or uninstalling anything.';

  @override
  String get watchAskAgree => 'Agree and turn on';

  @override
  String get watchAskNotNow => 'Not now';

  @override
  String get watchRestricted =>
      'If Android says it\'s a restricted setting: open Doomread\'s App info, tap the three-dot menu, then Allow restricted settings, and try again.';

  @override
  String get workAppNone => 'Not on the phone';

  @override
  String get workAppPick => 'Where is it tonight?';

  @override
  String get workAppHint =>
      'Switching to its app never brings up the \"not yet\" screen. With YouTube, only Shorts does.';

  @override
  String workAppReading(String app) {
    return 'It\'s in $app, so switching to it is fine.';
  }

  @override
  String get openWorkApp => 'Open';

  @override
  String get workAppAsk => 'On the phone?';

  @override
  String get watchViaAccessibility => 'Through Accessibility';

  @override
  String get watchViaUsage => 'Through usage access';

  @override
  String get watchViaNone => 'Off';

  @override
  String get watchOnUsage =>
      'On, through usage access. It can take a second or two, and it can\'t tell Shorts from the rest of YouTube.';

  @override
  String get watchFallback =>
      'Can\'t turn on Accessibility, say with Advanced Protection on? Usage access works too, a second or two slower. It needs two permissions: usage access, and display over other apps, so the \"not yet\" screen can come up.';

  @override
  String get watchAllowUsage => 'Allow usage access';

  @override
  String get watchAllowOverlay => 'Allow display over other apps';

  @override
  String get tone => 'Tone';

  @override
  String get toneChill => 'Chill';

  @override
  String get toneSpicy => 'Spicy';

  @override
  String get toneMom => 'Mom mode';

  @override
  String get toneAsk => 'How should Doomread talk to you?';

  @override
  String get toneHint =>
      'Whichever you pick, it roasts the urge, never you, and it\'s always kind after a slip.';

  @override
  String whereIsElsewhere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'paperBook': 'On paper',
      'other': 'Elsewhere',
    });
    return '$_temp0';
  }

  @override
  String get whereIsPhone => 'On this phone';

  @override
  String get whereIsSearch => 'Search apps';
}
