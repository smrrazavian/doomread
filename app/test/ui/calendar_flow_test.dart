import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// A month to look at, seeded through the repositories with a clock moved
/// by hand: Dune on 20 October (18 pages and a Note), a short book
/// Finished on 12 October, a Task Done at 1 a.m. on the 21st (so on the
/// 20th), and one planned for the 25th. pumpApp's clock is 22 October.
Future<void> seedMonth(AppDatabase db, {String lang = 'en'}) async {
  var now = DateTime(2026, 10);
  final works = WorkRepository(db, clock: () => now);
  final sessions = SessionRepository(db, clock: () => now);

  Future<void> sit(
    String workId,
    DateTime at,
    int minutes,
    int page, [
    String note = '',
  ]) async {
    now = at;
    final id = await sessions.start(workId);
    final record = SessionRecord(
      id: id,
      road: Road(
        Work(
          id: workId,
          title: '',
          author: '',
          totalPages: 1,
          checkpoints: const [],
        ),
        position: 0,
      ),
      events: const [],
    );
    now = at.add(Duration(minutes: minutes));
    await sessions.add(record, SessionEventKind.stop);
    await sessions.end(record, page: page, note: note);
  }

  final fa = lang == 'fa';
  final dune = await works.add(
    title: fa ? 'تل‌ماسه' : 'Dune',
    author: 'Frank Herbert',
    totalPages: 412,
    checkpoints: const [],
  );
  final short = await works.add(
    title: fa ? 'شازده کوچولو' : 'The Little Prince',
    author: 'Antoine de Saint-Exupéry',
    totalPages: 96,
    checkpoints: const [],
  );
  await sit(short, DateTime(2026, 10, 12, 21), 95, 96);
  await sit(
    dune,
    DateTime(2026, 10, 20, 21),
    40,
    18,
    fa
        ? 'پل بالاخره آب حیات رو خورد.'
        : 'Paul finally drinks the Water of Life.',
  );
  now = DateTime(2026, 10, 20, 10);
  final report = await works.addTask(
    name: fa ? 'نوشتن گزارش' : 'Write the report',
    day: DateTime(2026, 10, 20),
  );
  now = DateTime(2026, 10, 21, 0, 10);
  final reportSession = await sessions.start(report);
  now = DateTime(2026, 10, 21, 1);
  await sessions.add(
    SessionRecord(
      id: reportSession,
      road: Road(
        Work(
          id: report,
          title: '',
          author: '',
          totalPages: 1,
          checkpoints: const [],
        ),
        position: 0,
      ),
      events: const [],
    ),
    SessionEventKind.stop,
  );
  await works.setDone(report);
  await works.addTask(
    name: fa ? 'دندون‌پزشکی' : 'Dentist',
    day: DateTime(2026, 10, 25),
  );
}

