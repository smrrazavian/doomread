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
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text(fa.editChapterPages));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkpoints')), '۳۰، ۶۰');
    await tester.tap(find.text(fa.save));
    await tester.pumpAndSettle();

    // Typed in Persian digits, read back as 120 and shown as ۱۲۰.
    expect(fa.pageOf(0, 120), contains('۱۲۰'));
    expect(find.text(fa.pageOf(0, 120)), findsOne);
  });

  testApp('a book added with a chapter count alone has its chapters '
      'spread evenly, as estimates', (tester, db) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '400');
    expect(find.text(en.fieldChapters), findsOne);
    expect(find.byKey(const Key('checkpoints')), findsNothing);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('fewerChapters')));
    }
    await tester.pump();
    expect(find.text('4'), findsOne);
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    expect(find.text(en.pageOf(0, 400)), findsOne);
    expect(find.text(en.nextCheckpointAbout(100)), findsOne);
  });

  testApp('Edit pages shows where the count puts chapters, to change', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '400');
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('fewerChapters')));
    }
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
    expect(find.text('100, 200, 300'), findsOne);
    await tester.enterText(find.byKey(const Key('checkpoints')), '90, 200');
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    // Typed, so known: no "around".
    expect(find.text(en.nextCheckpoint(90)), findsOne);
  });

  testApp('pages left as Edit pages showed them stay estimates', (
    tester,
    db,
  ) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '400');
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('fewerChapters')));
    }
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('checkpoints')),
      '90, 200, 300',
    );
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    expect(find.text(en.nextCheckpoint(90)), findsOne);
    final dune = await db.select(db.works).getSingle();
    expect(dune.checkpoints, '90,200,300');
    expect(dune.estimated, 2, reason: 'Chapter done still asks for those');
  });

  testApp('back to Just a count keeps the pages typed', (tester, db) async {
    await openApp(tester, db);
    await tester.tap(find.text(en.tonightAddBook));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), 'Dune');
    await tester.enterText(find.byKey(const Key('pages')), '400');
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('fewerChapters')));
    }
    await tester.tap(find.text(en.editChapterPages));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('checkpoints')),
      '90, 200, 300',
    );
    await tester.tap(find.text(en.useChapterCount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.save));
    await tester.pumpAndSettle();

    final dune = await db.select(db.works).getSingle();
    expect(dune.checkpoints, startsWith('90,'), reason: 'typed, so kept');
    expect(dune.estimated, 2, reason: 'the rest spread from the count');
  });
}
