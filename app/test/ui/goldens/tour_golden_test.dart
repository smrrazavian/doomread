import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// The first-run intro, card by card, and the demo Urge, in both languages.
void main() {
  final now = DateTime(2026, 10, 22, 21);

  Future<void> phone(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('introNext')));
    await tester.pumpAndSettle();
  }

  const cards = ['story', 'company', 'tone', 'work'];

  for (final lang in ['en', 'fa']) {
    for (final (i, card) in cards.indexed) {
      testApp('The intro, $card, in $lang', (tester, db) async {
        await phone(tester);
        await SettingsRepository(db).setLocale(Locale(lang));
        await pumpApp(tester, db, tour: true, clock: () => now);
        for (var n = 0; n < i; n++) {
          await next(tester);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('intro_${card}_$lang.png'),
        );
      });
    }

    testApp('The demo Urge, in $lang', (tester, db) async {
      await phone(tester);
      await demoReady(db, lang);
      await pumpApp(tester, db, tour: true, clock: () => now);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('demoShow')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('demo_urge_$lang.png'),
      );
    });
  }
}

/// A Work to read and the intro done, with the demo and the "not yet"
/// screen's hint still to come.
Future<void> demoReady(AppDatabase db, String lang) async {
  await WorkRepository(db).add(
    title: lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day',
    author: lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: const [34, 66, 98],
  );
  final settings = SettingsRepository(db);
  await settings.setLocale(Locale(lang));
  await settings.setIntroSeen();
  await settings.setHintsSeen({Hint.aim, Hint.plannedBreak});
}
