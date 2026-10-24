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
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));
  const title = 'The Remains of the Day';

  Future<void> openAt(
    WidgetTester tester,
    AppDatabase db,
    int page, {
    String lang = 'en',
  }) async {
    now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: title,
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      WorksCompanion(position: Value(page)),
    );
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// From Tonight to End of the evening, after [minutes] in one go.
  Future<void> readFor(
    WidgetTester tester,
    int minutes, [
    AppLocalizations? l10n,
  ]) async {
    l10n ??= en;
    await tap(tester, find.text(l10n.startReading));
    now = now.add(Duration(minutes: minutes));
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.text(l10n.stopForTonight));
  }

  String pageField(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const Key('page'))).controller!.text;

  Future<int> position(AppDatabase db) async =>
      (await db.select(db.works).getSingle()).position;

  testApp('the first evening prefills the page where it started', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142);
    await readFor(tester, 9);
    expect(pageField(tester), '142');
    expect(find.text(en.eveningOfTotal('245')), findsOne);
    expect(find.text(en.eveningStartedAtPage(142)), findsOne);
  });

  testApp('the page is prefilled at the pace, and saves with one tap', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142);
    // A page a minute.
    await readFor(tester, 10);
    await tester.enterText(find.byKey(const Key('page')), '152');
    await tap(tester, find.text(en.saveAndLightsOut));

    now = now.add(const Duration(days: 1));
    await readFor(tester, 5);
    expect(pageField(tester), '157');
    await tap(tester, find.text(en.saveAndLightsOut));
    expect(await position(db), 157);
  });

  testApp('the prefill stops short of the end', (tester, db) async {
    await openAt(tester, db, 230);
    await readFor(tester, 10);
    await tester.enterText(find.byKey(const Key('page')), '240');
    await tap(tester, find.text(en.saveAndLightsOut));

    now = now.add(const Duration(days: 1));
    await readFor(tester, 10);
    expect(pageField(tester), '244');
  });

  testApp('the steppers move a page and stay between start and end', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142);
    await readFor(tester, 5);
    await tap(tester, find.byKey(const Key('pageUp')));
    await tap(tester, find.byKey(const Key('pageUp')));
    expect(pageField(tester), '144');
    for (var i = 0; i < 4; i++) {
      await tap(tester, find.byKey(const Key('pageDown')));
    }
    expect(pageField(tester), '142');

    await tester.enterText(find.byKey(const Key('page')), '245');
    await tap(tester, find.byKey(const Key('pageUp')));
    expect(pageField(tester), '245');
  });

  testApp('in Persian the page is in Persian digits, + on the left', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142, lang: 'fa');
    await readFor(tester, 5, fa);
    expect(pageField(tester), '۱۴۲');
    await tap(tester, find.byKey(const Key('pageUp')));
    expect(pageField(tester), '۱۴۳');
    expect(
      tester.getCenter(find.byKey(const Key('pageUp'))).dx,
      lessThan(tester.getCenter(find.byKey(const Key('pageDown'))).dx),
    );
  });
}
