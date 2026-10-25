import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'planned_break_fixture.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final l10n = lookupAppLocalizations(const Locale('en'));

  final live = FakeSessionNotification();

  /// The last [estimated] Checkpoints are estimates from a chapter count.
  Future<FakeBreakOverNotification> open(
    WidgetTester tester,
    AppDatabase db, {
    int estimated = 0,
  }) async {
    await addRemainsReadLastNight(db, 'en', (t) => now = t);
    await db
        .update(db.works)
        .write(WorksCompanion(estimated: Value(estimated)));
    await SettingsRepository(db).setLocale(const Locale('en'));
    final breakOver = FakeBreakOverNotification();
    await pumpApp(
      tester,
      db,
      clock: () => now,
      notification: live,
      breakOver: breakOver,
    );
    return breakOver;
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  testApp('Planned breaks: offered, nudged, taken, and taken again', (
    tester,
    db,
  ) async {
    final alarm = await open(tester, db);
    await tap(tester, l10n.startReading);

    // Page 154 after 12 minutes; chapter 5 ends at 156, two minutes on.
    await wait(tester, const Duration(minutes: 5));
    expect(find.text(l10n.nextBreakAtCheckpoint(5, 9)), findsOne);
    expect(
      find.text(l10n.breakCardStart(5)),
      findsNothing,
      reason: 'not due yet',
    );

    // Due on reading time alone, it never claims chapter 5 is done.
    await wait(tester, const Duration(minutes: 9));
    expect(find.text(l10n.breakDueAfterReading(14)), findsOne);
    expect(find.text(l10n.breakDueAtCheckpoint(5)), findsNothing);

    // Nudged: 20 minutes in, chapter 6 is too far, so the end of the page.
    await tap(tester, l10n.nudgeBreak);
    expect(find.text(l10n.nextBreakAtPage(6)), findsOne);
    expect(find.text(l10n.breakCardStart(5)), findsNothing);

    await wait(tester, const Duration(minutes: 6));
    expect(find.text(l10n.breakDueAfterReading(20)), findsOne);
    expect(alarm.set, isNull, reason: 'nothing is set until it starts');

    // One tap on the card starts the break.
    await tap(tester, l10n.breakCardStart(5));
    expect(find.text(l10n.onBreak), findsOne);
    expect(find.text('5:00'), findsOne);
    expect(find.text(l10n.chapterDone(5)), findsNothing, reason: 'unclaimed');
    expect(alarm.set?.at, DateTime(2026, 10, 22, 21, 25));
    expect(alarm.set?.title, voice(Moment.breakOver, Tone.spicy, 'en'));
    expect(alarm.set?.text, l10n.workWaiting('The Remains of the Day'));

    await wait(tester, const Duration(minutes: 5));
    expect(find.text(voice(Moment.breakOver, Tone.spicy, 'en')), findsOne);
    await tap(tester, l10n.backToReading);
    expect(alarm.set, isNull, reason: 'back, so the alarm is unset');

    // The Session goes on, toward the next break.
    expect(find.text('0:00'), findsOne);
    await wait(tester, const Duration(minutes: 12));
    expect(find.text('12:00'), findsOne);
    expect(find.text(l10n.breakDueAfterReading(12)), findsOne);
    await tap(tester, l10n.breakCardStart(3));
    expect(alarm.set?.at, DateTime(2026, 10, 22, 21, 40));

    // Back early.
    await tap(tester, l10n.imBack);
    expect(alarm.set, isNull);
    await wait(tester, const Duration(minutes: 1));
    expect(find.text('1:00'), findsOne);
  });

  testApp('Chapter done makes the break due there and moves the '
      'Position', (tester, db) async {
    final alarm = await open(tester, db);
    await tap(tester, l10n.startReading);

    // Faster than last night: chapter 5 ends at 156, done 5 minutes in.
    await wait(tester, const Duration(minutes: 5));
    await tap(tester, l10n.chapterDone(5));
    expect(find.text(l10n.breakDueAtCheckpoint(5)), findsOne);
    expect(
      find.text(l10n.chapterDone(6)),
      findsNothing,
      reason: 'the break comes first',
    );

    await tap(tester, l10n.breakCardStart(2));
    expect(find.text(l10n.chapterDone(5)), findsOne, reason: 'the chip');
    expect(find.text(l10n.backToChapterAt(6, '21:07')), findsOne);
    expect(alarm.set?.text, l10n.chapterWaiting(6));

    // The Position is already there, on Tonight's Road.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(l10n.pageOf(156, 245)), findsOne);
  });

  testApp('One tap on the due card starts the break', (tester, db) async {
    final alarm = await open(tester, db);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 14));
    await tap(tester, l10n.breakCardStart(4));
    expect(find.text(l10n.onBreak), findsOne);
    expect(find.text(l10n.startMyBreak(4)), findsNothing);
    expect(alarm.set, isNotNull);
  });

  testApp('Stop during a break unsets the alarm', (tester, db) async {
    final alarm = await open(tester, db);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 14));
    await tap(tester, l10n.breakCardStart(4));
    expect(alarm.set, isNotNull);
    expect(live.shown?.text, l10n.onBreak, reason: 'a break is no Pause');
    expect(live.shown?.runningSince, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(l10n.onBreakUntil('21:18')), findsOne);
    await tap(tester, l10n.stopForTonight);
    expect(alarm.set, isNull);
  });

  testApp('Chapter done on an estimate asks the real page, which replaces '
      'it', (tester, db) async {
    await open(tester, db, estimated: 3);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 5));

    // Not now: nothing is marked.
    await tap(tester, l10n.chapterDone(5));
    expect(find.text(l10n.chapterEndedOn(5)), findsOne);
    expect(find.text('156'), findsOne, reason: 'the estimate to start from');
    await tap(tester, l10n.chapterEndNotYet);
    expect(find.text(l10n.breakDueAtCheckpoint(5)), findsNothing);

    // Past the end is refused, with what's possible.
    await tap(tester, l10n.chapterDone(5));
    await tester.enterText(find.byKey(const Key('chapterEnd')), '245');
    await tap(tester, l10n.save);
    expect(find.text(l10n.problemChapterEnd(142, 245)), findsOne);

    await tester.enterText(find.byKey(const Key('chapterEnd')), '150');
    await tester.tap(find.byKey(const Key('chapterEndUp')));
    await tester.tap(find.byKey(const Key('chapterEndUp')));
    await tap(tester, l10n.save);
    expect(find.text(l10n.breakDueAtCheckpoint(5)), findsOne);

    // The Position is at the real end; the rest are spread on from there.
    final row = await tester.runAsync(() => db.select(db.works).getSingle());
    expect(row!.position, 152);
    expect(row.checkpoints, '34,66,98,128,152,183,214');
    expect(row.estimated, 2);
  });
}
