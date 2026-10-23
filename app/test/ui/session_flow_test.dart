import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<void> openWithBook(WidgetTester tester, AppDatabase db) async {
    now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      const WorksCompanion(position: Value(142)),
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testApp('a Session from Start to Stop moves the Position and sets the Aim', (
    tester,
    db,
  ) async {
    await openWithBook(tester, db);
    expect(find.text(l10n.aim(1)), findsOne);
    expect(find.text(l10n.eveningsLeft(7)), findsNothing);
    expect(find.text(l10n.readingWeekCount(0)), findsOne);

    await tap(tester, l10n.startReading);
    expect(find.text('0:00'), findsOne);
    await wait(tester, const Duration(minutes: 5, seconds: 12));
    expect(find.text('5:12'), findsOne);
    expect(find.text(l10n.aimReached), findsOne);

    await tap(tester, l10n.pause);
    expect(find.text(l10n.paused), findsOne);
    await wait(tester, const Duration(minutes: 2));
    expect(find.text('5:12'), findsOne, reason: 'a Pause stops the clock');

    await tap(tester, l10n.resume);
    await wait(tester, const Duration(minutes: 3));
    expect(find.text('3:00'), findsOne, reason: 'a Pause ends the Stretch');

    await tap(tester, l10n.stopForTonight);
    expect(find.text(l10n.newBestStretch), findsOne);
    expect(find.text(l10n.inOneGoTonight(5)), findsOne);

    await tester.enterText(find.byKey(const Key('page')), '100');
    await tap(tester, l10n.saveAndLightsOut);
    expect(find.text(l10n.problemPageOutOfRange(142, 245)), findsOne);

    await tester.enterText(find.byKey(const Key('page')), '۱۵۶');
    await tester.enterText(
      find.byKey(const Key('note')),
      'Stevens misses Miss Kenton, only to himself.',
    );
    await tap(tester, l10n.saveAndLightsOut);

    expect(find.text(l10n.pageOf(156, 245)), findsOne);
    // 89 pages left at 14 pages an evening.
    expect(find.text(l10n.eveningsLeft(7)), findsOne);
    // 5:12 plus a minute, rounded up.
    expect(find.text(l10n.aim(7)), findsOne);
    expect(find.text(l10n.readingWeekCount(1)), findsOne);
    final note = await db.select(db.notes).getSingle();
    expect((note.fromPage, note.toPage), (142, 156));
    expect(note.body, 'Stevens misses Miss Kenton, only to himself.');
  });

  testApp('the next Session only shows a new best when it beats the last', (
    tester,
    db,
  ) async {
    await openWithBook(tester, db);
    Future<void> session(Duration length, int page) async {
      await tap(tester, l10n.startReading);
      await wait(tester, length);
      await tap(tester, l10n.stopForTonight);
      await tester.enterText(find.byKey(const Key('page')), '$page');
      await tap(tester, l10n.saveAndLightsOut);
    }

    await session(const Duration(minutes: 9), 150);
    await tap(tester, l10n.startReading);
    expect(find.text('${l10n.aim(10)} ${l10n.aimToGo(10)}'), findsOne);
    await wait(tester, const Duration(minutes: 7));
    await tap(tester, l10n.stopForTonight);
    expect(find.text(l10n.newBestStretch), findsNothing);
  });

  testApp('a Session left open is offered again on Tonight', (
    tester,
    db,
  ) async {
    await openWithBook(tester, db);
    await tap(tester, l10n.startReading);
    await wait(tester, const Duration(minutes: 2));
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tap(tester, l10n.backToReading);
    expect(find.text('2:00'), findsOne);
  });
}
