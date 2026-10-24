import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpHouse(
  WidgetTester tester,
  List<HouseWindow> windows, {
  bool backOn = false,
}) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(const Locale('en')),
        home: Scaffold(body: HouseView(windows: windows, backOn: backOn)),
      ),
    );

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// How lit the user's Window and a past evening's are in the frame just
/// painted, from 0 to 1.
({double yours, double past}) lit(WidgetTester tester) {
  final pastFill = Color.lerp(Palette.unlit, Palette.lamp, 0.22)!;
  var yours = 0.0;
  var past = 0.0;
  bool same(Color a, Color b) =>
      a.toARGB32() & 0xFFFFFF == b.toARGB32() & 0xFFFFFF;
  expect(
    tester.renderObject(
      find.descendant(
        of: find.byType(HouseView),
        matching: find.byType(CustomPaint),
      ),
    ),
    paints..everything((method, args) {
      if (method != #drawRRect) return true;
      final paint = args[1] as Paint;
      if (paint.style != PaintingStyle.fill) return true;
      if (same(paint.color, Palette.me)) yours = paint.color.a;
      if (same(paint.color, pastFill)) past = paint.color.a;
      return true;
    }),
  );
  return (yours: yours, past: past);
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const some = [HouseWindow.yours, HouseWindow.pastEvening];

  testWidgets("the Windows light up and the user's own keeps pulsing", (
    tester,
  ) async {
    await pumpHouse(tester, some);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Stop the pulse before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion, nothing moves', (tester) async {
    reduceMotion(tester);
    await pumpHouse(tester, some);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('an empty House says so kindly', (tester) async {
    reduceMotion(tester);
    await pumpHouse(tester, const [HouseWindow.yours]);
    expect(find.text(l10n.houseEmpty), findsOneWidget);
    await pumpHouse(tester, some);
    expect(find.text(l10n.houseYours), findsOneWidget);
  });

  testWidgets("the user's Window switches on first, like a lamp", (
    tester,
  ) async {
    await pumpHouse(tester, some);
    await tester.pump(const Duration(milliseconds: 250));
    expect(lit(tester).yours, 0, reason: 'still dark');
    await tester.pump(const Duration(milliseconds: 90));
    final on = lit(tester);
    expect(on.yours, greaterThan(0.8), reason: 'on at once, not a fade');
    expect(on.past, 0, reason: 'the others follow');
    await tester.pump(const Duration(milliseconds: 60));
    expect(lit(tester).yours, lessThan(0.6), reason: 'the stutter');
    await tester.pump(const Duration(seconds: 1));
    expect(lit(tester).yours, greaterThan(0.6));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("back from an Urge, only the user's Window flickers on", (
    tester,
  ) async {
    await pumpHouse(tester, some, backOn: true);
    expect(lit(tester), (yours: 0.0, past: 1.0));
    await tester.pump(const Duration(milliseconds: 70));
    final first = lit(tester).yours;
    await tester.pump(const Duration(milliseconds: 85));
    expect(lit(tester).yours, lessThan(first - 0.5), reason: 'a flicker');
    await tester.pump(const Duration(seconds: 1));
    expect(lit(tester).yours, greaterThan(0.6));
    expect(lit(tester).past, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion, it is simply back on', (tester) async {
    reduceMotion(tester);
    await pumpHouse(tester, some, backOn: true);
    expect(lit(tester), (yours: 1.0, past: 1.0));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
