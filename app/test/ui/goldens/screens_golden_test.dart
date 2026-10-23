import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  // Tonight is 22 October, 21:00. Every Session event is stamped by this.
  var now = DateTime(2026, 10, 22, 21);
  setUp(() => now = DateTime(2026, 10, 22, 21));

  Future<void> openIn(
    WidgetTester tester,
    AppDatabase db,
    String lang, {
    FakeSessionNotification? notification,
  }) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now, notification: notification);
  }

  /// The Remains of the Day at page 142, as the current Work.
  Future<String> addRemains(AppDatabase db, String lang) async {
    final id = await WorkRepository(db).add(
      title: lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day',
      author: lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: [34, 66, 98, 128, 156, 194, 222],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      const WorksCompanion(position: Value(114)),
    );
    return id;
  }

  /// Two earlier evenings of 14 pages each, ending at page 142. The best of
  /// them is 5:40 in one go, so tonight's Aim is 7 minutes.
  // The records are built by hand: watching the journal before the app is
  // pumped would wait on drift timers that fake time never fires.
  Future<void> addEarlierEvenings(
    WidgetTester tester,
    AppDatabase db,
    String workId,
  ) async {
    final sessions = SessionRepository(db, clock: () => now);
    final work = Work(
      id: workId,
      title: '',
      author: '',
      totalPages: 245,
      checkpoints: const [],
    );
    for (final (day, minutes, page) in [(20, 4, 128), (21, 5, 142)]) {
      now = DateTime(2026, 10, day, 21);
      final record = SessionRecord(
        id: await sessions.start(workId),
        road: Road(work, position: 0),
        events: const [],
      );
      now = now.add(Duration(minutes: minutes, seconds: 40));
      await sessions.add(record, SessionEventKind.stop);
      await sessions.end(record, page: page);
    }
    now = DateTime(2026, 10, 22, 21);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    // Let the journal's query stream deliver before the next step.
    await tester.pump(const Duration(seconds: 1));
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

    testApp('Tone, with Mom mode picked, in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RadioListTile<Tone>).last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tone_$lang.png'),
      );
    });

    testApp('Tonight with a book, its Aim and pace in $lang', (
      tester,
      db,
    ) async {
      await addEarlierEvenings(tester, db, await addRemains(db, lang));
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_book_$lang.png'),
      );
    });

    testApp('Reading in $lang', (tester, db) async {
      await addEarlierEvenings(tester, db, await addRemains(db, lang));
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 5, seconds: 12));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_$lang.png'),
      );
    });

    testApp('Reading on a first evening, the House empty, in $lang', (
      tester,
      db,
    ) async {
      await addRemains(db, lang);
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 2, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_house_empty_$lang.png'),
      );
    });

    testApp('Reading after an earlier Session tonight in $lang', (
      tester,
      db,
    ) async {
      final id = await addRemains(db, lang);
      await addEarlierEvenings(tester, db, id);
      // A first sitting at 19:00 tonight, six minutes long.
      final sessions = SessionRepository(db, clock: () => now);
      now = DateTime(2026, 10, 22, 19);
      final record = SessionRecord(
        id: await sessions.start(id),
        road: Road(
          Work(
            id: id,
            title: '',
            author: '',
            totalPages: 245,
            checkpoints: const [],
          ),
          position: 0,
        ),
        events: const [],
      );
      now = now.add(const Duration(minutes: 6));
      await sessions.add(record, SessionEventKind.stop);
      await sessions.end(record, page: 148);
      now = DateTime(2026, 10, 22, 21);
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 4, seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_house_$lang.png'),
      );
    });

    testApp('Asking for the Session notification in $lang', (tester, db) async {
      await addEarlierEvenings(tester, db, await addRemains(db, lang));
      await openIn(
        tester,
        db,
        lang,
        notification: FakeSessionNotification(askable: true),
      );
      await tap(tester, find.byType(FilledButton));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('notification_ask_$lang.png'),
      );
    });

    testApp('Reading, paused, in $lang', (tester, db) async {
      await addEarlierEvenings(tester, db, await addRemains(db, lang));
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 3, seconds: 5));
      await tap(tester, find.byType(OutlinedButton).first);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_paused_$lang.png'),
      );
    });

    testApp('End of the evening, with a new best stretch, in $lang', (
      tester,
      db,
    ) async {
      await addEarlierEvenings(tester, db, await addRemains(db, lang));
      await openIn(tester, db, lang);
      await tap(tester, find.byType(FilledButton));
      now = now.add(const Duration(minutes: 9, seconds: 20));
      await tap(tester, find.byType(OutlinedButton).last);
      await tester.enterText(
        find.byKey(const Key('page')),
        lang == 'fa' ? '۱۵۶' : '156',
      );
      await tester.enterText(
        find.byKey(const Key('note')),
        lang == 'fa'
            ? 'استیونز بالاخره قبول می‌کنه دلش برای دوشیزه کنتون تنگ شده، '
                  'ولی فقط پیش خودش.'
            : 'Stevens finally admits he misses Miss Kenton, '
                  'but only to himself.',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evening_$lang.png'),
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
