import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/reading/widgets/desk_view.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread/ui/tasks/widgets/task_list.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));
  final today = DateTime(2026, 10, 22);
  const report = 'Write the Q3 report';

  Future<String> addReport(AppDatabase db) =>
      WorkRepository(db).addTask(name: report, day: today);

  Future<String> addBook(AppDatabase db) => WorkRepository(db).add(
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: const [],
  );

  Future<void> open(
    WidgetTester tester,
    AppDatabase db, {
    FakeSessionNotification? notification,
    FakeAppWatch? watch,
  }) async {
    now = DateTime(2026, 10, 22, 21);
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(
      tester,
      db,
      clock: () => now,
      notification: notification,
      watch: watch,
    );
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  final start = find.text(en.startWork('task'));

  // A plain query: watching the Works waits on drift timers that fake time
  // never fires.
  Future<Task> task(AppDatabase db) async =>
      WorkRepository.toTask(await db.select(db.works).getSingle());

  testApp('a Task Session: the clock is the pause button, and Stop for now '
      'goes back to Today with the Task undone', (tester, db) async {
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    expect(find.text(en.taskWorkingOn), findsOne);
    expect(find.text(report), findsOne);
    expect(find.byType(DeskView), findsOne);
    expect(find.byType(HouseView), findsNothing);

    await wait(tester, const Duration(minutes: 6));
    expect(find.text('6:00'), findsOne);
    expect(find.text(en.taskClockRunning), findsOne);

    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(find.text(en.taskClockPaused), findsOne);
    await wait(tester, const Duration(minutes: 2));
    expect(find.text('6:00'), findsOne, reason: 'paused');
    expect(find.text(en.stretchSoFar(1, 6)), findsNothing, reason: 'the same');
    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(find.text(en.taskClockRunning), findsOne);
    await wait(tester, const Duration(minutes: 1));
    expect(find.text('1:00'), findsOne, reason: 'a new Stretch');
    expect(
      find.text(en.stretchSoFar(2, 7)),
      findsOne,
      reason: 'the time before the Pause still counts',
    );

    await tap(tester, find.text(en.taskStop));
    expect(find.text(en.taskAdd), findsOne, reason: 'back on Today');
    expect(find.text(en.whichPage), findsNothing, reason: 'nothing asked');
    expect((await task(db)).done, isFalse);
    expect(start, findsOne);
  });

  testApp('a Stop for now by mistake is taken back from Today', (
    tester,
    db,
  ) async {
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    await wait(tester, const Duration(minutes: 4));
    await tap(tester, find.text(en.taskStop));
    expect(find.text(en.stoppedByMistake), findsOne);

    await tap(tester, find.text(en.resume));
    expect(find.text(en.taskWorkingOn), findsOne);
    expect(find.text(en.taskClockRunning), findsOne);
    final sessions = await SessionRepository(db, clock: () => now).all();
    expect(sessions.single.at(now).stopped, isFalse);
  });

  testApp('the Stop is offered back on Today however the Session opened', (
    tester,
    db,
  ) async {
    final id = await addReport(db);
    final session = await SessionRepository(db, clock: () => now).start(id);
    final notification = FakeSessionNotification(opened: session);
    await pumpApp(tester, db, clock: () => now, notification: notification);
    await tester.pumpAndSettle();
    expect(find.text(en.taskWorkingOn), findsOne);

    await tap(tester, find.text(en.taskStop));
    expect(find.text(en.taskAdd), findsOne, reason: 'on Today');
    expect(find.text(en.stoppedByMistake), findsOne);
  });

  testApp('a clock past an hour still fits', (tester, db) async {
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    await wait(tester, const Duration(hours: 1, minutes: 5, seconds: 12));
    expect(find.text('1:05:12'), findsOne);
    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(find.text(en.taskClockPaused), findsOne);
  });

  testApp('Done ends the Session and lights the Task on Today', (
    tester,
    db,
  ) async {
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    await wait(tester, const Duration(minutes: 38));
    await tap(tester, find.text(en.taskDone));
    expect(find.text(en.doneTitle(report)), findsOne, reason: 'the moment');
    await tap(tester, find.text(en.doneBreather));

    expect(find.text(en.taskDoneAt('21:38', 38)), findsOne);
    expect(tester.widget<TaskWindow>(find.byType(TaskWindow)).lit, isTrue);
    final sessions = await SessionRepository(db, clock: () => now).all();
    expect(sessions.single.at(now).stopped, isTrue);
  });

  testApp('working keeps its own Aim, apart from reading', (tester, db) async {
    // Half an hour of reading last night sets reading's Aim, not work's.
    final book = await addBook(db);
    var at = DateTime(2026, 10, 21, 21);
    final journal = SessionRepository(db, clock: () => at);
    final record = SessionRecord(
      id: await journal.start(book),
      road: Road(
        Work(id: book, title: '', author: '', totalPages: 245, checkpoints: []),
        position: 0,
      ),
      events: const [],
    );
    at = at.add(const Duration(minutes: 30));
    await journal.add(record, SessionEventKind.stop);
    await addReport(db);
    await open(tester, db);
    expect(find.text(en.aim(31)), findsOne, reason: "reading's Aim");

    await tap(tester, start);
    expect(find.text(en.taskAim(1)), findsOne);
    await wait(tester, const Duration(seconds: 70));
    expect(find.text(en.taskAimBeaten), findsOne);
  });

  testApp('a Task Session stays out of the Reading week and the House', (
    tester,
    db,
  ) async {
    await addBook(db);
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    await wait(tester, const Duration(minutes: 10));
    await tap(tester, find.text(en.taskStop));

    expect(find.text(en.readingWeekCount(0)), findsOne);
    await tester.ensureVisible(find.text(en.startReading));
    await tester.pumpAndSettle();
    await tap(tester, find.text(en.startReading));
    expect(tester.widget<HouseView>(find.byType(HouseView)).windows, [
      HouseWindow.yours,
    ], reason: 'only the book lights a Window');
  });

  testApp('the Planned break on a Task is time-based and names no '
      'chapter', (tester, db) async {
    await addReport(db);
    await open(tester, db);
    await tap(tester, start);
    expect(find.text(en.nextBreakWorking(12)), findsOne);
    await wait(tester, const Duration(minutes: 12));
    expect(find.text(en.breakDueAfterWorking(12)), findsOne);
    await tap(tester, find.text(en.breakCardStart(3)));
    expect(find.text(en.onBreak), findsOne);
    expect(find.text(en.backToWorkAt('21:15')), findsOne);
  });

  testApp('the Urge during a Task names it, over the desk', (tester, db) async {
    await addReport(db);
    final watch = FakeAppWatch();
    await open(tester, db, watch: watch);
    await tap(tester, start);
    await wait(tester, const Duration(minutes: 3));
    watch.onForeground!('com.instagram.android', 'Instagram', const {});
    await tester.pumpAndSettle();

    expect(
      find.text(
        voice(Moment.urgeTask, Tone.spicy, 'en', const {
          'task': report,
          'app': 'Instagram',
        }),
      ),
      findsOne,
    );
    expect(find.byType(DeskView), findsOne);
    await tap(tester, find.text(en.backToWork('task')));
    expect(find.text(en.taskWorkingOn), findsOne);
  });

  testApp('starting a Task while another runs asks to stop that one '
      'first', (tester, db) async {
    await addReport(db);
    await WorkRepository(db).addTask(name: 'Call the bank', day: today);
    await open(tester, db);
    await tap(tester, start.first);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // "Not now" leaves things as they are.
    await tap(tester, find.text(en.startWork('task')).last);
    expect(find.text(en.oneSessionTitle(report)), findsOne);
    await tap(tester, find.byKey(const Key('oneSessionNotNow')));
    expect(find.text(en.taskAdd), findsOne);

    await tap(tester, find.text(en.startWork('task')).last);
    await tap(tester, find.byKey(const Key('oneSessionStop')));
    expect(find.text('Call the bank'), findsOne);
    expect(find.text(en.taskWorkingOn), findsOne);
    final all = await SessionRepository(db, clock: () => now).all();
    expect([for (final r in all) r.at(now).stopped], [true, false]);
  });

  testApp('starting a Task while a book runs stops the book for its '
      'End of the evening first', (tester, db) async {
    await addBook(db);
    await addReport(db);
    await open(tester, db);
    await tester.ensureVisible(find.text(en.startReading));
    await tester.pumpAndSettle();
    await tap(tester, find.text(en.startReading));
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(start, -200);
    await tap(tester, start);
    await tap(tester, find.byKey(const Key('oneSessionStop')));
    expect(find.text(en.whichPage), findsOne);
  });

  testApp('the notification offers Done, which ends it and lights the '
      'Task', (tester, db) async {
    await addReport(db);
    final notification = FakeSessionNotification();
    await open(tester, db, notification: notification);
    await tap(tester, start);
    expect(notification.shown?.title, report);
    expect(notification.shown?.done, en.taskDone);

    await wait(tester, const Duration(minutes: 12));
    await tap(tester, find.text(en.breakCardStart(3)));
    expect(notification.shown?.done, isNull, reason: 'not on a break');
    await tap(tester, find.text(en.imBack));
    expect(notification.shown?.done, en.taskDone);

    notification.onDone!(notification.shown!.sessionId);
    await tester.pumpAndSettle();
    expect((await task(db)).done, isTrue);
    expect(notification.shown, isNull);
    expect(find.text(en.doneTitle(report)), findsOne, reason: 'the moment');
    await tap(tester, find.text(en.doneBreather));
    expect(find.text(en.taskAdd), findsOne, reason: 'on Today');
  });

  testApp('Done on the notification works when it starts the app', (
    tester,
    db,
  ) async {
    final id = await addReport(db);
    final session = await SessionRepository(db, clock: () => now).start(id);
    now = now.add(const Duration(minutes: 5));
    final notification = FakeSessionNotification()..doneOpened = session;
    await pumpApp(tester, db, clock: () => now, notification: notification);
    await tester.pumpAndSettle();
    expect((await task(db)).done, isTrue);
    expect(find.text(en.doneTitle(report)), findsOne);
  });
}
