import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/empty_scenes.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// Each empty-state scene close up, with the line that goes under it.
void main() {
  final lines = <EmptyScene, String Function(AppLocalizations)>{
    EmptyScene.darkWindow: (l10n) => l10n.emptyTonight,
    EmptyScene.emptyShelf: (l10n) => l10n.emptyLibrary,
    EmptyScene.blankPage: (l10n) => l10n.emptyStory,
  };

  for (final lang in ['en', 'fa']) {
    for (final MapEntry(key: scene, value: line) in lines.entries) {
      testWidgets('the ${scene.name} scene, in $lang', (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 1280)
          ..devicePixelRatio = 4;
        addTearDown(tester.view.reset);
        // The light is simply on.
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Builder(
                    builder: (context) => Column(
                      key: const Key('scene'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptySceneView(scene),
                        const SizedBox(height: 16),
                        Text(
                          line(AppLocalizations.of(context)),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await expectLater(
          find.byKey(const Key('scene')),
          matchesGoldenFile('empty_${scene.name}_$lang.png'),
        );
      });
    }
  }

  for (final lang in ['en', 'fa']) {
    testApp('the Book page with no Notes yet, in $lang', (tester, db) async {
      tester.view
        ..physicalSize = const Size(720, 1560)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final title = lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day';
      await WorkRepository(db).add(
        title: title,
        author: lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
        totalPages: 245,
        checkpoints: const [34, 66, 98, 128, 156, 194, 222],
      );
      await SettingsRepository(db).setLocale(Locale(lang));
      await pumpApp(tester, db);
      // The book's title on Tonight opens its page.
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('book_no_notes_$lang.png'),
      );
    });
  }
}
