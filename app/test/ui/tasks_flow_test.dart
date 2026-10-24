import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/tasks/widgets/task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));
  // pumpApp's clock: Thursday 22 October 2026, 21:00.
  final today = DateTime(2026, 10, 22);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> addThroughSheet(WidgetTester tester, String name) async {
    await tap(tester, find.text(en.taskAdd));
    await tester.enterText(find.byKey(const Key('taskName')), name);
    await tap(tester, find.text(en.taskAddButton));
  }

  testApp('a Task added with only a name shows on Today, and the Library '
      'and Tonight stay as they were', (tester, db) async {
    await pumpApp(tester, db);
    expect(find.text(en.navToday), findsWidgets);

    await addThroughSheet(tester, 'Call the bank');
    expect(find.text('Call the bank'), findsOne);
    expect(find.text(en.emptyTonight), findsOne, reason: 'no current Work');

    await tap(tester, find.text(en.navBooks));
    expect(find.text('Call the bank'), findsNothing);
    expect(find.text(en.emptyLibrary), findsOne);
  });

  testApp('a Task needs a name', (tester, db) async {
    await pumpApp(tester, db);
    await tap(tester, find.text(en.taskAdd));
    await tap(tester, find.text(en.taskAddButton));
    expect(find.text(en.taskNoName), findsOne);
  });

  testApp("an earlier day's Task carries over unmarked; a later one "
      'waits', (tester, db) async {
    final works = WorkRepository(db);
    await works.addTask(name: 'Answer the client emails', day: today);
    await works.addTask(
      name: 'Call the bank',
      day: DateTime(2026, 10, 19),
      estimate: const Duration(minutes: 10),
    );
    await works.addTask(name: 'Dentist', day: DateTime(2026, 10, 23));
    await pumpApp(tester, db);

    expect(find.text('Answer the client emails'), findsOne);
    expect(find.text('Dentist'), findsNothing);
    // Carried over, it looks like any other: only its estimate under it.
    final row = find.ancestor(
      of: find.text('Call the bank'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: row.first, matching: find.byType(Text)),
      findsNWidgets(3),
      reason: 'its name, its estimate and its Start',
    );
    expect(find.text(en.taskAbout(10)), findsOne);

    // The first undone one has the filled Start.
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text(en.startWork('task')),
      ),
      findsOne,
    );
    expect(find.byType(TaskWindow), findsNWidgets(2));
  });

  testApp('a Task Done today shows lit, with when and how long in one '
      'go', (tester, db) async {
    final works = WorkRepository(
      db,
      clock: () => DateTime(2026, 10, 22, 11, 40),
    );
    final id = await works.addTask(
      name: 'Answer the client emails',
      day: today,
    );
    await works.setDone(id);
    await pumpApp(tester, db);
    expect(find.text(en.taskDoneAtOnly('11:40')), findsOne);
    expect(tester.widget<TaskWindow>(find.byType(TaskWindow)).lit, isTrue);
    expect(find.text(en.startWork('task')), findsNothing);
  });

  testApp('tapping a Task changes its name, estimate and day', (
    tester,
    db,
  ) async {
    await WorkRepository(db).addTask(name: 'Write the report', day: today);
    await pumpApp(tester, db);

    await tap(tester, find.text('Write the report'));
    expect(find.text(en.taskEdit), findsOne);
    await tester.enterText(
      find.byKey(const Key('taskName')),
      'Write the Q3 report',
    );
    await tester.enterText(find.byKey(const Key('taskEstimate')), '45');
    await tap(tester, find.text(en.save));
    expect(find.text('Write the Q3 report'), findsOne);
    expect(find.text(en.taskAbout(45)), findsOne);

    // Moved to tomorrow, it leaves Today.
    await tap(tester, find.text('Write the Q3 report'));
    await tap(tester, find.text(en.taskDayTomorrow));
    await tap(tester, find.text(en.save));
    expect(find.text('Write the Q3 report'), findsNothing);
  });

  testApp('swiping a Task away deletes it, and Undo brings it back', (
    tester,
    db,
  ) async {
    await WorkRepository(db).addTask(name: 'Call the bank', day: today);
    await pumpApp(tester, db);

    await tester.drag(find.text('Call the bank'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Call the bank'), findsNothing);
    expect(find.text(en.workDeleted('Call the bank')), findsOne);

    await tap(tester, find.text(en.undo));
    expect(find.text('Call the bank'), findsOne);
  });

  testApp("Start opens the Task's Session", (tester, db) async {
    await WorkRepository(db).addTask(name: 'Call the bank', day: today);
    await pumpApp(tester, db);
    await tap(tester, find.text(en.startWork('task')));
    expect(find.text('Call the bank'), findsOne);
    expect(find.text(en.taskAdd), findsNothing, reason: 'off Today');
  });

  testApp('in Persian, the days ahead are named on the Solar Hijri '
      'calendar', (tester, db) async {
    await SettingsRepository(db).setLocale(const Locale('fa'));
    await pumpApp(tester, db);
    await tap(tester, find.text(fa.taskAdd));
    await tap(tester, find.text(fa.taskDayPick));
    // Saturday 24 October 2026 is 2 Aban 1405.
    await tap(tester, find.text('شنبه ۲ آبان'));
    expect(find.text('۲ آبان'), findsOne, reason: 'the chip names it');
    expect(
      tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: find.text('۲ آبان'),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection,
      TextDirection.rtl,
    );
  });
}
