import 'dart:typed_data';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread/ui/share/widgets/yalda_poster.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final yaldaLine = en.yaldaTonight('paperBook');

  /// The Remains of the Day as the current Work, read for [minutes] from
  /// 21:00 on [day] December 2026 if [minutes] isn't null, up to [page].
  /// Returns its id.
  Future<String> setUp(
    AppDatabase db,
    int day, {
    int? minutes,
    int page = 20,
  }) async {
    var now = DateTime(2026, 12, day, 21);
    final id = await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    if (minutes == null) return id;
    final sessions = SessionRepository(db, clock: () => now);
    final record = SessionRecord(
      id: await sessions.start(id),
      road: Road(
        Work(id: id, title: '', author: '', totalPages: 245, checkpoints: []),
        position: 0,
      ),
      events: const [],
    );
    now = now.add(Duration(minutes: minutes));
    await sessions.add(record, SessionEventKind.stop);
    await sessions.end(record, page: page);
    return id;
  }

  testApp('Tonight says nothing of Yalda the night before', (tester, db) async {
    await setUp(db, 20, minutes: 30);
    await pumpApp(tester, db, clock: () => DateTime(2026, 12, 20, 23));
    expect(find.text(yaldaLine), findsNothing);
    expect(find.text(en.yaldaShare), findsNothing);
  });

  testApp('on Yalda, Tonight has its line, and no poster before reading', (
    tester,
    db,
  ) async {
    await setUp(db, 21);
    await pumpApp(tester, db, clock: () => DateTime(2026, 12, 21, 20));
    expect(find.text(yaldaLine), findsOne);
    expect(find.text(en.yaldaShare), findsNothing);
  });

  testApp('after reading on Yalda, past midnight, the poster shares', (
    tester,
    db,
  ) async {
    final sheet = FakeShareSheet();
    await setUp(db, 21, minutes: 47);
    await pumpApp(
      tester,
      db,
      clock: () => DateTime(2026, 12, 22, 0, 30),
      share: sheet,
    );
    expect(find.text(yaldaLine), findsOne);

    await tester.tap(find.text(en.yaldaShare));
    await tester.pumpAndSettle();
    final poster = tester.widget<YaldaPoster>(find.byType(YaldaPoster));
    expect(poster.minutes, 47);
    expect(poster.work.title, 'The Remains of the Day');
    expect(poster.house, [HouseWindow.yours]);
    expect(tester.widget<HouseView>(find.byType(HouseView)).yalda, isTrue);
    expect(find.text(en.yaldaPosterNight('2026')), findsOne);

    await tester.tap(find.text(en.shareSend));
    // Drawing the image is real work, outside the test's fake time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();
    final header = ByteData.sublistView(sheet.shared.single.png);
    expect((header.getUint32(16), header.getUint32(20)), (1080, 1920));
  });

  testApp('a Work finished on Yalda keeps its night on Tonight', (
    tester,
    db,
  ) async {
    await setUp(db, 21, minutes: 52, page: 245);
    // Finished, and no longer the current Work.
    await (db.delete(
      db.settings,
    )..where((s) => s.key.equals('currentWork'))).go();
    await pumpApp(tester, db, clock: () => DateTime(2026, 12, 21, 23));
    expect(find.text(yaldaLine), findsOne);
    expect(find.text(en.yaldaShare), findsOne);
  });

  testApp('the Finish on Yalda offers the Yalda poster too', (
    tester,
    db,
  ) async {
    final id = await setUp(db, 21, minutes: 52, page: 245);
    await pumpApp(tester, db, clock: () => DateTime(2026, 12, 21, 23));
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/building/finish/$id');
    await tester.pumpAndSettle();
    expect(find.text(en.shareAction), findsOne);
    await tester.tap(find.text(en.yaldaShare));
    await tester.pumpAndSettle();
    expect(tester.widget<YaldaPoster>(find.byType(YaldaPoster)).minutes, 52);
  });

  testApp('the Finish on another night has no Yalda poster', (
    tester,
    db,
  ) async {
    final id = await setUp(db, 22, minutes: 52, page: 245);
    await pumpApp(tester, db, clock: () => DateTime(2026, 12, 22, 23));
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/building/finish/$id');
    await tester.pumpAndSettle();
    expect(find.text(en.shareAction), findsOne);
    expect(find.text(en.yaldaShare), findsNothing);
  });
}
