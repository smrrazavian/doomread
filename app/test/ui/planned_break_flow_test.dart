import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'planned_break_fixture.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final l10n = lookupAppLocalizations(const Locale('en'));

  final live = FakeSessionNotification();

  Future<FakeBreakOverNotification> open(
    WidgetTester tester,
    AppDatabase db,
  ) async {
    await addRemainsReadLastNight(db, 'en', (t) => now = t);
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
    expect(find.text(l10n.takeBreak), findsNothing, reason: 'not due yet');

    await wait(tester, const Duration(minutes: 9));
    expect(find.text(l10n.breakDueAtCheckpoint(5)), findsOne);

    // Nudged: 20 minutes in, chapter 6 is too far, so the end of the page.
    await tap(tester, l10n.nudgeBreak);
    expect(find.text(l10n.nextBreakAtPage(6)), findsOne);
    expect(find.text(l10n.takeBreak), findsNothing);

    await wait(tester, const Duration(minutes: 6));
    expect(find.text(l10n.breakDueAtPage), findsOne);
    await tap(tester, l10n.takeBreak);
    expect(find.text(l10n.breakHere), findsOne);
    expect(find.text(l10n.backToBookAt('21:25')), findsOne);
    expect(alarm.set, isNull, reason: 'nothing is set until it starts');

    await tap(tester, l10n.startMyBreak(5));
    expect(find.text(l10n.onBreak), findsOne);
    expect(find.text('5:00'), findsOne);
    expect(alarm.set?.at, DateTime(2026, 10, 22, 21, 25));
    expect(alarm.set?.title, l10n.breakOver);
    expect(alarm.set?.text, l10n.workWaiting('The Remains of the Day'));

    await wait(tester, const Duration(minutes: 5));
    expect(find.text(l10n.breakOver), findsOne);
    await tap(tester, l10n.backToReading);
    expect(alarm.set, isNull, reason: 'back, so the alarm is unset');

    // The Session goes on, toward the next break.
    expect(find.text('0:00'), findsOne);
    await wait(tester, const Duration(minutes: 12));
    expect(find.text('12:00'), findsOne);
    expect(find.text(l10n.breakDueAtPage), findsOne);
    await tap(tester, l10n.takeBreak);
    await tap(tester, l10n.startMyBreak(3));
    expect(alarm.set?.at, DateTime(2026, 10, 22, 21, 40));

    // Back early.
    await tap(tester, l10n.imBack);
    expect(alarm.set, isNull);
    await wait(tester, const Duration(minutes: 1));
    expect(find.text('1:00'), findsOne);
  });

  testApp('Keep reading instead nudges the break later', (tester, db) async {
    await open(tester, db);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 14));
    await tap(tester, l10n.takeBreak);
    expect(find.text(l10n.chapterDone(5)), findsOne);
    expect(find.text(l10n.backToChapterAt(6, '21:18')), findsOne);

    await tap(tester, l10n.keepReading);
    expect(find.text(l10n.nextBreakAtPage(6)), findsOne);
  });

  testApp('Stop during a break unsets the alarm', (tester, db) async {
    final alarm = await open(tester, db);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 14));
    await tap(tester, l10n.takeBreak);
    await tap(tester, l10n.startMyBreak(4));
    expect(alarm.set, isNotNull);
    expect(live.shown?.text, l10n.onBreak, reason: 'a break is no Pause');
    expect(live.shown?.runningSince, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(l10n.onBreakUntil('21:18')), findsOne);
    await tap(tester, l10n.stopForTonight);
    expect(alarm.set, isNull);
  });
}
