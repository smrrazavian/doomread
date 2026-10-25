import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);

  /// Working on the report for 18:42, with reduced motion: the caret holds
  /// still, and in Persian the desk mirrors.
  Future<void> workOnReport(
    WidgetTester tester,
    AppDatabase db,
    String lang,
  ) async {
    now = DateTime(2026, 10, 22, 21);
    await WorkRepository(db).addTask(
      name: lang == 'fa' ? 'نوشتن گزارش فصل سوم' : 'Write the Q3 report',
      day: DateTime(2026, 10, 22),
    );
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
    await tester.tap(
      find.text(lookupAppLocalizations(Locale(lang)).startWork('task')),
    );
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 18, seconds: 42));
    await tester.pump(const Duration(seconds: 1));
  }

  for (final lang in ['en', 'fa']) {
    testApp('a Task Session at the desk, in $lang', (tester, db) async {
      await workOnReport(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('task_session_$lang.png'),
      );
    });

    testApp('a Task Session, paused, in $lang', (tester, db) async {
      await workOnReport(tester, db, lang);
      await tester.tap(find.byKey(const Key('sessionClock')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('task_session_paused_$lang.png'),
      );
    });

    testApp('the Done moment, in $lang', (tester, db) async {
      await workOnReport(tester, db, lang);
      // Another Task is left, so Next shows.
      await WorkRepository(db).addTask(
        name: lang == 'fa' ? 'زنگ زدن به بانک' : 'Call the bank',
        day: DateTime(2026, 10, 22),
      );
      now = now.add(const Duration(minutes: 33, seconds: 18));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(
        find.text(lookupAppLocalizations(Locale(lang)).taskDone),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('done_$lang.png'),
      );
    });
  }
}
