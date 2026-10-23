import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../planned_break_fixture.dart';

void main() {
  // Tonight is 22 October, 21:00. Every Session event is stamped by this.
  var now = DateTime(2026, 10, 22, 21);

  /// Reading for 14 minutes: the break at the end of chapter 5 is due.
  Future<void> readTo14Minutes(
    WidgetTester tester,
    AppDatabase db,
    String lang,
  ) async {
    await addRemainsReadLastNight(db, lang, (t) => now = t);
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 14));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Watching for 14 minutes: the break at the end of episode 4 is due.
  Future<void> watchTo14Minutes(
    WidgetTester tester,
    AppDatabase db,
    String lang,
  ) async {
    await addDarkWatchedLastNight(db, lang, (t) => now = t);
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 14));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  for (final lang in ['en', 'fa']) {
    final l10n = lookupAppLocalizations(Locale(lang));

    testApp('Reading, with the Planned break due, in $lang', (
      tester,
      db,
    ) async {
      await readTo14Minutes(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_break_due_$lang.png'),
      );
    });

    testApp('The Planned break, offered, in $lang', (tester, db) async {
      await readTo14Minutes(tester, db, lang);
      await tap(tester, l10n.takeBreak);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('planned_break_$lang.png'),
      );
    });

    testApp('The Planned break, under way, in $lang', (tester, db) async {
      await readTo14Minutes(tester, db, lang);
      await tap(tester, l10n.takeBreak);
      await tap(tester, l10n.startMyBreak(4));
      now = now.add(const Duration(minutes: 1, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('planned_break_on_$lang.png'),
      );
    });

    testApp('The Planned break, over, in $lang', (tester, db) async {
      await readTo14Minutes(tester, db, lang);
      await tap(tester, l10n.takeBreak);
      await tap(tester, l10n.startMyBreak(4));
      now = now.add(const Duration(minutes: 4, seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('planned_break_over_$lang.png'),
      );
    });

    testApp('Watching a series, with the Planned break due, in $lang', (
      tester,
      db,
    ) async {
      await watchTo14Minutes(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_break_due_series_$lang.png'),
      );
    });

    testApp('The Planned break of a series, under way, in $lang', (
      tester,
      db,
    ) async {
      await watchTo14Minutes(tester, db, lang);
      await tap(tester, l10n.takeBreak);
      await tap(tester, l10n.startMyBreak(4));
      now = now.add(const Duration(minutes: 1, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('planned_break_series_on_$lang.png'),
      );
    });
  }
}
