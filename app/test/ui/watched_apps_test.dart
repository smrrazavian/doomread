import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const installed = [
    (package: 'org.example.feed', label: 'Feed'),
    (package: 'com.instagram.android', label: 'Instagram'),
  ];

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> addBook(AppDatabase db) async {
    await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
  }

  testApp('the first Start offers the disclosure once, and the Session '
      'starts whatever the answer', (tester, db) async {
    await addBook(db);
    final w = FakeAppWatch(isEnabled: false);
    await pumpApp(tester, db, watch: w);
    await tap(tester, find.text(l10n.startReading));
    expect(find.text(l10n.watchAskTitle), findsOne);
    await tap(tester, find.byKey(const Key('watchAgree')));
    expect(w.settingsOpened, 1);
    expect(find.text(l10n.stopForTonight), findsOne);

    await tap(tester, find.text(l10n.stopForTonight));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text(l10n.startReading));
    expect(find.text(l10n.watchAskTitle), findsNothing);
  });

  testApp('Not now opens nothing', (tester, db) async {
    await addBook(db);
    final w = FakeAppWatch(isEnabled: false);
    await pumpApp(tester, db, watch: w);
    await tap(tester, find.text(l10n.startReading));
    await tap(tester, find.byKey(const Key('watchNotNow')));
    expect(w.settingsOpened, 0);
    expect(find.text(l10n.stopForTonight), findsOne);
  });

  testApp('Watched apps lists the apps, Watched first, and remembers picks', (
    tester,
    db,
  ) async {
    final w = FakeAppWatch(isEnabled: false, installed: installed);
    await pumpApp(tester, db, watch: w);
    await tap(tester, find.byTooltip(l10n.settings));
    await tap(tester, find.text(l10n.watchedApps));
    expect(find.text(l10n.watchOff), findsOne);
    final rows = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(
      [for (final r in rows) (r.title! as Text).data],
      ['Instagram', 'Feed'],
    );

    await tap(tester, find.text('Feed'));
    expect(
      await SettingsRepository(db).watchedApps(),
      contains('org.example.feed'),
    );

    await tap(tester, find.text(l10n.watchTurnOn));
    await tap(tester, find.byKey(const Key('watchAgree')));
    expect(w.settingsOpened, 1);
  });
}
