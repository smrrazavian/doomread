import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'haptics.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));
  const title = 'The Remains of the Day';

  Future<void> openAt(WidgetTester tester, AppDatabase db, int page) async {
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
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// One Session from Tonight: [minutes] in one go, ended at [page].
  Future<void> session(
    WidgetTester tester,
    int minutes,
    int page, [
    String note = '',
  ]) async {
    await tap(tester, find.text(en.startReading));
    now = now.add(Duration(minutes: minutes));
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), '$page');
    await tester.enterText(find.byKey(const Key('note')), note);
    await tap(tester, find.text(en.saveAndLightsOut));
  }

  testApp('entering the last page Finishes the Work and grows the Building', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 230);
    final buzzes = haptics(tester);
    await session(tester, 9, 245, 'Stevens looks at the pier lights.');

    expect(find.text(en.finishedTitle(title)), findsOne);
    // Start's click, then the Finish's.
    expect(buzzes.last, 'HapticFeedbackType.heavyImpact');
    expect(find.text(en.finishedSub(245, 1)), findsOne);
    expect(find.text(en.minutesShort(9)), findsOne);
    expect(find.text(en.notesWritten(1)), findsOne);
    // The Building is the way on; the story is there to look back at.
    expect(find.widgetWithText(FilledButton, en.seeYourBuilding), findsOne);
    expect(find.widgetWithText(OutlinedButton, en.readTheStory), findsOne);

    await tap(tester, find.text(en.readTheStory));
    expect(find.text(en.bookFinished), findsOne);
    expect(find.text(en.pageRange(230, 245)), findsOne);
    expect(find.text('Stevens looks at the pier lights.'), findsOne);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text(en.seeYourBuilding));
    expect(
      find.descendant(
        of: find.byKey(const Key('newestFloor')),
        matching: find.text(title),
      ),
      findsOne,
    );
    expect(find.text(en.floorDetails(245, 1)), findsOne);
  });

  testApp('the Book page lists Notes newest first and skips empty ones', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 100);
    await session(tester, 5, 120, 'Darlington Hall, in the old days.');
    now = now.add(const Duration(days: 1));
    await session(tester, 5, 130);
    now = now.add(const Duration(days: 1));
    await session(tester, 5, 142, 'The car breaks down.');

    await tap(tester, find.text(title));
    expect(find.text(en.pagesLeft(103)), findsOne);
    expect(find.text(en.pageRange(120, 130)), findsNothing);
    final newer = tester.getTopLeft(find.text(en.pageRange(130, 142)));
    final older = tester.getTopLeft(find.text(en.pageRange(100, 120)));
    expect(newer.dy, lessThan(older.dy));
  });

  testApp('saving the last page again is not a second Finish', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 240);
    await session(tester, 5, 245);
    await tap(tester, find.text(en.seeYourBuilding));
    await tap(tester, find.text(en.navToday));

    await session(tester, 5, 245);
    expect(find.text(en.finishedTitle(title)), findsNothing);
    expect(find.text(en.startReading), findsOne);
  });

  test('Persian page ranges use Persian digits, in reading order', () {
    final range = fa.pageRange(142, 156);
    expect(range, isNot(contains('142')));
    expect(range.indexOf('۱۴۲'), lessThan(range.indexOf('۱۵۶')));
  });
}
