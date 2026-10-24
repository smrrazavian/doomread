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
  /// **'Library'**
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
  /// **'Add what you\'re reading, watching or listening to'**
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
  /// **'Add something'**
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
  /// **'Nothing here yet'**
  String get booksEmpty;

  /// No description provided for @readingNow.
  ///
  /// In en, this message translates to:
  /// **'Reading now'**
  String get readingNow;

  /// No description provided for @editBook.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
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
  /// **'An account keeps your library on all your devices. The app works fully without one.'**
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

  /// The server answered 429: too many sign-in or sign-up attempts in a short time.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes, then try again.'**
  String get accountErrorTooMany;

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
  /// **'Pick another'**
  String get changeBook;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @backToReading.
  ///
  /// In en, this message translates to:
  /// **'Back to reading'**
  String get backToReading;

  /// No description provided for @aim.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Aim: 1 minute in one go.} other{Aim: {minutes} minutes in one go.}}'**
  String aim(int minutes);

  /// No description provided for @eveningsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At your pace, about 1 evening left.} other{At your pace, about {count} evenings left.}}'**
  String eveningsLeft(int count);

  /// No description provided for @aimToGo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute to go.} other{{minutes} minutes to go.}}'**
  String aimToGo(int minutes);

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused. Take your time, it doesn\'t count against you.'**
  String get paused;

  /// No description provided for @faceDown.
  ///
  /// In en, this message translates to:
  /// **'Turn the phone face down.'**
  String get faceDown;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stopForTonight.
  ///
  /// In en, this message translates to:
  /// **'Stop for tonight'**
  String get stopForTonight;

  /// No description provided for @newBestStretch.
  ///
  /// In en, this message translates to:
  /// **'New best stretch'**
  String get newBestStretch;

  /// No description provided for @inOneGoTonight.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{Under a minute in one go tonight.} =1{1 minute in one go tonight.} other{{minutes} minutes in one go tonight.}}'**
  String inOneGoTonight(int minutes);

  /// No description provided for @whichPage.
  ///
  /// In en, this message translates to:
  /// **'Which page did you stop at?'**
  String get whichPage;

  /// No description provided for @ofStartedAt.
  ///
  /// In en, this message translates to:
  /// **'of {total}, started at {from}'**
  String ofStartedAt(int total, int from);

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'In a sentence, what happened?'**
  String get whatHappened;

  /// No description provided for @saveAndLightsOut.
  ///
  /// In en, this message translates to:
  /// **'Save and turn off the light'**
  String get saveAndLightsOut;

  /// No description provided for @problemNoPage.
  ///
  /// In en, this message translates to:
  /// **'Which page? Just the number.'**
  String get problemNoPage;

  /// No description provided for @problemPageOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'A page from {from} to {total}'**
  String problemPageOutOfRange(int from, int total);

  /// No description provided for @readingWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get readingWeekTitle;

  /// The Reading week: nights this week with a Session. It never mentions missed nights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{A fresh week} =1{1 reading night so far} other{{count} reading nights so far}}'**
  String readingWeekCount(int count);

  /// No description provided for @stretchTrendGrew.
  ///
  /// In en, this message translates to:
  /// **'Your longest stretch grew from {from} to {to} minutes.'**
  String stretchTrendGrew(int from, int to);

  /// No description provided for @stretchTrendSoFar.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{Your longest stretch so far is under a minute.} =1{Your longest stretch so far is 1 minute.} other{Your longest stretch so far is {minutes} minutes.}}'**
  String stretchTrendSoFar(int minutes);

  /// No description provided for @stretchTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start once and your longest stretch shows up here.'**
  String get stretchTrendEmpty;

  /// The first and last evening on the Longest stretch trend, read out by screen readers.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}.'**
  String stretchTrendDates(String from, String to);

  /// No description provided for @notificationAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the timer on your lock screen?'**
  String get notificationAskTitle;

  /// No description provided for @notificationAskBody.
  ///
  /// In en, this message translates to:
  /// **'While you\'re at it, Doomread shows one quiet notification with the timer and what you\'re on. It goes away when you stop, and that\'s all it\'s for.'**
  String get notificationAskBody;

  /// No description provided for @notificationAskAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notificationAskAllow;

  /// No description provided for @notificationAskNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationAskNotNow;

  /// No description provided for @notificationPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused at {time}'**
  String notificationPaused(String time);

  /// No description provided for @buildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your building'**
  String get buildingTitle;

  /// No description provided for @buildingSub.
  ///
  /// In en, this message translates to:
  /// **'One floor for everything you finish.'**
  String get buildingSub;

  /// No description provided for @buildingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No floors yet. Finish something and the first one lights up.'**
  String get buildingEmpty;

  /// No description provided for @floorDetails.
  ///
  /// In en, this message translates to:
  /// **'{pages, plural, =1{1 page} other{{pages} pages}}, {evenings, plural, =1{1 evening} other{{evenings} evenings}}'**
  String floorDetails(int pages, int evenings);

  /// No description provided for @finishedTitle.
  ///
  /// In en, this message translates to:
  /// **'You finished {title}.'**
  String finishedTitle(String title);

  /// No description provided for @finishedSub.
  ///
  /// In en, this message translates to:
  /// **'{pages, plural, =1{1 page} other{{pages} pages}} over {evenings, plural, =1{1 evening} other{{evenings} evenings}}. Your building grew a floor.'**
  String finishedSub(int pages, int evenings);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @longestStretchLabel.
  ///
  /// In en, this message translates to:
  /// **'longest stretch'**
  String get longestStretchLabel;

  /// The caption under the number of Notes on the finishing screen; the number itself is shown above it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{note written} other{notes written}}'**
  String notesWritten(int count);

  /// No description provided for @readTheStory.
  ///
  /// In en, this message translates to:
  /// **'Read the story in your words'**
  String get readTheStory;

  /// No description provided for @seeYourBuilding.
  ///
  /// In en, this message translates to:
  /// **'See your building'**
  String get seeYourBuilding;

  /// No description provided for @storySoFar.
  ///
  /// In en, this message translates to:
  /// **'The story so far, in your words'**
  String get storySoFar;

  /// No description provided for @storyEmpty.
  ///
  /// In en, this message translates to:
  /// **'After each evening, the sentence you write about it lands here.'**
  String get storyEmpty;

  /// No description provided for @bookFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished, every last page.'**
  String get bookFinished;

  /// No description provided for @pageRange.
  ///
  /// In en, this message translates to:
  /// **'p. {from}–{to}'**
  String pageRange(int from, int to);

  /// Under the House on the Reading screen when only the user's own Window is lit.
  ///
  /// In en, this message translates to:
  /// **'Only your light is on for now. Each evening you show up lights another.'**
  String get houseEmpty;

  /// Under the House when it has other lit Windows; before Friends exist, they are all the user's own earlier Sessions.
  ///
  /// In en, this message translates to:
  /// **'Every other light here is yours too, from an evening you showed up.'**
  String get houseYours;

  /// On Reading: how far away the next Planned break is, in minutes of reading, when it is at a chapter end.
  ///
  /// In en, this message translates to:
  /// **'Your break: the end of chapter {chapter}, in about {minutes} min.'**
  String nextBreakAtCheckpoint(int chapter, int minutes);

  /// No description provided for @nextBreakAtPage.
  ///
  /// In en, this message translates to:
  /// **'Your break: in about {minutes} min, at the end of the page you\'re on.'**
  String nextBreakAtPage(int minutes);

  /// No description provided for @breakDueAtCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Break time at the end of chapter {chapter}.'**
  String breakDueAtCheckpoint(int chapter);

  /// No description provided for @breakDueAtPage.
  ///
  /// In en, this message translates to:
  /// **'Break time. Finish the page you\'re on.'**
  String get breakDueAtPage;

  /// No description provided for @takeBreak.
  ///
  /// In en, this message translates to:
  /// **'I\'m there'**
  String get takeBreak;

  /// No description provided for @nudgeBreak.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get nudgeBreak;

  /// No description provided for @onBreakUntil.
  ///
  /// In en, this message translates to:
  /// **'On your break until {time}.'**
  String onBreakUntil(String time);

  /// No description provided for @showBreak.
  ///
  /// In en, this message translates to:
  /// **'Show the timer'**
  String get showBreak;

  /// No description provided for @chapterDone.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} done'**
  String chapterDone(int chapter);

  /// No description provided for @breakHere.
  ///
  /// In en, this message translates to:
  /// **'Your break is here.'**
  String get breakHere;

  /// The return time, named before the Planned break starts.
  ///
  /// In en, this message translates to:
  /// **'Back to chapter {chapter} at {time}.'**
  String backToChapterAt(int chapter, String time);

  /// No description provided for @backToBookAt.
  ///
  /// In en, this message translates to:
  /// **'Back to the book at {time}.'**
  String backToBookAt(String time);

  /// No description provided for @bestTonight.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{Your best stretch tonight is under a minute.} =1{Your best stretch tonight is 1 minute.} other{Your best stretch tonight is {minutes} minutes.}}'**
  String bestTonight(int minutes);

  /// No description provided for @startMyBreak.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Start my minute} other{Start my {minutes} minutes}}'**
  String startMyBreak(int minutes);

  /// No description provided for @keepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep reading instead'**
  String get keepReading;

  /// No description provided for @onBreak.
  ///
  /// In en, this message translates to:
  /// **'On your break.'**
  String get onBreak;

  /// No description provided for @imBack.
  ///
  /// In en, this message translates to:
  /// **'I\'m back'**
  String get imBack;

  /// No description provided for @chapterWaiting.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} is waiting.'**
  String chapterWaiting(int chapter);

  /// No description provided for @workWaiting.
  ///
  /// In en, this message translates to:
  /// **'{title} is waiting.'**
  String workWaiting(String title);

  /// On the home screen widget, under the page: how many evenings until the Finish at the user's pace.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{about 1 evening left} other{about {count} evenings left}}'**
  String widgetEvenings(int count);

  /// On the home screen widget, once the user has read tonight.
  ///
  /// In en, this message translates to:
  /// **'Your window is lit tonight'**
  String get widgetLit;

  /// On the home screen widget, before the user has read tonight.
  ///
  /// In en, this message translates to:
  /// **'Your window is still dark tonight'**
  String get widgetDark;

  /// No description provided for @kindPaperBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get kindPaperBook;

  /// No description provided for @kindEbook.
  ///
  /// In en, this message translates to:
  /// **'Ebook'**
  String get kindEbook;

  /// No description provided for @kindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get kindSeries;

  /// No description provided for @kindFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get kindFilm;

  /// No description provided for @kindPodcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get kindPodcast;

  /// No description provided for @fieldCreator.
  ///
  /// In en, this message translates to:
  /// **'Made by'**
  String get fieldCreator;

  /// No description provided for @fieldEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Number of episodes'**
  String get fieldEpisodes;

  /// No description provided for @fieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get fieldDuration;

  /// No description provided for @fieldDurationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2:41:00'**
  String get fieldDurationHint;

  /// No description provided for @fieldTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Where segments end (optional)'**
  String get fieldTimestamps;

  /// No description provided for @fieldTimestampsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 42:30, 1:15:00'**
  String get fieldTimestampsHint;

  /// No description provided for @problemNoEpisodes.
  ///
  /// In en, this message translates to:
  /// **'How many episodes does it have?'**
  String get problemNoEpisodes;

  /// No description provided for @problemNoDuration.
  ///
  /// In en, this message translates to:
  /// **'How long is it? Like 2:41:00'**
  String get problemNoDuration;

  /// No description provided for @problemTimestampPastEnd.
  ///
  /// In en, this message translates to:
  /// **'Times must be within its length'**
  String get problemTimestampPastEnd;

  /// No description provided for @episodeOf.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode} of {total}'**
  String episodeOf(int episode, int total);

  /// No description provided for @timeOf.
  ///
  /// In en, this message translates to:
  /// **'{time} of {total}'**
  String timeOf(String time, String total);

  /// No description provided for @episodesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode left} other{{count} episodes left}}'**
  String episodesLeft(int count);

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @nextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next up: episode {episode}'**
  String nextEpisode(int episode);

  /// No description provided for @nextTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Next segment ends at {time}'**
  String nextTimestamp(String time);

  /// kind is a WorkKind name: paperBook, ebook, series, film or podcast.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, series{Start watching} film{Start watching} podcast{Start listening} other{Start reading}}'**
  String startWork(String kind);

  /// kind is a WorkKind name: paperBook, ebook, series, film or podcast.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, series{Back to watching} film{Back to watching} podcast{Back to listening} other{Back to reading}}'**
  String backToWork(String kind);

  /// kind is a WorkKind name: paperBook, ebook, series, film or podcast.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, series{Watching now} film{Watching now} podcast{Listening now} other{Reading now}}'**
  String workNow(String kind);

  /// No description provided for @whichEpisode.
  ///
  /// In en, this message translates to:
  /// **'Which episode did you get to?'**
  String get whichEpisode;

  /// No description provided for @whereStopped.
  ///
  /// In en, this message translates to:
  /// **'Where did you stop?'**
  String get whereStopped;

  /// No description provided for @ofStartedAtTime.
  ///
  /// In en, this message translates to:
  /// **'of {total}, started at {from}'**
  String ofStartedAtTime(String total, String from);

  /// No description provided for @problemNoEpisode.
  ///
  /// In en, this message translates to:
  /// **'Which episode? Just the number.'**
  String get problemNoEpisode;

  /// No description provided for @problemNoTime.
  ///
  /// In en, this message translates to:
  /// **'Where? Like 1:12:20'**
  String get problemNoTime;

  /// No description provided for @problemEpisodeOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'An episode from {from} to {total}'**
  String problemEpisodeOutOfRange(int from, int total);

  /// No description provided for @problemTimeOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'A time from {from} to {total}'**
  String problemTimeOutOfRange(String from, String total);

  /// No description provided for @episodeRange.
  ///
  /// In en, this message translates to:
  /// **'ep. {from}–{to}'**
  String episodeRange(int from, int to);

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String timeRange(String from, String to);

  /// No description provided for @finishedSubEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{episodes, plural, =1{1 episode} other{{episodes} episodes}} over {evenings, plural, =1{1 evening} other{{evenings} evenings}}. Your building grew a floor.'**
  String finishedSubEpisodes(int episodes, int evenings);

  /// No description provided for @finishedSubTime.
  ///
  /// In en, this message translates to:
  /// **'{time} over {evenings, plural, =1{1 evening} other{{evenings} evenings}}. Your building grew a floor.'**
  String finishedSubTime(String time, int evenings);

  /// No description provided for @floorDetailsEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{episodes, plural, =1{1 episode} other{{episodes} episodes}}, {evenings, plural, =1{1 evening} other{{evenings} evenings}}'**
  String floorDetailsEpisodes(int episodes, int evenings);

  /// No description provided for @floorDetailsTime.
  ///
  /// In en, this message translates to:
  /// **'{time}, {evenings, plural, =1{1 evening} other{{evenings} evenings}}'**
  String floorDetailsTime(String time, int evenings);

  /// No description provided for @watchedFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished, right to the end.'**
  String get watchedFinished;

  /// No description provided for @trendReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get trendReading;

  /// No description provided for @trendWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get trendWatching;

  /// No description provided for @ofStartedAtEpisode.
  ///
  /// In en, this message translates to:
  /// **'of {total}, started at episode {from}'**
  String ofStartedAtEpisode(int total, int from);

  /// inOneGoTonight for a Work that is watched or listened to, not read.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{Under a minute in one go tonight.} =1{1 minute in one go tonight.} other{{minutes} minutes in one go tonight.}}'**
  String inOneGoTonightWatched(int minutes);

  /// No description provided for @nextBreakAtEpisode.
  ///
  /// In en, this message translates to:
  /// **'Your break: the end of episode {episode}, in about {minutes} min.'**
  String nextBreakAtEpisode(int episode, int minutes);

  /// No description provided for @breakDueAtEpisode.
  ///
  /// In en, this message translates to:
  /// **'Break time at the end of episode {episode}.'**
  String breakDueAtEpisode(int episode);

  /// No description provided for @nextBreakAtTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Your break: at {timestamp}, in about {minutes} min.'**
  String nextBreakAtTimestamp(String timestamp, int minutes);

  /// No description provided for @breakDueAtTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Break time at {timestamp}.'**
  String breakDueAtTimestamp(String timestamp);

  /// No description provided for @nextBreakWatching.
  ///
  /// In en, this message translates to:
  /// **'Your break: in about {minutes} min, when this segment ends.'**
  String nextBreakWatching(int minutes);

  /// No description provided for @breakDueWatching.
  ///
  /// In en, this message translates to:
  /// **'Break time. Pause when this segment ends.'**
  String get breakDueWatching;

  /// No description provided for @episodeDone.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode} done'**
  String episodeDone(int episode);

  /// No description provided for @episodeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode} is waiting.'**
  String episodeWaiting(int episode);

  /// No description provided for @backToEpisodeAt.
  ///
  /// In en, this message translates to:
  /// **'Back to episode {episode} at {time}.'**
  String backToEpisodeAt(int episode, String time);

  /// No description provided for @backToWorkAt.
  ///
  /// In en, this message translates to:
  /// **'Back to it at {time}.'**
  String backToWorkAt(String time);

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going instead'**
  String get keepGoing;

  /// Under the Urge headline and the distance to the next Planned break.
  ///
  /// In en, this message translates to:
  /// **'You planned that break yourself, remember?'**
  String get urgeBody;

  /// The big button on the Urge screen for a book: going back is Let pass.
  ///
  /// In en, this message translates to:
  /// **'Back to the book'**
  String get backToBook;

  /// The full-size, always-allowed button on the Urge screen; it records a Slip and opens the app.
  ///
  /// In en, this message translates to:
  /// **'Open {app} anyway'**
  String openAnyway(String app);

  /// The same as openAnyway when the app's name isn't known, say after a restart.
  ///
  /// In en, this message translates to:
  /// **'Open it anyway'**
  String get openItAnyway;

  /// After a slip: how long the Stretch the Slip ended was.
  ///
  /// In en, this message translates to:
  /// **'You were {minutes} min in. Pick it back up?'**
  String slipBody(int minutes);

  /// After a slip: resumes the Session.
  ///
  /// In en, this message translates to:
  /// **'Back in'**
  String get backIn;

  /// After a slip: stops the Session and goes to End of the evening.
  ///
  /// In en, this message translates to:
  /// **'Done for tonight'**
  String get doneForTonight;

  /// Settings entry and screen title: the apps that bring up the "not yet" screen during a Session.
  ///
  /// In en, this message translates to:
  /// **'Watched apps'**
  String get watchedApps;

  /// At the top of the Watched apps screen.
  ///
  /// In en, this message translates to:
  /// **'Open one of these mid-Session and the \"not yet\" screen comes up. Outside a Session, and on your Planned break, nothing happens.'**
  String get watchedAppsHint;

  /// On the Watched apps screen while the accessibility service is not turned on.
  ///
  /// In en, this message translates to:
  /// **'The \"not yet\" screen is off.'**
  String get watchOff;

  /// Opens the prominent disclosure, then Android's Accessibility settings.
  ///
  /// In en, this message translates to:
  /// **'Turn it on'**
  String get watchTurnOn;

  /// Prominent disclosure title (Google Play policy), shown before the Accessibility settings.
  ///
  /// In en, this message translates to:
  /// **'Doomread uses Accessibility'**
  String get watchAskTitle;

  /// Prominent disclosure body (Google Play policy): what is accessed, how it's used, that it isn't collected or shared, and how to turn it off.
  ///
  /// In en, this message translates to:
  /// **'To bring up the \"not yet\" screen, Doomread uses Android\'s Accessibility service to see which app you open during a Session. It notices which app is in front and, when tonight\'s Work is on YouTube, whether Shorts is open, by the kind of screen showing. It never reads the text on your screen or what you type. Nothing it sees leaves your phone or is shared with anyone.\n\nYou can turn it off any time in Settings. Doomread never stops you turning it off or uninstalling anything.'**
  String get watchAskBody;

  /// The affirmative tap on the disclosure; opens Android's Accessibility settings.
  ///
  /// In en, this message translates to:
  /// **'Agree and turn on'**
  String get watchAskAgree;

  /// Declines the disclosure; nothing is turned on.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get watchAskNotNow;

  /// Under watchOff. Android 13+ restricts Accessibility for apps installed outside an app store (the apk flavour, and Cafe Bazaar).
  ///
  /// In en, this message translates to:
  /// **'If Android says it\'s a restricted setting: open Doomread\'s App info, tap the three-dot menu, then Allow restricted settings, and try again.'**
  String get watchRestricted;

  /// Tonight: the Work isn't in an app on this phone (a paper book, a TV).
  ///
  /// In en, this message translates to:
  /// **'Not on the phone'**
  String get workAppNone;

  /// Title of the sheet that picks the Work app.
  ///
  /// In en, this message translates to:
  /// **'Where is it tonight?'**
  String get workAppPick;

  /// Under workAppPick.
  ///
  /// In en, this message translates to:
  /// **'Switching to its app never brings up the \"not yet\" screen. With YouTube, only Shorts does.'**
  String get workAppHint;

  /// Reading, in place of faceDown, when the Work is in an app on the phone.
  ///
  /// In en, this message translates to:
  /// **'It\'s in {app}, so switching to it is fine.'**
  String workAppReading(String app);

  /// Button by workAppReading that opens the Work app.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openWorkApp;

  /// Reading, by faceDown: picks the app that holds the Work, its Work app.
  ///
  /// In en, this message translates to:
  /// **'On the phone?'**
  String get workAppAsk;

  /// Settings, under Watched apps: the way of watching apps that is on (ADR 0016).
  ///
  /// In en, this message translates to:
  /// **'Through Accessibility'**
  String get watchViaAccessibility;

  /// No description provided for @watchViaUsage.
  ///
  /// In en, this message translates to:
  /// **'Through usage access'**
  String get watchViaUsage;

  /// No description provided for @watchViaNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get watchViaNone;

  /// Watched apps, in place of watchOff, when the usage access fallback is on.
  ///
  /// In en, this message translates to:
  /// **'On, through usage access. It can take a second or two, and it can\'t tell Shorts from the rest of YouTube.'**
  String get watchOnUsage;

  /// Watched apps, while no way of watching is on: the usage access fallback, explained before its two buttons.
  ///
  /// In en, this message translates to:
  /// **'Can\'t turn on Accessibility, say with Advanced Protection on? Usage access works too, a second or two slower. It needs two permissions: usage access, and display over other apps, so the \"not yet\" screen can come up.'**
  String get watchFallback;

  /// No description provided for @watchAllowUsage.
  ///
  /// In en, this message translates to:
  /// **'Allow usage access'**
  String get watchAllowUsage;

  /// No description provided for @watchAllowOverlay.
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps'**
  String get watchAllowOverlay;

  /// Settings and the Tone screen: the voice the app speaks in.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get tone;

  /// No description provided for @toneChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get toneChill;

  /// No description provided for @toneSpicy.
  ///
  /// In en, this message translates to:
  /// **'Spicy'**
  String get toneSpicy;

  /// No description provided for @toneMom.
  ///
  /// In en, this message translates to:
  /// **'Mom mode'**
  String get toneMom;

  /// Tonight before the first Work: offers the Tone.
  ///
  /// In en, this message translates to:
  /// **'How should Doomread talk to you?'**
  String get toneAsk;

  /// Top of the Tone screen.
  ///
  /// In en, this message translates to:
  /// **'Whichever you pick, it roasts the urge, never you, and it\'s always kind after a slip.'**
  String get toneHint;
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
