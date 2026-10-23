import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpHouse(WidgetTester tester, List<HouseWindow> windows) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(const Locale('en')),
        home: Scaffold(body: HouseView(windows: windows)),
      ),
    );

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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
}
