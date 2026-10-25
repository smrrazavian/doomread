import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// Goldens for the Finish: the ceremony, the Building and the Book page.
void main() {
  var now = DateTime(2026, 10, 22, 21);
  setUp(() => now = DateTime(2026, 10, 22, 21));

  Future<void> openIn(WidgetTester tester, AppDatabase db, String lang) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
  }

  Future<String> book(AppDatabase db, String title, String author, int pages) =>
      WorkRepository(db).add(
        title: title,
        author: author,
        totalPages: pages,
        checkpoints: const [
          34,
          66,
          98,
          128,
          156,
          194,
          222,
        ].where((c) => c < pages).toList(),
      );

  /// Sessions on [workId], one per (day of October, minutes, page, Note).
  // The records are built by hand: watching the journal before the app is
  // pumped would wait on drift timers that fake time never fires.
  Future<void> read(
    AppDatabase db,
    String workId,
    List<(int, int, int, String)> evenings,
  ) async {
    final sessions = SessionRepository(db, clock: () => now);
    final work = Work(
      id: workId,
      title: '',
      author: '',
      totalPages: 1,
      checkpoints: const [],
    );
    for (final (day, minutes, page, note) in evenings) {
      now = DateTime(2026, 10, day, 21);
      final record = SessionRecord(
        id: await sessions.start(workId),
        road: Road(work, position: 0),
        events: const [],
      );
      now = now.add(Duration(minutes: minutes));
      await sessions.add(record, SessionEventKind.stop);
      await sessions.end(record, page: page, note: note);
    }
    now = DateTime(2026, 10, 22, 21);
  }

  Future<String> remains(AppDatabase db, String lang) => book(
    db,
    lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day',
    lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
    245,
  );

  /// The Remains of the Day, read to page 156 with these Notes.
  Future<String> remainsWithNotes(AppDatabase db, String lang) async {
    final id = await remains(db, lang);
    final fa = lang == 'fa';
    await read(db, id, [
      (
        16,
        6,
        117,
        fa
            ? 'با خودش سر معنی «وقار» کلنجار می‌ره و می‌ره سمت غرب.'
            : 'He drives west, arguing with himself about "dignity".',
      ),
      (
        17,
        5,
        128,
        fa
            ? 'برمی‌گرده به شبی که باباش مُرد و اون همچنان شام سرو می‌کرد.'
            : 'Back to the night his father died while he kept serving dinner.',
      ),
      (18, 4, 135, ''),
      (
        19,
        7,
        142,
        fa
            ? 'ماشین خراب می‌شه و اهل ده فکر می‌کنن آقازاده‌ست.'
            : 'The car breaks down and a village takes him for a gentleman.',
      ),
      (
        21,
        9,
        156,
        fa
            ? 'استیونز بالاخره قبول می‌کنه دلش برای دوشیزه کنتون تنگ شده، '
                  'ولی فقط پیش خودش.'
            : 'Stevens finally admits he misses Miss Kenton, '
                  'but only to himself.',
      ),
    ]);
    return id;
  }

  for (final lang in ['en', 'fa']) {
    testApp('the Building with no floors yet, in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.apartment_outlined));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('building_empty_$lang.png'),
      );
    });

    testApp('the Building with three floors, in $lang', (tester, db) async {
      final fa = lang == 'fa';
      final habits = await book(
        db,
        fa ? 'عادت‌های اتمی' : 'Atomic Habits',
        fa ? 'جیمز کلیر' : 'James Clear',
        180,
      );
      await read(db, habits, [(2, 5, 90, ''), (4, 6, 180, '')]);
      final owl = await book(
        db,
        fa ? 'بوف کور' : 'Piranesi',
        fa ? 'صادق هدایت' : 'Susanna Clarke',
        120,
      );
      await read(db, owl, [(8, 7, 60, ''), (9, 8, 120, '')]);
      final id = await remains(db, lang);
      await read(db, id, [
        (12, 9, 100, ''),
        (14, 12, 200, ''),
        (15, 18, 245, ''),
      ]);
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.apartment_outlined));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('building_$lang.png'),
      );
    });

    testApp('the finishing ceremony, in $lang', (tester, db) async {
      final fa = lang == 'fa';
      final id = await remains(db, lang);
      await read(db, id, [
        (19, 6, 142, fa ? 'ماشین خراب می‌شه.' : 'The car breaks down.'),
        (21, 8, 222, fa ? 'نامه‌ی خانم بن.' : "Mrs Benn's letter."),
      ]);
      await openIn(tester, db, lang);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 11, seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byKey(const Key('page')), fa ? '۲۴۵' : '245');
      await tester.enterText(
        find.byKey(const Key('note')),
        fa ? 'اسکله، چراغ‌ها، و یه لبخند.' : 'The pier, the lights, a smile.',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('finish_$lang.png'),
      );
    });

    testApp('the Book page with its Notes, in $lang', (tester, db) async {
      await remainsWithNotes(db, lang);
      await openIn(tester, db, lang);
      // The book's title on Tonight opens its page.
      await tester.tap(
        find.text(lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day'),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('book_$lang.png'),
      );
    });
  }
}
