import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openIn(WidgetTester tester, String lang) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = SettingsRepository(db);
    await settings.setLocale(Locale(lang));

    await tester.pumpWidget(DoomreadApp(settings: settings));
    await tester.pumpAndSettle();
  }

  for (final lang in ['en', 'fa']) {
    testWidgets('Tonight, empty, in $lang', (tester) async {
      await openIn(tester, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_empty_$lang.png'),
      );
    });

    testWidgets('Settings in $lang', (tester) async {
      await openIn(tester, lang);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('settings_$lang.png'),
      );
    });
  }
}
