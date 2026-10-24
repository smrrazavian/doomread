import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));
  final now = DateTime(2026, 10, 22, 21);
  final demoTitle = voice(Moment.urge, Tone.spicy, 'en', {'app': 'Instagram'});

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('introNext')));

  /// The user leaves for the system settings and comes back.
  Future<void> comeBack(WidgetTester tester) async {
    [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();
  }

  Future<List<SessionEventKind>> journal(AppDatabase db) async => [
    for (final e in await db.select(db.sessionEvents).get()) e.kind,
  ];

  /// A fresh install, through the three cards and the Work, to Start.
  Future<void> throughIntro(
    WidgetTester tester,
    AppDatabase db, {
    FakeAppWatch? watch,
    FakeSessionNotification? notification,
  }) async {
    await pumpApp(
      tester,
      db,
      tour: true,
      clock: () => now,
      watch: watch,
      notification: notification,
    );
    expect(find.text(en.tourStoryTitle), findsOne);
    await next(tester);
    expect(find.text(en.tourCompanyTitle), findsOne);
    await next(tester);
    expect(find.text(en.tourToneTitle), findsOne);
    await next(tester);
    expect(find.text(en.tourWorkTitle), findsOne);
    await tester.enterText(find.byKey(const Key('title')), 'Piranesi');
    await tester.enterText(find.byKey(const Key('pages')), '245');
    await next(tester);
  }

  /// Hints and asks on screen now, by their text.
  List<String> explainers(WidgetTester tester) => [
    for (final t in [
      en.notificationAskTitle,
      en.watchAskTitle,
      en.tourDemoAsk,
      en.tourUrgeHint,
      en.tourWatchAsk,
    ])
      if (find.text(t).evaluate().isNotEmpty) t,
    if (find.textContaining('Your best + 1').evaluate().isNotEmpty) 'aim',
  ];

  testApp('a first launch opens the intro, its Tone is heard and picked, '
      'and its Start is the first Session', (tester, db) async {
    await pumpApp(tester, db, tour: true, clock: () => now);
    expect(find.text(en.tourStoryTitle), findsOne);
    await next(tester);
    await next(tester);
    for (final t in Tone.values) {
      expect(
        find.text(voice(Moment.urge, t, 'en', {'app': 'Instagram'})),
        findsOne,
        reason: 'each Tone says the same line in its own voice',
      );
    }
    await tap(tester, find.byKey(const Key('tone_mom')));
    expect(await SettingsRepository(db).tone(), Tone.mom);
    await next(tester);

    // Title, length, Start.
    await tester.enterText(find.byKey(const Key('title')), 'Piranesi');
    await tester.enterText(find.byKey(const Key('pages')), '245');
    await next(tester);
    expect(find.text(en.stopForTonight), findsOne);
    expect(await journal(db), [SessionEventKind.start]);
    expect(find.textContaining('Your best + 1'), findsOne);

    // Never again.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, db, tour: true, clock: () => now);
    expect(find.text(en.tourStoryTitle), findsNothing);
  });

  testApp('the intro asks again for a missing title, and Later leaves '
      'without a Work', (tester, db) async {
    await pumpApp(tester, db, tour: true);
    await next(tester);
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text(en.problemNoTitle), findsOne);
    await tap(tester, find.text(en.tourLater));
    expect(find.text(en.emptyTonight), findsOne);
    expect(await SettingsRepository(db).introSeen(), isTrue);
  });

  testApp('someone upgrading with Works never sees the intro or the hints', (
    tester,
    db,
  ) async {
    await WorkRepository(db).add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 245,
      checkpoints: const [],
    );
    await pumpApp(tester, db, tour: true, clock: () => now);
    expect(find.text(en.tourStoryTitle), findsNothing);
    expect(find.text('Piranesi'), findsOne);
    expect(await SettingsRepository(db).introSeen(), isTrue);
    expect(await SettingsRepository(db).hintsSeen(), Hint.values.toSet());

    await tap(tester, find.text(en.startReading));
    expect(find.text(en.stopForTonight), findsOne);
    expect(find.byKey(const Key('hintGotIt')), findsNothing);
  });

  testApp('Skip lands on an empty Tonight, and the intro never comes back', (
    tester,
    db,
  ) async {
    await pumpApp(tester, db, tour: true);
    await tap(tester, find.byKey(const Key('introSkip')));
    expect(find.text(en.emptyTonight), findsOne);
    expect(await SettingsRepository(db).hintsSeen(), {
      Hint.demoUrge,
    }, reason: 'the one-line hints still come, once each');
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, db, tour: true);
    expect(find.text(en.tourStoryTitle), findsNothing);
    expect(find.text(en.emptyTonight), findsOne);
  });

  testApp('the language switch flips the intro live, right to left, and '
      'is saved', (tester, db) async {
    await pumpApp(tester, db, tour: true);
    await tap(tester, find.byKey(const Key('language_fa')));
    expect(find.text(fa.tourStoryTitle), findsOne);
    expect(
      Directionality.of(tester.element(find.text(fa.tourStoryTitle))),
      TextDirection.rtl,
    );
    expect(await SettingsRepository(db).locale(), const Locale('fa'));

    await next(tester);
    expect(find.text(fa.tourCompanyTitle), findsOne);
    expect(find.byKey(const Key('language_en')), findsNothing);
  });

  testApp('on a Persian phone a new user starts in Persian, kept once the '
      'intro is skipped', (tester, db) async {
    await pumpApp(tester, db, tour: true, phoneLocale: const Locale('fa'));
    expect(find.text(fa.tourStoryTitle), findsOne);
    expect(
      Directionality.of(tester.element(find.text(fa.tourStoryTitle))),
      TextDirection.rtl,
    );
    expect(await SettingsRepository(db).locale(), isNull);
    await tap(tester, find.byKey(const Key('introSkip')));
    expect(await SettingsRepository(db).locale(), const Locale('fa'));
  });

  testApp('the switch on a Persian phone picks English', (tester, db) async {
    await pumpApp(tester, db, tour: true, phoneLocale: const Locale('fa'));
    await tap(tester, find.byKey(const Key('language_en')));
    expect(find.text(en.tourStoryTitle), findsOne);
    expect(await SettingsRepository(db).locale(), const Locale('en'));
  });

  testApp('someone upgrading on a Persian phone stays in English', (
    tester,
    db,
  ) async {
    await WorkRepository(db).add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 245,
      checkpoints: const [],
    );
    await pumpApp(tester, db, tour: true, phoneLocale: const Locale('fa'));
    expect(find.text(en.startReading), findsOne);
    expect(await SettingsRepository(db).locale(), const Locale('en'));
  });

  testApp('the demo Urge records nothing, then asks for the "not yet" '
      'screen', (tester, db) async {
    final w = FakeAppWatch(isEnabled: false);
    await throughIntro(tester, db, watch: w);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    await tap(tester, find.byKey(const Key('demoShow')));
    expect(find.text(demoTitle), findsOne);
    expect(find.text(en.tourDemoBadge), findsOne);

    await tap(tester, find.text(en.backToBook));
    expect(find.text(demoTitle), findsNothing);
    expect(find.text(en.watchAskTitle), findsOne);
    await tap(tester, find.byKey(const Key('watchNotNow')));
    expect(await journal(db), [SessionEventKind.start]);
    expect(w.fronts, 0);
    expect(w.opened, isNull);
    expect(w.settingsOpened, 0);
    expect(find.text(en.tourDemoAsk), findsNothing);
  });

  testApp('Open anyway in the demo opens nothing and records nothing', (
    tester,
    db,
  ) async {
    final w = FakeAppWatch();
    await throughIntro(tester, db, watch: w);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    await tap(tester, find.byKey(const Key('demoShow')));
    await tap(tester, find.text(en.openAnyway('Instagram')));
    expect(find.text(demoTitle), findsNothing);
    expect(find.text(en.stopForTonight), findsOne);
    expect(find.text(en.watchAskTitle), findsNothing, reason: 'already on');
    expect(await journal(db), [SessionEventKind.start]);
    expect(w.opened, isNull);
  });

  testApp('no tap brings up more than one explainer', (tester, db) async {
    final w = FakeAppWatch(isEnabled: false);
    await throughIntro(
      tester,
      db,
      watch: w,
      notification: FakeSessionNotification(askable: true),
    );
    expect(explainers(tester), [en.notificationAskTitle]);
    await tap(tester, find.byKey(const Key('notificationAllow')));
    expect(explainers(tester), ['aim']);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    expect(explainers(tester), [en.tourDemoAsk]);
    await tap(tester, find.byKey(const Key('demoShow')));
    expect(explainers(tester), [en.tourUrgeHint]);
    await tap(tester, find.text(en.backToBook));
    expect(explainers(tester), [en.watchAskTitle]);
    await tap(tester, find.byKey(const Key('watchNotNow')));
    expect(explainers(tester), isEmpty);
  });

  testApp('back from Accessibility settings, it says the "not yet" screen '
      'is on', (tester, db) async {
    final w = FakeAppWatch(isEnabled: false);
    await throughIntro(tester, db, watch: w);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    await tap(tester, find.byKey(const Key('demoShow')));
    await tap(tester, find.text(en.backToBook));
    await tap(tester, find.byKey(const Key('watchAgree')));
    expect(w.settingsOpened, 1);
    w.isEnabled = true;
    await comeBack(tester);
    expect(find.text(en.tourWatchOn), findsOne);
  });

  testApp('a resume without leaving for the settings says nothing yet', (
    tester,
    db,
  ) async {
    final w = FakeAppWatch(isEnabled: false);
    await throughIntro(tester, db, watch: w);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    await tap(tester, find.byKey(const Key('demoShow')));
    await tap(tester, find.text(en.backToBook));
    await tap(tester, find.byKey(const Key('watchAgree')));
    // A dialog closing, say: inactive and back, never hidden.
    [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();
    expect(find.text(en.tourWatchOff), findsNothing);
    w.isEnabled = true;
    await comeBack(tester);
    expect(find.text(en.tourWatchOn), findsOne);
  });

  testApp('back with it still off, it says so kindly and can try again', (
    tester,
    db,
  ) async {
    final w = FakeAppWatch(isEnabled: false);
    await throughIntro(tester, db, watch: w);
    await tap(tester, find.byKey(const Key('hintGotIt')));
    await tap(tester, find.byKey(const Key('demoShow')));
    await tap(tester, find.text(en.backToBook));
    await tap(tester, find.byKey(const Key('watchAgree')));
    await comeBack(tester);
    expect(find.text(en.tourWatchOff), findsOne);
    await tap(tester, find.text(en.tourWatchRetry));
    expect(w.settingsOpened, 2);
    w.isEnabled = true;
    await comeBack(tester);
    expect(find.text(en.tourWatchOn), findsOne);
  });

  testApp('without the tour, the first Start asks about notifications, and '
      'Reading offers the "not yet" screen as its own step', (
    tester,
    db,
  ) async {
    await WorkRepository(db).add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 245,
      checkpoints: const [],
    );
    final w = FakeAppWatch(isEnabled: false);
    await pumpApp(
      tester,
      db,
      watch: w,
      notification: FakeSessionNotification(askable: true),
    );
    await tap(tester, find.text(en.startReading));
    expect(explainers(tester), [en.notificationAskTitle]);
    await tap(tester, find.byKey(const Key('notificationNotNow')));
    expect(explainers(tester), [en.tourWatchAsk]);
    await tap(tester, find.byKey(const Key('watchCardTurnOn')));
    expect(explainers(tester), [en.watchAskTitle]);
    await tap(tester, find.byKey(const Key('watchAgree')));
    expect(w.settingsOpened, 1);
    expect(explainers(tester), isEmpty);
  });

  testApp('Replay the intro from Settings runs the cards and comes back', (
    tester,
    db,
  ) async {
    await WorkRepository(db).add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 245,
      checkpoints: const [],
    );
    await pumpApp(tester, db);
    await tap(tester, find.byTooltip(en.settings));
    await tap(tester, find.text(en.tourReplay));
    expect(find.text(en.tourStoryTitle), findsOne);
    await next(tester);
    await next(tester);
    await tap(tester, find.byKey(const Key('tone_chill')));
    await next(tester);
    expect(find.text(en.tourWorkTitle), findsNothing);
    expect(find.text(en.tourReplay), findsOne);
    expect(await SettingsRepository(db).tone(), Tone.chill);
    expect(await db.select(db.works).get(), hasLength(1));
  });
}
