import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Future<void> openApp(
    WidgetTester tester,
    AppDatabase db, {
    String lang = 'en',
  }) async {
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db);
  }

  testApp('adding a book shows it on Tonight with its Road, and in Books', (
    tester,
    db,
  ) async {
    await openApp(tester, db);

    await tester.tap(find.text('Add a book'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('author')), 'Frank Herbert');
    await tester.enterText(find.byKey(const Key('pages')), '412');
    await tester.enterText(find.byKey(const Key('checkpoints')), '100, 200');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOne);
    expect(find.text('Page 0 of 412'), findsOne);

    await tester.tap(find.text('Books'));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOne);
  });

  testApp('a book with no pages is refused with a message by the field', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text('Add a book'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('How many pages does it have?'), findsOne);
  });

  testApp('Persian digits and the Persian comma are understood', (
    tester,
    db,
  ) async {
    await openApp(tester, db, lang: 'fa');
    await tester.tap(find.text('یه کتاب اضافه کن'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'بوف کور');
    await tester.enterText(find.byKey(const Key('pages')), '۱۲۰');
    await tester.enterText(find.byKey(const Key('checkpoints')), '۳۰، ۶۰');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();

    expect(find.text('صفحه‌ی ۰ از ۱۲۰'), findsOne);
  });
}
