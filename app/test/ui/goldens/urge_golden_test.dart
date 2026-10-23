import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../planned_break_fixture.dart';

void main() {
  // Tonight is 22 October, 21:00. Every Session event is stamped by this.
  var now = DateTime(2026, 10, 22, 21);

  Future<void> open(
    WidgetTester tester,
    AppDatabase db,
    String lang,
    FakeAppWatch watch,
  ) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await SettingsRepository(db).setLocale(Locale(lang));
    await pumpApp(tester, db, clock: () => now, watch: watch);
  }

  /// Six minutes into tonight's Session, Instagram opens.
  Future<FakeAppWatch> urge(
    WidgetTester tester,
    AppDatabase db,
    String lang,
  ) async {
    await addRemainsReadLastNight(db, lang, (t) => now = t);
    final watch = FakeAppWatch();
    await open(tester, db, lang, watch);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 6));
    await tester.pump(const Duration(seconds: 1));
    watch.onForeground!('com.instagram.android', 'Instagram', const {});
    await tester.pumpAndSettle();
    return watch;
  }

  for (final lang in ['en', 'fa']) {
    final l10n = lookupAppLocalizations(Locale(lang));

    testApp('The Urge, in $lang', (tester, db) async {
      await urge(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('urge_$lang.png'),
      );
    });

    testApp('After a slip, in $lang', (tester, db) async {
      await urge(tester, db, lang);
      await tester.tap(find.text(l10n.openAnyway('Instagram')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('after_slip_$lang.png'),
      );
    });

    testApp('The Accessibility disclosure, in $lang', (tester, db) async {
      await addRemainsReadLastNight(db, lang, (t) => now = t);
      await open(tester, db, lang, FakeAppWatch(isEnabled: false));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('watch_disclosure_$lang.png'),
      );
    });

    testApp('Picking the Work app, in $lang', (tester, db) async {
      await addDarkWatchedLastNight(db, lang, (t) => now = t);
      await open(tester, db, lang, FakeAppWatch(installed: _apps));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.workAppAsk));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('work_app_sheet_$lang.png'),
      );
    });

    testApp('Reading with a Work app, in $lang', (tester, db) async {
      await addDarkWatchedLastNight(db, lang, (t) => now = t);
      await open(tester, db, lang, FakeAppWatch(installed: _apps));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.workAppAsk));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reading_work_app_$lang.png'),
      );
    });

    testApp('Watched apps, off, in $lang', (tester, db) async {
      await open(
        tester,
        db,
        lang,
        FakeAppWatch(isEnabled: false, installed: _apps.take(4).toList()),
      );
      await tester.tap(find.byTooltip(l10n.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.watchedApps));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('watched_apps_$lang.png'),
      );
    });
  }
}

const List<LaunchableApp> _apps = [
  (package: 'com.instagram.android', label: 'Instagram'),
  (package: 'com.zhiliaoapp.musically', label: 'TikTok'),
  (package: 'org.telegram.messenger', label: 'Telegram'),
  (package: 'com.google.android.youtube', label: 'YouTube'),
  (package: 'com.netflix.mediaclient', label: 'Netflix'),
];
