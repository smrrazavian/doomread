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
  var now = DateTime(2026, 10, 22, 21);
  final l10n = lookupAppLocalizations(const Locale('en'));
  const instagram = 'com.instagram.android';

  Future<FakeAppWatch> startReading(
    WidgetTester tester,
    AppDatabase db, {
    FakeAppWatch? watch,
  }) async {
    now = DateTime(2026, 10, 22, 21);
    await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    final w = watch ?? FakeAppWatch();
    await pumpApp(tester, db, clock: () => now, watch: w);
    await tester.tap(find.text(l10n.startReading));
    await tester.pumpAndSettle();
    return w;
  }

  Future<void> wait(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<List<SessionEventKind>> journal(AppDatabase db) async => [
    for (final e in await db.select(db.sessionEvents).get()) e.kind,
  ];

  Future<void> open(WidgetTester tester, FakeAppWatch w, String app) async {
    w.onForeground!(app, 'Instagram', const {});
    await tester.pumpAndSettle();
  }

  testApp('watches apps only while a Session is open', (tester, db) async {
    final w = await startReading(tester, db);
    expect(w.watching, isTrue);
    await tap(tester, l10n.stopForTonight);
    expect(w.watching, isFalse);
  });

  testApp('a Watched app brings up the Urge, and Back keeps the Stretch', (
    tester,
    db,
  ) async {
    final w = await startReading(tester, db);
    await wait(tester, const Duration(minutes: 4));
    await open(tester, w, instagram);
    expect(find.text(l10n.urgeTitle('Instagram')), findsOne);
    expect(w.fronts, 1);

    await wait(tester, const Duration(minutes: 1));
    await tap(tester, l10n.backToBook);
    expect(find.text(l10n.urgeTitle('Instagram')), findsNothing);
    expect(find.text('5:00'), findsOne, reason: 'Let pass keeps the Stretch');
    expect(await journal(db), [
      SessionEventKind.start,
      SessionEventKind.urge,
      SessionEventKind.letPass,
    ]);
  });

  testApp('an app that is not Watched raises nothing', (tester, db) async {
    final w = await startReading(tester, db);
    await open(tester, w, 'org.example.reader');
    expect(find.text(l10n.urgeTitle('Instagram')), findsNothing);
    expect(w.fronts, 0);
  });

  testApp('Open anyway is a Slip, then the kind After-a-slip screen', (
    tester,
    db,
  ) async {
    final w = await startReading(tester, db);
    await wait(tester, const Duration(minutes: 6));
    await open(tester, w, instagram);
    await tap(tester, l10n.openAnyway('Instagram'));
    expect(w.opened, instagram);
    expect(find.text(l10n.slipTitle), findsOne);
    expect(find.text(l10n.slipBody(6)), findsOne);

    // The service then reports Instagram, which the user chose.
    await open(tester, w, instagram);
    expect(w.fronts, 1);
    expect(find.text(l10n.slipTitle), findsOne);

    await tap(tester, l10n.backIn);
    await wait(tester, const Duration(minutes: 2));
    expect(find.text('2:00'), findsOne, reason: 'the Slip ended the Stretch');
    expect((await journal(db)).sublist(1), [
      SessionEventKind.urge,
      SessionEventKind.slip,
      SessionEventKind.resume,
    ]);
  });

  testApp('back to a Watched app with the Urge up raises no second one', (
    tester,
    db,
  ) async {
    final w = await startReading(tester, db);
    await open(tester, w, instagram);
    await open(tester, w, instagram);
    expect(w.fronts, 2, reason: 'the Urge comes to the front again');
    expect(await journal(db), [SessionEventKind.start, SessionEventKind.urge]);
  });

  testApp('nothing is raised while paused', (tester, db) async {
    final w = await startReading(tester, db);
    await tap(tester, l10n.pause);
    await open(tester, w, instagram);
    expect(w.fronts, 0);
    expect(find.text(l10n.paused), findsOne);
  });

  testApp('nothing is raised on a Planned break', (tester, db) async {
    final w = await startReading(tester, db);
    await tester.runAsync(() async {
      final sessions = SessionRepository(db, clock: () => now);
      final record = (await sessions.watchAll().first).single;
      await sessions.add(record, SessionEventKind.breakStart);
    });
    await tester.pumpAndSettle();
    await open(tester, w, instagram);
    expect(w.fronts, 0);
  });

  testApp('Done for tonight after a Slip goes to End of the evening', (
    tester,
    db,
  ) async {
    final w = await startReading(tester, db);
    await open(tester, w, instagram);
    await tap(tester, l10n.openAnyway('Instagram'));
    await tap(tester, l10n.doneForTonight);
    expect(find.text(l10n.saveAndLightsOut), findsOne);
  });

  testApp('with usage access only, the service polls and the Urge still '
      'comes', (tester, db) async {
    final w = await startReading(
      tester,
      db,
      watch: FakeAppWatch(isEnabled: false, usageAccess: true, overlay: true),
    );
    expect(w.polling, isTrue);
    await open(tester, w, instagram);
    expect(find.text(l10n.urgeTitle('Instagram')), findsOne);
    await tap(tester, l10n.backToBook);
    await tap(tester, l10n.stopForTonight);
    expect(w.polling, isFalse);
  });

  testApp('with Accessibility on, nothing polls', (tester, db) async {
    final w = await startReading(
      tester,
      db,
      watch: FakeAppWatch(usageAccess: true, overlay: true),
    );
    expect(w.watching, isTrue);
    expect(w.polling, isFalse);
  });
}
