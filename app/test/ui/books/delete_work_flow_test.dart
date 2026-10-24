import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<String> addDune(WorkRepository works) => works.add(
    title: 'Dune',
    author: 'Frank Herbert',
    totalPages: 412,
    checkpoints: const [],
  );

  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text(en.navBooks));
    await tester.pumpAndSettle();
  }

  testApp('swiping a Work away deletes it, and Undo brings it back', (
    tester,
    db,
  ) async {
    await addDune(WorkRepository(db));
    await pumpApp(tester, db);
    await openLibrary(tester);

    await tester.drag(find.text('Dune'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsNothing);
    expect(find.text(en.workDeleted('Dune')), findsOne);

    await tester.tap(find.text(en.undo));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOne);
  });

  testApp('a Work can be deleted from its edit screen', (tester, db) async {
    await addDune(WorkRepository(db));
    await pumpApp(tester, db);
    await openLibrary(tester);

    await tester.tap(find.byTooltip(en.editBook));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.deleteWork));
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsNothing);
    expect(find.text(en.emptyLibrary), findsOne);
    expect(find.text(en.workDeleted('Dune')), findsOne);
  });

  // Plain queries: watching the journal waits on drift timers that fake
  // time never fires.
  Future<List<SessionEventKind>> journal(AppDatabase db) async => [
    for (final e in await db.select(db.sessionEvents).get()) e.kind,
  ];

  testApp('a Session open on a deleted Work stops once Undo is gone', (
    tester,
    db,
  ) async {
    await SessionRepository(db).start(await addDune(WorkRepository(db)));
    await pumpApp(tester, db);
    await openLibrary(tester);

    await tester.drag(find.text('Dune'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(await journal(db), [SessionEventKind.start]);

    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.text(en.undo), findsNothing);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await journal(db), [SessionEventKind.start, SessionEventKind.stop]);
  });

  testApp('leaving the Library right after still stops the Session', (
    tester,
    db,
  ) async {
    await SessionRepository(db).start(await addDune(WorkRepository(db)));
    await pumpApp(tester, db);
    await openLibrary(tester);

    await tester.drag(find.text('Dune'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.navTonight));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await journal(db), [SessionEventKind.start, SessionEventKind.stop]);
  });

  testApp('Undo keeps a Session open on the Work running', (tester, db) async {
    await SessionRepository(db).start(await addDune(WorkRepository(db)));
    await pumpApp(tester, db);
    await openLibrary(tester);

    await tester.drag(find.text('Dune'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.undo));
    await tester.pumpAndSettle();
    expect(await journal(db), [SessionEventKind.start]);
  });
}
