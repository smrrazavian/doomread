import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The House close up, with the user's Window showing what they're on,
/// and on Shab-e Yalda, with its pomegranates.
void main() {
  const windows = [
    HouseWindow.yours,
    HouseWindow.earlierTonight,
    HouseWindow.pastEvening,
    HouseWindow.pastEvening,
  ];

  for (final lang in ['en', 'fa']) {
    for (final (kind, yalda) in [
      for (final yalda in [false, true])
        for (final kind in [
          WorkKind.paperBook,
          WorkKind.film,
          WorkKind.podcast,
        ])
          (kind, yalda),
    ]) {
      final name = '${yalda ? 'yalda_' : ''}${kind.name}';
      testWidgets('The House for a ${kind.name}${yalda ? ' on Yalda' : ''}, '
          'in $lang', (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 800)
          ..devicePixelRatio = 4;
        addTearDown(tester.view.reset);
        // The pulse holds still at full brightness.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildTheme(Locale(lang)),
            home: Scaffold(
              body: Center(
                child: HouseView(windows: windows, kind: kind, yalda: yalda),
              ),
            ),
          ),
        );
        await tester.pump();
        await expectLater(
          find.byType(HouseView),
          matchesGoldenFile('house_${name}_$lang.png'),
        );
      });
    }
  }
}
