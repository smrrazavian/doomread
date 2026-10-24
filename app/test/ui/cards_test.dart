import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/share/widgets/glow_up_poster.dart';
import 'package:doomread/ui/share/widgets/month_poster.dart';
import 'package:doomread/ui/share/widgets/note_poster.dart';
import 'package:doomread/ui/share/widgets/receipt_poster.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// The share cards' ways in: each one opt-in, from the screen it belongs to.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  const title = 'The Remains of the Day';

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testApp('Share tonight saves, opens the receipt, then the evening ends', (
    tester,
    db,
  ) async {
    var now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: title,
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      const WorksCompanion(position: Value(142)),
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await SettingsRepository(db).setTone(Tone.mom);
    final sheet = FakeShareSheet();
    await pumpApp(tester, db, clock: () => now, share: sheet);

    await tap(tester, find.text(en.startReading));
    now = now.add(const Duration(minutes: 12));
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), '156');
    await tester.enterText(find.byKey(const Key('note')), 'Not on it.');
    await tap(tester, find.byKey(const Key('shareTonight')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Saved before anything is shown.
    expect((await db.select(db.works).getSingle()).position, 156);
    final receipt = tester.widget<ReceiptPoster>(find.byType(ReceiptPoster));
    expect(receipt.pages, (from: 142, to: 156));
    expect(receipt.session.reading, const Duration(minutes: 12));
    expect(receipt.signOff, voice(Moment.receipt, Tone.mom, 'en'));
    expect(receipt.signOff, receiptSignOff(receipt.session, Tone.mom, 'en'));
    // No Urges tonight: no zero to read as a score.
    expect(find.text(en.cardReceiptUrges), findsNothing);
    // The Note stays off the receipt.
    expect(find.text('Not on it.'), findsNothing);
    expect(sheet.shared, isEmpty);

    await tap(tester, find.byType(BackButton));
    expect(find.byType(ReceiptPoster), findsNothing);
    expect(find.text(en.startReading), findsOne);
  });

  group('from the Building and the Book page', () {
    var now = DateTime(2026, 10, 24, 21);

    /// A book read on [evenings]: (day of October, minutes in one go,
    /// page reached, Note). Returns its id.
    Future<String> readOn(
      AppDatabase db,
      List<(int, int, int, String)> evenings,
    ) async {
      final sessions = SessionRepository(db, clock: () => now);
      final id = await WorkRepository(db).add(
        title: title,
        author: 'Kazuo Ishiguro',
        totalPages: 245,
        checkpoints: const [],
      );
      final work = Work(
        id: id,
        title: title,
        author: '',
        totalPages: 245,
        checkpoints: const [],
      );
      var from = 0;
      for (final (day, minutes, page, note) in evenings) {
        now = DateTime(2026, 10, day, 21);
        final record = SessionRecord(
          id: await sessions.start(id),
          road: Road(work, position: from),
          events: const [],
        );
        now = now.add(Duration(minutes: minutes));
        await sessions.add(record, SessionEventKind.stop);
        await sessions.end(record, page: page, note: note);
        from = page;
      }
      now = DateTime(2026, 10, 24, 21);
      return id;
    }

    Future<FakeShareSheet> open(WidgetTester tester, AppDatabase db) async {
      await SettingsRepository(db).setLocale(const Locale('en'));
      final sheet = FakeShareSheet();
      await pumpApp(tester, db, clock: () => now, share: sheet);
      return sheet;
    }

    testApp('the glow-up opens from the trend once it has risen', (
      tester,
      db,
    ) async {
      await readOn(db, [(3, 5, 20, ''), (9, 12, 60, ''), (20, 31, 120, '')]);
      await open(tester, db);
      await tap(tester, find.text(en.navBuilding));

      await tap(tester, find.text(en.cardGlowUpAction));
      final card = tester.widget<GlowUpPoster>(find.byType(GlowUpPoster));
      expect(card.watched, isFalse);
      expect([for (final r in card.rises) r.longest.inMinutes], [5, 12, 31]);
      expect(find.text(en.minutesShort(5)), findsOne);
      expect(find.text(en.minutesShort(31)), findsOne);
    });

    testApp('the month of windows opens from the Building', (tester, db) async {
      await readOn(db, [(3, 5, 20, ''), (9, 12, 60, ''), (20, 31, 120, '')]);
      await open(tester, db);
      await tap(tester, find.text(en.navBuilding));

      await tap(tester, find.text(en.cardMonthAction));
      final card = tester.widget<MonthPoster>(find.byType(MonthPoster));
      expect(card.month.calendarMonth, (year: 2026, month: 10));
      expect(card.month.count, 3);
      expect(card.month.readingOn(DateTime(2026, 10, 20)).inMinutes, 31);
      expect(find.text(en.cardMonthLit(3)), findsOne);
    });

    testApp('a Note shares on its own, with no numbers', (tester, db) async {
      await readOn(db, [
        (3, 5, 20, 'Darlington Hall, in the old days.'),
        (9, 12, 60, 'The car breaks down.'),
      ]);
      await open(tester, db);
      await tap(tester, find.text(title));

      final shares = find.byTooltip(en.cardNoteAction);
      expect(shares, findsNWidgets(2));
      // Newest first: the second one is the older Note.
      await tap(tester, shares.last);
      final card = tester.widget<NotePoster>(find.byType(NotePoster));
      expect(card.note, 'Darlington Hall, in the old days.');
      expect(find.text('Darlington Hall, in the old days.'), findsOne);
      expect(find.text('The car breaks down.'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(NotePoster),
          matching: find.textContaining(RegExp('[0-9]')),
        ),
        findsNothing,
      );
    });

    testApp('no glow-up while the line has not risen', (tester, db) async {
      await readOn(db, [(9, 12, 60, '')]);
      await open(tester, db);
      await tap(tester, find.text(en.navBuilding));
      expect(find.text(en.cardGlowUpAction), findsNothing);
    });
  });
}
