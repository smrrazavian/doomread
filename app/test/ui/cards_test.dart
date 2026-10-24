import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
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
    // The Note stays off the receipt.
    expect(find.text('Not on it.'), findsNothing);
    expect(sheet.shared, isEmpty);

    await tap(tester, find.byType(BackButton));
    expect(find.byType(ReceiptPoster), findsNothing);
    expect(find.text(en.startReading), findsOne);
  });
}