/// The tile of [day] on the grid.
Finder dayTile(DateTime day) => find.byKey(ValueKey(day));

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openCalendar(WidgetTester tester, AppDatabase db) async {
    await pumpApp(tester, db);
    await tap(tester, find.text(en.navCalendar));
  }

  int marks(Finder tile, String key) => find
      .descendant(of: tile, matching: find.byKey(Key(key)))
      .evaluate()
      .length;

  testApp('the month sums itself up, and each day carries its marks', (
    tester,
    db,
  ) async {
    await seedMonth(db);
    await openCalendar(tester, db);

    expect(find.text('October 2026'), findsOne);
    expect(
      find.text(
        [
          en.calendarNightsLit(2),
          en.calendarTasksDone(1),
          en.calendarFinishes(1),
        ].join(en.calendarSeparator),
      ),
      findsOne,
    );

    final reading = dayTile(DateTime(2026, 10, 20));
    expect(marks(reading, 'spine'), 1);
    expect(marks(reading, 'dot'), 1, reason: 'the Task Done at 1 a.m.');
    expect(marks(reading, 'flag'), 0);
    expect(marks(dayTile(DateTime(2026, 10, 21)), 'dot'), 0);

    final finished = dayTile(DateTime(2026, 10, 12));
    expect(marks(finished, 'flag'), 1);
    expect(marks(finished, 'spine'), 1);

    final ahead = dayTile(DateTime(2026, 10, 25));
    expect(marks(ahead, 'planned'), 1);
    expect(marks(ahead, 'dot'), 0);

    // A dark day carries nothing at all.
    final dark = dayTile(DateTime(2026, 10, 5));
    for (final k in ['spine', 'dot', 'flag', 'planned', 'glow']) {
      expect(marks(dark, k), 0, reason: k);
    }
    expect(marks(reading, 'glow'), 1);
  });

  testApp('tapping a day tells what happened on it', (tester, db) async {
    await seedMonth(db);
    await openCalendar(tester, db);

    await tap(tester, dayTile(DateTime(2026, 10, 20)));
    expect(find.text('Tuesday, October 20'), findsOne);
    // 40 minutes of Dune and 50 of the report, which ran past midnight.
    expect(find.text(en.calendarFocusHours(1, 30)), findsOne);
    expect(find.text(en.calendarDayTasksDone(1)), findsOne);
    expect(
      find.text(
        '${en.calendarDayWork('paperBook', 'Dune')}'
        '${en.calendarSeparator}${en.calendarPages(18)}',
      ),
      findsOne,
    );
    expect(find.text('Paul finally drinks the Water of Life.'), findsOne);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tap(tester, dayTile(DateTime(2026, 10, 5)));
    expect(find.text(en.calendarDayQuiet), findsOne);
    expect(find.textContaining('focused'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tap(tester, dayTile(DateTime(2026, 10, 25)));
    expect(find.text(en.calendarDayPlanned(1)), findsOne);
  });

  testApp('the legend shows its minutes on tap', (tester, db) async {
    await openCalendar(tester, db);
    await tester.ensureVisible(find.text(en.calendarLegendFocus));
    await tester.pumpAndSettle();
    expect(find.text(en.calendarTick1h), findsNothing);
    await tap(tester, find.text(en.calendarLegendFocus));
    for (final t in [
      en.calendarTick30m,
      en.calendarTick1h,
      en.calendarTick2h,
    ]) {
      expect(find.text(t), findsOne);
    }
  });

  testApp('months can be swiped', (tester, db) async {
    await openCalendar(tester, db);
    Future<void> swipe(String from, double dx) async {
      await tester.fling(find.text(from), Offset(dx, 0), 1000);
      await tester.pumpAndSettle();
    }

    await swipe('October 2026', 200);
    expect(find.text('September 2026'), findsOne);
    await swipe('September 2026', -200);
    await swipe('October 2026', -200);
    expect(find.text('November 2026'), findsOne);
  });

  testApp('nothing on the Calendar speaks of streaks', (tester, db) async {
    await seedMonth(db);
    await openCalendar(tester, db);
    await tap(tester, dayTile(DateTime(2026, 10, 20)));
    final words = [
      for (final t in tester.widgetList<Text>(find.byType(Text)))
        t.data ?? t.textSpan?.toPlainText() ?? '',
    ].join(' ').toLowerCase();
    for (final banned in ['streak', 'in a row', 'chain', 'missed', 'broke']) {
      expect(words, isNot(contains(banned)));
    }
  });

  testApp('in Persian the month is Solar Hijri, in Persian digits', (
    tester,
    db,
  ) async {
    await SettingsRepository(db).setLocale(const Locale('fa'));
    await pumpApp(tester, db);
    final fa = lookupAppLocalizations(const Locale('fa'));
    await tap(tester, find.text(fa.navCalendar));
    expect(find.text('مهر ۱۴۰۵'), findsOne);
    // 22 October is 30 Mehr: the last day, and today.
    expect(
      find.descendant(
        of: dayTile(DateTime(2026, 10, 22)),
        matching: find.text('۳۰'),
      ),
      findsOne,
    );
  });

  /// How high the 20th's glow stands now: 90 minutes of focus is 0.75.
  double glowHeight(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(
        find.descendant(
          of: dayTile(DateTime(2026, 10, 20)),
          matching: find.byType(FractionallySizedBox),
        ),
      )
      .heightFactor!;

  testApp('with motion on, the glow rises as the month opens', (
    tester,
    db,
  ) async {
    await seedMonth(db);
    await pumpApp(tester, db, reduceMotion: false);
    await tester.tap(find.text(en.navCalendar));
    await tester.pump();
    await tester.pump();
    expect(glowHeight(tester), lessThan(0.1));
    await tester.pumpAndSettle();
    expect(glowHeight(tester), closeTo(0.75, 0.001));
  });

  testApp('with reduced motion, the glow is already up', (tester, db) async {
    await seedMonth(db);
    await pumpApp(tester, db);
    await tester.tap(find.text(en.navCalendar));
    await tester.pump();
    await tester.pump();
    expect(glowHeight(tester), closeTo(0.75, 0.001));
  });
}
