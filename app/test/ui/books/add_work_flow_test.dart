import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));

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

    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('author')), 'Frank Herbert');
    await tester.enterText(find.byKey(const Key('pages')), '412');
    await tester.enterText(find.byKey(const Key('checkpoints')), '100, 200');
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOne);
    expect(find.text(en.pageOf(0, 412)), findsOne);

    await tester.tap(find.text(en.navBooks));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOne);
  });

  testApp('a book with no pages is refused with a message by the field', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    expect(find.text(en.problemNoPages), findsOne);
  });

  testApp('a malformed Checkpoint list says what format is expected', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '412');
    for (final bad in ['34, 66,, 98', 'abc']) {
      await tester.enterText(find.byKey(const Key('checkpoints')), bad);
      await tester.tap(find.text(en.save));
      await tester.pumpAndSettle();
      expect(find.text(en.checkpointsFormatPages), findsOne, reason: bad);
      expect(find.text(en.problemCheckpointPastEnd), findsNothing);
    }
  });

  testApp('a Checkpoint beyond the length says past end, not format', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '412');
    await tester.enterText(find.byKey(const Key('checkpoints')), '34, 500');
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();
    expect(find.text(en.problemCheckpointPastEnd), findsOne);
    expect(find.text(en.checkpointsFormatPages), findsNothing);
  });

  testApp('Persian digits and the Persian comma are understood', (
    tester,
    db,
  ) async {
    await openApp(tester, db, lang: 'fa');
    await tester.tap(find.text(fa.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'بوف کور');
    await tester.enterText(find.byKey(const Key('pages')), '۱۲۰');
    await tester.enterText(find.byKey(const Key('checkpoints')), '۳۰، ۶۰');
    await tester.tap(find.text(fa.save));
    await tester.pumpAndSettle();

    // Typed in Persian digits, read back as 120 and shown as ۱۲۰.
    expect(fa.pageOf(0, 120), contains('۱۲۰'));
    expect(find.text(fa.pageOf(0, 120)), findsOne);
  });
}
