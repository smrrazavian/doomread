import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../calendar_flow_test.dart' show dayTile, seedMonth;

void main() {
  /// The Calendar on 22 October with the seeded month, the legend's
  /// minutes showing: Mehr 1405 in Persian, October 2026 in English.
  Future<void> openIn(WidgetTester tester, AppDatabase db, String lang) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await seedMonth(db, lang: lang);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db);
    final l10n = lookupAppLocalizations(Locale(lang));
    await tester.tap(find.text(l10n.navCalendar));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.calendarLegendFocus));
    await tester.pumpAndSettle();
  }

  for (final lang in ['en', 'fa']) {
    testApp('the Calendar, in $lang', (tester, db) async {
      await openIn(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('calendar_$lang.png'),
      );
    });

    testApp("a day's sheet, in $lang", (tester, db) async {
      await openIn(tester, db, lang);
      await tester.tap(dayTile(DateTime(2026, 10, 20)));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('calendar_day_$lang.png'),
      );
    });
  }
}
