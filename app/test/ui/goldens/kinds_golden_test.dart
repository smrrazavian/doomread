import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// Goldens for Works that aren't paper books: a series in episodes and a
/// podcast or film in timestamps.
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    // Let the journal's query stream deliver before the next step.
    await tester.pump(const Duration(seconds: 1));
  }

  /// Dark, season 1: ten episodes.
  Future<String> dark(AppDatabase db, String lang) => WorkRepository(db).add(
    title: lang == 'fa' ? 'دارک، فصل ۱' : 'Dark, season 1',
    author: lang == 'fa' ? 'باران بو اودار' : 'Baran bo Odar',
    totalPages: 10,
    checkpoints: const [],
    kind: WorkKind.series,
  );

  /// A 2:41:00 podcast, with its segments ending at 42:30 and 1:15:00.
  Future<String> podcast(AppDatabase db, String lang) => WorkRepository(db).add(
    title: lang == 'fa' ? 'رادیو مرز، قسمت ۴۰' : 'Radio Marz, episode 40',
    author: lang == 'fa' ? 'علی بندری' : 'Ali Bandari',
    totalPages: 9660,
    checkpoints: const [2550, 4500],
    kind: WorkKind.podcast,
  );

  /// Sessions on [workId], one per (day of October, minutes, Position, Note).
  // The records are built by hand: watching the journal before the app is
  // pumped would wait on drift timers that fake time never fires.
  Future<void> sit(
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
    for (final (day, minutes, to, note) in evenings) {
      now = DateTime(2026, 10, day, 21);
      final record = SessionRecord(
        id: await sessions.start(workId),
        road: Road(work, position: 0),
        events: const [],
      );
      now = now.add(Duration(minutes: minutes, seconds: 40));
      await sessions.add(record, SessionEventKind.stop);
      await sessions.end(record, page: to, note: note);
    }
    now = DateTime(2026, 10, 22, 21);
  }

  /// A long evening with a book, so the watching Aim visibly stands apart.
  Future<void> readABook(AppDatabase db) async {
    final book = await WorkRepository(db)
        .add(title: 'Dune', author: '', totalPages: 412, checkpoints: const []);
    await sit(db, book, [(18, 25, 60, '')]);
  }

  Future<void> makeCurrent(AppDatabase db, String id) =>
      WorkRepository(db).setCurrent(id);

  for (final lang in ['en', 'fa']) {
    final fa = lang == 'fa';

    testApp('adding a series in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('series')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('title')),
        fa ? 'دارک، فصل ۱' : 'Dark, season 1',
      );
      await tester.enterText(find.byKey(const Key('pages')), fa ? '۱۰' : '10');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('add_series_$lang.png'),
      );
    });

    testApp('adding a podcast in $lang, with a problem shown', (
      tester,
      db,
    ) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('podcast')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('title')),
        fa ? 'رادیو مرز، قسمت ۴۰' : 'Radio Marz, episode 40',
      );
      await tester.enterText(
        find.byKey(const Key('checkpoints')),
        fa ? '۴۲:۳۰، ۱:۱۵:۰۰' : '42:30, 1:15:00',
      );
      await tester.tap(find.byType(FilledButton)); // no length yet
      await tester.pumpAndSettle();
      // No caret: its blink would depend on how long the steps took.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('add_podcast_$lang.png'),
      );
    });

    testApp('Books with every kind of Work in $lang', (tester, db) async {
      // One clock, so the order doesn't hang on a second ticking over.
      final works = WorkRepository(db, clock: () => DateTime(2026, 10, 22, 21));
      for (final (kind, en, persian) in [
        (WorkKind.paperBook, 'Piranesi', 'بوف کور'),
        (WorkKind.ebook, 'Atomic Habits', 'عادت‌های اتمی'),
        (WorkKind.series, 'Dark, season 1', 'دارک، فصل ۱'),
        (WorkKind.film, 'Paris, Texas', 'پاریس، تگزاس'),
        (WorkKind.podcast, 'Radio Marz, episode 40', 'رادیو مرز، قسمت ۴۰'),
      ]) {
        await works.add(
          title: fa ? persian : en,
          author: '',
          totalPages: 100,
          checkpoints: const [],
          kind: kind,
        );
      }
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.video_library_outlined));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('books_kinds_$lang.png'),
      );
    });

    testApp('Tonight with a series in $lang', (tester, db) async {
      await readABook(db);
      final id = await dark(db, lang);
      await sit(db, id, [(20, 38, 3, ''), (21, 44, 6, '')]);
      await makeCurrent(db, id);
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_series_$lang.png'),
      );
    });

    testApp('Tonight with a podcast in $lang', (tester, db) async {
      final id = await podcast(db, lang);
      await sit(db, id, [(21, 12, 4340, '')]);
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_podcast_$lang.png'),
      );
    });

    testApp('End of the evening for a series in $lang', (tester, db) async {
      final id = await dark(db, lang);
      await sit(db, id, [(21, 44, 6, '')]);
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 50));
      await tap(tester, find.byType(FilledButton).last);
      await tester.enterText(find.byKey(const Key('page')), fa ? '۸' : '8');
      await tester.enterText(
        find.byKey(const Key('note')),
        fa
            ? 'یوناس می‌فهمه غریبه کیه و همه‌چی بهم می‌ریزه.'
            : 'Jonas finds out who the stranger is, and everything tilts.',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evening_series_$lang.png'),
      );
    });

    testApp('End of the evening for a podcast in $lang, with a problem', (
      tester,
      db,
    ) async {
      final id = await podcast(db, lang);
      await sit(db, id, [(21, 12, 4340, '')]);
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 20, seconds: 5));
      await tap(tester, find.byType(FilledButton).last);
      // Before where it started: refused, with the range in timestamps.
      await tester.enterText(
        find.byKey(const Key('page')),
        fa ? '۱:۰۲:۲۰' : '1:02:20',
      );
      await tap(tester, find.byType(FilledButton));
      // No caret: its blink would depend on how long the steps took.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evening_podcast_$lang.png'),
      );
    });

    testApp('the Book page for a podcast in $lang', (tester, db) async {
      final id = await podcast(db, lang);
      await sit(db, id, [
        (
          19,
          20,
          2550,
          fa
              ? 'از تهران دهه‌ی شصت می‌گه و نوارهای قاچاق.'
              : 'Tehran in the eighties, and smuggled tapes.',
        ),
        (
          21,
          30,
          4340,
          fa
              ? 'یه آهنگ که هیچ‌وقت ضبط نشد.'
              : 'A song that was never recorded.',
        ),
      ]);
      await openIn(tester, db, lang);
      await tester.tap(
        find.text(fa ? 'رادیو مرز، قسمت ۴۰' : 'Radio Marz, episode 40'),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('book_podcast_$lang.png'),
      );
    });

    testApp('finishing a series in $lang', (tester, db) async {
      final id = await dark(db, lang);
      await sit(db, id, [(19, 40, 4, ''), (21, 45, 9, '')]);
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 52));
      await tap(tester, find.byType(FilledButton).last);
      await tester.enterText(find.byKey(const Key('page')), fa ? '۱۰' : '10');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('finish_series_$lang.png'),
      );
    });

    testApp('the Building with reading and watching in $lang', (
      tester,
      db,
    ) async {
      final book = await WorkRepository(db).add(
        title: fa ? 'بوف کور' : 'Piranesi',
        author: '',
        totalPages: 120,
        checkpoints: const [],
      );
      await sit(db, book, [(8, 7, 60, ''), (9, 11, 120, '')]);
      final series = await dark(db, lang);
      await sit(db, series, [(12, 30, 4, ''), (14, 45, 10, '')]);
      final film = await WorkRepository(db).add(
        title: fa ? 'پاریس، تگزاس' : 'Paris, Texas',
        author: '',
        totalPages: 8700,
        checkpoints: const [],
        kind: WorkKind.film,
      );
      await sit(db, film, [(16, 80, 4000, ''), (17, 72, 8700, '')]);
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.apartment_outlined));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('building_kinds_$lang.png'),
      );
      // Down past the tower, to the floors in their own units.
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('building_kinds_floors_$lang.png'),
      );
    });
  }
}
