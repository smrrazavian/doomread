import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 22, 21);
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openApp(WidgetTester tester, AppDatabase db) async {
    now = DateTime(2026, 10, 22, 21);
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);
  }

  /// Adds a Work of the kind behind the chip [kind], [length] long.
  Future<void> add(
    WidgetTester tester,
    String kind,
    String title,
    String length,
  ) async {
    await tap(tester, find.text(en.tonightAddBook).first);
    await tap(tester, find.byKey(Key(kind)));
    await tester.enterText(find.byKey(const Key('title')), title);
    await tester.enterText(find.byKey(const Key('pages')), length);
    await tap(tester, find.text(en.save));
  }

  /// One Session from Tonight: [minutes] in one go, ended at [position].
  Future<void> session(
    WidgetTester tester,
    String start,
    int minutes,
    String position,
  ) async {
    await tap(tester, find.text(start));
    now = now.add(Duration(minutes: minutes));
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.text(en.stopForTonight));
    await tester.enterText(find.byKey(const Key('page')), position);
    await tap(tester, find.text(en.saveAndLightsOut));
  }

  testApp('a podcast moves along its Road by timestamps', (tester, db) async {
    await openApp(tester, db);
    await add(tester, 'podcast', 'Radio Marz', '2:41:00');
    expect(find.text(en.timeOf('0:00', '2:41:00')), findsOne);

    await session(tester, en.startWork('podcast'), 20, '1:12:20');
    expect(find.text(en.timeOf('1:12:20', '2:41:00')), findsOne);
    expect(find.text(en.timeLeft('1:28:40')), findsOne);
  });

  testApp('a series counts episodes, up to its Finish', (tester, db) async {
    await openApp(tester, db);
    await add(tester, 'series', 'Dark', '10');
    expect(find.text(en.episodeOf(0, 10)), findsOne);
    expect(find.text(en.nextEpisode(1)), findsOne);

    await session(tester, en.startWork('series'), 50, '10');
    expect(find.text(en.finishedSubEpisodes(10, 1)), findsOne);
  });

  testApp('a film is Finished at its last second', (tester, db) async {
    await openApp(tester, db);
    await add(tester, 'film', 'Paris, Texas', '2:25:00');
    await session(tester, en.startWork('film'), 80, '2:25:00');
    expect(find.text(en.finishedSubTime('2:25:00', 1)), findsOne);
  });

  testApp('watching sets its own Aim, apart from reading', (tester, db) async {
    await openApp(tester, db);
    await add(tester, 'paperBook', 'Dune', '412');
    await session(tester, en.startWork('paperBook'), 6, '30');
    expect(find.text(en.aim(7)), findsOne);

    // A film, added and made current in Books; its Aim starts from nothing.
    await tap(tester, find.text(en.navBooks));
    await add(tester, 'film', 'Paris, Texas', '2:25:00');
    await tap(tester, find.text('Paris, Texas'));
    await tap(tester, find.text(en.navTonight));
    expect(find.text(en.aim(1)), findsOne);
  });
}
