import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Future<void> openIn(WidgetTester tester, AppDatabase db, String lang) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db);
  }

  for (final lang in ['en', 'fa']) {
    testApp('Tonight, empty, in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_empty_$lang.png'),
      );
    });

    testApp('Settings in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('settings_$lang.png'),
      );
    });
    testApp('Tonight with a book in $lang', (tester, db) async {
      final works = WorkRepository(db);
      final id = await works.add(
        title: lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day',
        author: lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
        totalPages: 245,
        checkpoints: [34, 66, 98, 128, 156, 194, 222],
      );
      await (db.update(db.works)..where((w) => w.id.equals(id))).write(
        const WorksCompanion(position: Value(142)),
      );
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_book_$lang.png'),
      );
    });

    testApp('Add a book in $lang, with a problem shown', (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton)); // save the empty form
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('add_book_$lang.png'),
      );
    });

    testApp('Books in $lang', (tester, db) async {
      final works = WorkRepository(db);
      await works.add(
        title: lang == 'fa' ? 'بوف کور' : 'Dune',
        author: lang == 'fa' ? 'صادق هدایت' : 'Frank Herbert',
        totalPages: 120,
        checkpoints: const [],
      );
      await works.add(
        title: lang == 'fa' ? 'سمفونی مردگان' : 'Piranesi',
        author: lang == 'fa' ? 'عباس معروفی' : 'Susanna Clarke',
        totalPages: 272,
        checkpoints: const [],
      );
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.menu_book_outlined).first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('books_$lang.png'),
      );
    });
  }
}
