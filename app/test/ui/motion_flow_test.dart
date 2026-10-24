import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/road_view.dart';
import 'package:doomread/ui/evening/widgets/odometer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'haptics.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> openAt(
    WidgetTester tester,
    AppDatabase db,
    int page, {
    String lang = 'en',
  }) async {
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
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now);
  }

  /// From Tonight to End of the evening, after a few minutes in one go.
  Future<void> toEvening(WidgetTester tester, [AppLocalizations? l10n]) async {
    l10n ??= en;
    await tester.tap(find.text(l10n.startReading));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(l10n.stopForTonight));
    await tester.pumpAndSettle();
  }

  /// Motion back on, after the House (whose Window pulses) is gone.
  Future<void> allowMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    return tester.pump();
  }

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
    await allowMotion(tester);
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

  /// The page as the field holds it.
  String pageField(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const Key('page'))).controller!.text;

  for (final lang in ['en', 'fa']) {
    testApp('the page rolls over like an odometer on the steppers, in $lang', (
      tester,
      db,
    ) async {
      await openAt(tester, db, 149, lang: lang);
      await toEvening(tester, lookupAppLocalizations(Locale(lang)));
      await allowMotion(tester);
      await tester.tap(find.byKey(const Key('pageUp')));
      await tester.pump();
      expect(
        pageField(tester),
        lang == 'en' ? '150' : '۱۵۰',
        reason: 'the number itself is at once',
      );
      await tester.pump(const Duration(milliseconds: 60));
      final odometer = find.byType(Odometer);
      final early = tester.widget<Odometer>(odometer);
      expect(early.up, isTrue);
      await tester.pump(const Duration(milliseconds: 60));
      final later = tester.widget<Odometer>(odometer);
      expect(later.t, greaterThan(early.t), reason: 'it rolls on');
      expect(later.t, lessThan(1));

      // Level with the field's text, and centred where it draws it.
      final rolled = tester.getRect(odometer);
      final text = find.descendant(
        of: find.byKey(const Key('page')),
        matching: find.byType(EditableText),
      );
      expect(rolled.top, closeTo(tester.getRect(text).top, 0.01));
      expect(rolled.height, closeTo(tester.getRect(text).height, 0.01));

      await tester.pumpAndSettle();
      expect(odometer, findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(const Key('page'))).style!.color,
        isNot(Colors.transparent),
      );
      final field = tester.allRenderObjects.whereType<RenderEditable>().first;
      final glyphs = MatrixUtils.transformRect(
        field.getTransformTo(null),
        field
            .getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: pageField(tester).length,
              ),
            )
            .single
            .toRect(),
      );
      expect(rolled.center.dx, closeTo(glyphs.center.dx, 0.05));
    });
  }

  testApp('with reduced motion, the page just changes', (tester, db) async {
    await openAt(tester, db, 149);
    await toEvening(tester);
    await tester.tap(find.byKey(const Key('pageUp')));
    await tester.pump();
    expect(pageField(tester), '150');
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(Odometer), findsNothing);
  });

  testApp('saving the Evening turns the light off before Tonight', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142);
    await toEvening(tester);
    await allowMotion(tester);
    final note = find.descendant(
      of: find.byKey(const Key('note')),
      matching: find.byType(EditableText),
    );
    await tester.tap(note);
    await tester.pump();
    final typing = tester.state<EditableTextState>(note);
    await tester.tap(find.text(en.saveAndLightsOut));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester.state<EditableTextState>(note),
      same(typing),
      reason: 'the screen under the dark keeps its state',
    );
    expect(typing.widget.focusNode.hasFocus, isTrue);
    final dark = find.byKey(const Key('lightsOut'));
    expect(dark, findsOne);
    final dim = tester
        .widget<ColoredBox>(
          find.descendant(of: dark, matching: find.byType(ColoredBox)),
        )
        .color
        .a;
    expect(dim, inExclusiveRange(0, 0.85));
    expect(find.text(en.saveAndLightsOut), findsOne, reason: 'not gone yet');

    await tester.pumpAndSettle();
    expect(find.text(en.saveAndLightsOut), findsNothing);
    expect(find.text(en.startReading), findsOne);
  });

  testApp('with reduced motion, saving goes straight to Tonight', (
    tester,
    db,
  ) async {
    await openAt(tester, db, 142);
    await toEvening(tester);
    await tester.tap(find.text(en.saveAndLightsOut));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('lightsOut')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(en.startReading), findsOne);
  });
}
