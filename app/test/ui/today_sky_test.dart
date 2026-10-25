import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/tonight/widgets/today_sky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('the sky at an hour', () {
    test('counts the small hours on from the evening before', () {
      expect(skyHour(DateTime(2026, 10, 24, 14, 30)), 14.5);
      expect(skyHour(DateTime(2026, 10, 25, 1)), 25);
      expect(skyHour(DateTime(2026, 10, 25, 4)), 4);
    });

    test('names the part of the day', () {
      expect(partOfDay(9), DayPart.morning);
      expect(partOfDay(14), DayPart.afternoon);
      expect(partOfDay(18), DayPart.evening);
      expect(partOfDay(22), DayPart.night);
      expect(partOfDay(25), DayPart.night);
    });

    test("lights the neighbours' windows one by one through the evening", () {
      expect(litWindows(12), 0);
      expect(litWindows(17), 0);
      expect(litWindows(18.5), 4);
      expect(litWindows(20), skyWindows);
      expect(litWindows(26), skyWindows);
    });
  });

  Future<void> comeBack(WidgetTester tester) async {
    [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();
  }

  Future<void> addBook(AppDatabase db) => WorkRepository(db).add(
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: const [],
  );

  testApp('greets by the time of day, and moves on only when the app '
      'comes back', (tester, db) async {
    var now = DateTime(2026, 10, 24, 14, 20);
    await pumpApp(tester, db, clock: () => now);
    expect(find.text('Saturday afternoon'), findsOne);

    now = DateTime(2026, 10, 24, 21);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Saturday afternoon'), findsOne, reason: 'no ticking');

    await comeBack(tester);
    expect(find.text('Saturday night'), findsOne);

    // Past midnight it's still Saturday's night.
    now = DateTime(2026, 10, 25, 1);
    await comeBack(tester);
    expect(find.text('Saturday night'), findsOne);
  });

  testApp('glides on through an evening, but never backwards into the '
      'next', (tester, db) async {
    var now = DateTime(2026, 10, 24, 14);
    await pumpApp(tester, db, clock: () => now, reduceMotion: false);
    void resume() => [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);

    now = DateTime(2026, 10, 24, 23);
    resume();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue, reason: 'on to the night');
    await tester.pumpAndSettle();

    now = DateTime(2026, 10, 25, 8);
    resume();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse, reason: 'a new day');
    expect(find.text('Sunday morning'), findsOne);
  });

  testApp("says what's left today, then the book", (tester, db) async {
    final day = DateTime(2026, 10, 22);
    final works = WorkRepository(db);
    await works.addTask(name: 'Answer the client emails', day: day);
    await works.addTask(name: 'Write the Q3 report', day: day);
    await works.addTask(name: 'Call the bank', day: day);
    await addBook(db);
    await pumpApp(tester, db);
    expect(
      find.text(
        en.todaySkyBoth(en.todaySkyTasks(3), en.todaySkyThen('paperBook')),
      ),
      findsOne,
    );
  });

  testApp('with nothing planned, it says so', (tester, db) async {
    await pumpApp(tester, db);
    expect(find.text(en.todaySkyFree), findsOne);
  });

  testApp('with only the book, it says just the book', (tester, db) async {
    await addBook(db);
    await pumpApp(tester, db);
    expect(find.text(en.todaySkyOnlyWork('paperBook')), findsOne);
  });
}
