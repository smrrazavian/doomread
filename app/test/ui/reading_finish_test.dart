import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));
  const title = 'The Remains of the Day';

  /// Reading, a few minutes in, from [page] of a book whose last
  /// Checkpoint is page 222.
  Future<void> readFrom(WidgetTester tester, AppDatabase db, int page) async {
    now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: title,
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [194, 222],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      WorksCompanion(position: Value(page)),
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
    await tester.tap(find.text(en.startReading));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 7));
    await tester.pump(const Duration(seconds: 1));
  }

  testApp('before the last Checkpoint, Reading offers no Finish', (
    tester,
    db,
  ) async {
    await readFrom(tester, db, 200);
    expect(find.text(en.stopForTonight), findsOne);
    expect(find.text(en.eveningFinished), findsNothing);
  });

  testApp('past the last Checkpoint, "I finished it!" Finishes from Reading', (
    tester,
    db,
  ) async {
    await readFrom(tester, db, 230);
    await tester.tap(find.text(en.eveningFinished));
    await tester.pumpAndSettle();

    expect(find.text(en.finishedTitle(title)), findsOne);
    final work = await db.select(db.works).getSingle();
    expect(work.position, 245);
    final note = await db.select(db.notes).getSingle();
    expect((note.fromPage, note.toPage), (230, 245));
  });
}
