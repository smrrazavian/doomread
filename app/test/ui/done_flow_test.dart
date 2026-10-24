import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/tasks/widgets/task_list.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'haptics.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));
  final today = DateTime(2026, 10, 22);
  const report = 'Write the Q3 report';
  const bank = 'Call the bank';

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Works on the report for [minutes], then taps Done.
  Future<List<Object?>> workThenDone(
    WidgetTester tester,
    AppDatabase db, {
    bool another = true,
    bool reduceMotion = true,
    int minutes = 52,
  }) async {
    now = DateTime(2026, 10, 22, 21);
    final works = WorkRepository(db);
    await works.addTask(name: report, day: today);
    if (another) await works.addTask(name: bank, day: today);
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
    await tap(tester, find.text(en.startWork('task')).first);
    now = now.add(Duration(minutes: minutes));
    await tester.pump(const Duration(seconds: 1));
    final buzzes = haptics(tester);
    // Motion on only now: the caret at the desk would never let a test
    // settle.
    if (!reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
    }
    await tester.tap(find.text(en.taskDone));
    // Not settled: with motion on, the window is still lighting up.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    return buzzes;
  }

  testApp('Done plays the moment once: the title, the Tone line and what '
      'it took, with a firm buzz', (tester, db) async {
    final buzzes = await workThenDone(tester, db);
    await tester.pumpAndSettle();
    expect(find.text(en.doneTitle(report)), findsOne);
    expect(
      find.text(voice(Moment.taskDone, Tone.spicy, 'en', {'minutes': '52'})),
      findsOne,
    );
    expect(find.text('52'), findsNWidgets(2), reason: 'minutes and longest');
    expect(find.text('0'), findsOne, reason: 'no Urges');
    expect(buzzes, contains('HapticFeedbackType.heavyImpact'));

    await tap(tester, find.text(en.doneBreather));
    expect(
      tester.widget<TaskWindow>(find.byType(TaskWindow).first).lit,
      isTrue,
    );
  });

  testApp('with reduced motion, the end state shows at once', (
    tester,
    db,
  ) async {
    await workThenDone(tester, db);
    expect(find.text(en.doneTitle(report)), findsOne);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testApp('with motion, the window lights up over time', (tester, db) async {
    await workThenDone(tester, db, reduceMotion: false);
    expect(tester.hasRunningAnimations, isTrue);
    // The Done moment and the Today under it; stop before the House pulses.
    await tester.pump(const Duration(seconds: 2));
  });

  testApp('Undo makes the Task undone again', (tester, db) async {
    await workThenDone(tester, db);
    await tester.pumpAndSettle();
    await tap(tester, find.text(en.undo));
    expect(find.text(en.taskAdd), findsOne, reason: 'back on Today');
    final row = await db.select(db.works).get();
    expect(row.where((w) => w.title == report).single.doneAt, isNull);
    expect(
      tester.widget<TaskWindow>(find.byType(TaskWindow).first).lit,
      isFalse,
    );
  });

  testApp('Next starts the next undone Task', (tester, db) async {
    await workThenDone(tester, db);
    await tester.pumpAndSettle();
    await tap(tester, find.text(en.doneNext(bank)));
    expect(find.text(en.taskWorkingOn), findsOne);
    expect(find.text(bank), findsOne);
  });

  testApp('Next is hidden when no undone Task is left', (tester, db) async {
    await workThenDone(tester, db, another: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Next'), findsNothing);
    expect(find.text(en.doneBreather), findsOne);
  });
}
