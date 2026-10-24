import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/road_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'haptics.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> openAt(WidgetTester tester, AppDatabase db, int page) async {
    now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      WorksCompanion(position: Value(page)),
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
  }

  /// From Tonight to End of the evening, after a few minutes in one go.
  Future<void> toEvening(WidgetTester tester) async {
    await tester.tap(find.text(en.startReading));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(en.stopForTonight));
    await tester.pumpAndSettle();
  }

  /// Motion back on, after the House (whose Window pulses) is gone.
  void allowMotion(WidgetTester tester) => tester
      .platformDispatcher
      .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();

  /// Where Tonight's "you are here" dot is, from the start of the Road.
  double dot(WidgetTester tester) => tester
      .getCenter(
        find.descendant(
          of: find.byType(RoadView),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        ),
      )
      .dx;

  testApp('Start clicks like a lamp switching on', (tester, db) async {
    await openAt(tester, db, 142);
    final buzzes = haptics(tester);
    await tester.tap(find.text(en.startReading));
    await tester.pumpAndSettle();
    expect(buzzes, ['HapticFeedbackType.lightImpact']);
    expect(find.text(en.stopForTonight), findsOne);
  });

  testApp("after the Evening, Tonight's dot slides to the new Position", (
    tester,
    db,
  ) async {
    await openAt(tester, db, 50);
    final from = dot(tester);
    await toEvening(tester);
    await tester.enterText(find.byKey(const Key('page')), '200');
    allowMotion(tester);
    await tester.tap(find.text(en.saveAndLightsOut));

    final seen = <double>[];
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(RoadView).hitTestable().evaluate().isNotEmpty) {
        seen.add(dot(tester));
      }
    }
    await tester.pumpAndSettle();
    final to = dot(tester);
    expect(to, greaterThan(from));
    expect(
      seen.where((x) => x > from + 1 && x < to - 1),
      isNotEmpty,
      reason: 'seen on its way, not only at the end',
    );
  });
}
