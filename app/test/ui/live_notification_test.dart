import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final start = DateTime(2026, 10, 22, 21);
  var now = start;
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));

  Future<void> addBook(AppDatabase db, {String lang = 'en'}) async {
    now = start;
    await WorkRepository(db).add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 272,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(Locale(lang));
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  final startButton = find.byType(FilledButton);

  testApp('the notification follows the journal from Start to Stop', (
    tester,
    db,
  ) async {
    await addBook(db);
    final notification = FakeSessionNotification();
    await pumpApp(tester, db, clock: () => now, notification: notification);
    expect(notification.shown, isNull);

    await tap(tester, startButton);
    expect(notification.shown?.title, 'Piranesi');
    expect(notification.shown?.text, en.aim(1));
    expect(notification.shown?.runningSince, start);

    await wait(tester, const Duration(minutes: 5, seconds: 12));
    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(notification.shown?.runningSince, isNull, reason: 'paused');
    expect(notification.shown?.text, en.notificationPaused('5:12'));

    await wait(tester, const Duration(minutes: 2));
    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(
      notification.shown?.runningSince,
      start.add(const Duration(minutes: 7, seconds: 12)),
      reason: 'the chronometer counts the new Stretch',
    );

    await tap(tester, find.text(en.stopForTonight));
    expect(notification.shown, isNull);
  });

  testApp('the notification speaks the app language, with Persian digits', (
    tester,
    db,
  ) async {
    await addBook(db, lang: 'fa');
    final notification = FakeSessionNotification();
    await pumpApp(tester, db, clock: () => now, notification: notification);
    await tap(tester, startButton);
    await wait(tester, const Duration(minutes: 5, seconds: 12));
    await tap(tester, find.byKey(const Key('sessionClock')));
    expect(notification.shown?.text, fa.notificationPaused('۵:۱۲'));
  });

  testApp('after the app was killed, the running Session comes back', (
    tester,
    db,
  ) async {
    await addBook(db);
    await pumpApp(tester, db, clock: () => now);
    await tap(tester, startButton);
    await wait(tester, const Duration(minutes: 2));

    // Killed: nothing is left running but the journal.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    now = now.add(const Duration(minutes: 40));

    final notification = FakeSessionNotification();
    await pumpApp(tester, db, clock: () => now, notification: notification);
    expect(notification.shown?.runningSince, start);
    expect(find.text(en.backToReading), findsOne);
    await tap(tester, startButton);
    expect(find.text('42:00'), findsOne);
  });

  testApp('a tap on the notification opens its Session over Tonight', (
    tester,
    db,
  ) async {
    await addBook(db);
    final work = (await db.select(db.works).getSingle()).id;
    final id = await SessionRepository(db, clock: () => now).start(work);
    now = now.add(const Duration(minutes: 3));

    final notification = FakeSessionNotification(opened: id);
    await pumpApp(tester, db, clock: () => now, notification: notification);
    expect(find.text('3:00'), findsOne);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(en.backToReading), findsOne);

    notification.onTapped!(id);
    await tester.pumpAndSettle();
    expect(find.text('3:00'), findsOne);
  });

  testApp('the permission is explained once, on the first Start', (
    tester,
    db,
  ) async {
    await addBook(db);
    final notification = FakeSessionNotification(askable: true);
    await pumpApp(tester, db, clock: () => now, notification: notification);

    await tap(tester, startButton);
    expect(find.text(en.notificationAskBody), findsOne);
    await tap(tester, find.byKey(const Key('notificationAllow')));
    expect(notification.asks, 1);
    expect(find.text('0:00'), findsOne, reason: 'the Session started');
  });

  testApp('"not now" starts the Session and never asks again', (
    tester,
    db,
  ) async {
    await addBook(db);
    final notification = FakeSessionNotification(askable: true);
    await pumpApp(tester, db, clock: () => now, notification: notification);

    await tap(tester, startButton);
    await tap(tester, find.byKey(const Key('notificationNotNow')));
    expect(notification.asks, 0);
    expect(find.text('0:00'), findsOne, reason: 'the Session started');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, startButton);
    expect(find.byKey(const Key('notificationNotNow')), findsNothing);
    expect(find.text('0:00'), findsOne);
  });
}
