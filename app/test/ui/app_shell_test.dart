import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));

  testApp('opens on Tonight with the four sections in the bottom nav', (
    tester,
    db,
  ) async {
    await pumpApp(tester, db);

    final nav = find.byType(NavigationBar);
    for (final label in [
      en.navToday,
      en.navBooks,
      en.navCalendar,
      en.navBuilding,
    ]) {
      expect(find.descendant(of: nav, matching: find.text(label)), findsOne);
    }
    // Friends comes back with phase 2.
    expect(find.text(en.navFriends), findsNothing);
    expect(find.text(en.tonightEmpty), findsOne);
    // Down by the thumb, where the primary action is on every screen.
    final add = find.widgetWithText(FilledButton, en.tonightAddBook);
    final bar = tester.getTopLeft(nav).dy;
    expect(bar - tester.getBottomLeft(add).dy, lessThan(48));
  });

  testApp('Settings is a labelled button on every tab', (tester, db) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, db);

    for (final tab in [
      en.navToday,
      en.navBooks,
      en.navCalendar,
      en.navBuilding,
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(en.settings), findsOne, reason: tab);

      await tester.tap(find.byTooltip(en.settings));
      await tester.pumpAndSettle();
      expect(find.text(en.settings), findsOne, reason: tab);
      await tester.binding.handlePopRoute(); // Android back
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testApp('switching to Persian lays the app out right to left', (
    tester,
    db,
  ) async {
    await pumpApp(tester, db);

    await tester.tap(find.byTooltip(en.settings));
    await tester.pumpAndSettle();
    // Language names are written in their own language, not translated.
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); // Android back
    await tester.pumpAndSettle();

    final tonight = find.text(fa.navToday).first;
    expect(Directionality.of(tester.element(tonight)), TextDirection.rtl);
    expect(await SettingsRepository(db).locale(), const Locale('fa'));
  });
}
