import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final start = DateTime(2026, 10, 22, 21);
  final fourAm = DateTime(2026, 10, 23, 4);
  var now = start;
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));

  Future<String> addBook(AppDatabase db, {String lang = 'en'}) async {
    now = start;
    await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(Locale(lang));
    return (await db.select(db.works).getSingle()).id;
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testApp('with no Work yet, the widget asks for one', (tester, db) async {
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(widget.shown?.title, en.appTitle);
    expect(widget.shown?.road, en.tonightEmpty);
    expect(widget.shown?.button, en.tonightAddBook);
    expect(widget.shown?.workId, isNull);
    expect(widget.shown?.sessionId, isNull);
    expect(widget.shown?.litUntil, isNull);
    expect(widget.shown?.floors, 0, reason: 'no Building yet');
  });

  testApp('the Building widget grows a floor with each Finish', (
    tester,
    db,
  ) async {
    await addBook(db);
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(widget.shown?.floors, 0);
    expect(widget.shown?.litUntil, isNull, reason: "tonight's Window is dark");

    await tap(tester, find.text(en.startReading));
    await wait(tester, const Duration(minutes: 30));
    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), '245');
    await tap(tester, find.text(en.saveAndLightsOut));
    expect(widget.shown?.floors, 1, reason: 'the Finish adds a floor');
    expect(widget.shown?.litUntil, fourAm, reason: "tonight's Window is lit");
  });

  testApp("the widget follows the Road and tonight's Window", (
    tester,
    db,
  ) async {
    final work = await addBook(db);
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(widget.shown, (
      title: 'The Remains of the Day',
      road: en.pageOf(0, 245),
      evenings: null,
      lit: en.widgetLit,
      dark: en.widgetDark,
      litUntil: null,
      button: en.startReading,
      sessionId: null,
      workId: work,
      rtl: false,
      floors: 0,
    ));

    await tap(tester, find.text(en.startReading));
    final session = (await db.select(db.sessionEvents).get()).first.sessionId;
    expect(
      widget.shown?.litUntil,
      fourAm,
      reason: 'lit until the evening ends',
    );
    expect(widget.shown?.button, en.backToReading);
    expect(widget.shown?.sessionId, session);
    expect(widget.shown?.workId, isNull);

    final sent = widget.sent.length;
    await wait(tester, const Duration(minutes: 5));
    await tap(tester, find.text(en.pause));
    expect(widget.sent, hasLength(sent), reason: 'nothing on it changed');

    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), '35');
    await tap(tester, find.text(en.saveAndLightsOut));
    expect(widget.shown?.road, en.pageOf(35, 245));
    expect(widget.shown?.evenings, en.widgetEvenings(6));
    expect(widget.shown?.button, en.startReading);
    expect(widget.shown?.workId, work);
    expect(widget.shown?.litUntil, fourAm, reason: 'still tonight');
  });

  testApp('the widget speaks Persian, right to left, with Persian digits', (
    tester,
    db,
  ) async {
    await addBook(db, lang: 'fa');
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(widget.shown?.rtl, isTrue);
    expect(widget.shown?.road, fa.pageOf(0, 245));
    expect(widget.shown?.road, contains('۲۴۵'));
    expect(widget.shown?.button, fa.startReading);

    await tap(tester, find.byIcon(Icons.tune));
    await tap(tester, find.text('English'));
    expect(widget.shown?.rtl, isFalse, reason: 'it follows the app language');
    expect(widget.shown?.road, en.pageOf(0, 245));
  });

  testApp('Start on the widget opens straight into a Session', (
    tester,
    db,
  ) async {
    final work = await addBook(db);
    final widget = FakeHomeWidget(opened: work);
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(find.text('0:00'), findsOne);
    expect(widget.shown?.button, en.backToReading);
  });

  testApp('Start on the widget while the app is alive', (tester, db) async {
    final work = await addBook(db);
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);

    widget.onStart!(work);
    await tester.pumpAndSettle();
    expect(find.text('0:00'), findsOne);

    // A stale widget still says Start: it goes back to the open Session.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await wait(tester, const Duration(minutes: 3));
    widget.onStart!(work);
    await tester.pumpAndSettle();
    expect(find.text('3:00'), findsOne);
    final sessions = (await db.select(db.sessionEvents).get())
        .map((e) => e.sessionId)
        .toSet();
    expect(sessions, hasLength(1));
  });

  /// A Session open on the first Work, with a second Work made current
  /// since; returns the second Work's id.
  Future<String> openOnAnotherWork(AppDatabase db) async {
    final first = await addBook(db);
    await SessionRepository(db, clock: () => now).start(first);
    final works = WorkRepository(db);
    final second = await works.add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 272,
      checkpoints: const [],
    );
    await works.setCurrent(second);
    return second;
  }

  Future<Set<String>> sessionIds(AppDatabase db) async =>
      (await db.select(db.sessionEvents).get()).map((e) => e.sessionId).toSet();

  testApp('Start on the widget opens the Session running on another Work', (
    tester,
    db,
  ) async {
    final second = await openOnAnotherWork(db);
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);

    widget.onStart!(second);
    await tester.pumpAndSettle();
    expect(await sessionIds(db), hasLength(1), reason: 'no second Session');
    expect(find.text('The Remains of the Day'), findsOne);
  });

  testApp('Start on the widget, starting the app, opens the open Session', (
    tester,
    db,
  ) async {
    final second = await openOnAnotherWork(db);
    final widget = FakeHomeWidget(opened: second);
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(await sessionIds(db), hasLength(1), reason: 'no second Session');
    expect(find.text('The Remains of the Day'), findsOne);
  });

  testApp('a Session started elsewhere shows on the widget', (
    tester,
    db,
  ) async {
    final work = await addBook(db);
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    final id = await SessionRepository(db, clock: () => now).start(work);
    await tester.pumpAndSettle();
    expect(widget.shown?.sessionId, id);
  });

  testApp('a podcast on the widget is a timestamp, and listening', (
    tester,
    db,
  ) async {
    now = start;
    await WorkRepository(db).add(
      title: 'Radio Marz',
      author: '',
      totalPages: 9660,
      checkpoints: const [],
      kind: WorkKind.podcast,
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    final widget = FakeHomeWidget();
    await pumpApp(tester, db, clock: () => now, homeWidget: widget);
    expect(widget.shown?.road, en.timeOf('0:00', '2:41:00'));
    expect(widget.shown?.button, en.startWork('podcast'));

    await tap(tester, find.text(en.startWork('podcast')));
    await wait(tester, const Duration(minutes: 20));
    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), '1:12:20');
    await tap(tester, find.text(en.saveAndLightsOut));
    expect(widget.shown?.road, en.timeOf('1:12:20', '2:41:00'));
    // 4340 seconds in one evening, 5320 to go: about 2 more.
    expect(widget.shown?.evenings, en.widgetEvenings(2));
  });
}
