import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const youtube = 'com.google.android.youtube';
  final shorts = watchedScreens.single.anyOf.take(1).toSet();

  /// A Session with a podcast, and YouTube picked as its Work app.
  Future<FakeAppWatch> startOnYouTube(
    WidgetTester tester,
    AppDatabase db,
  ) async {
    await WorkRepository(db).add(
      title: 'Lex Fridman #400',
      author: 'Lex Fridman',
      totalPages: 180,
      kind: WorkKind.podcast,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    final w = FakeAppWatch(
      installed: [
        (package: youtube, label: 'YouTube'),
        (package: 'com.instagram.android', label: 'Instagram'),
      ],
    );
    await pumpApp(
      tester,
      db,
      clock: () => DateTime(2026, 10, 22, 21),
      watch: w,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.workAppAsk));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    return w;
  }

  testApp('switching to the Work app raises no Urge, and Reading says so '
      'instead of "face down"', (tester, db) async {
    final w = await startOnYouTube(tester, db);
    expect(find.text(l10n.faceDown), findsNothing);
    expect(find.text(l10n.workAppReading('YouTube')), findsOne);

    w.onForeground!(youtube, 'YouTube', const {});
    await tester.pumpAndSettle();
    expect(w.fronts, 0);
    expect(find.text(l10n.workAppReading('YouTube')), findsOne);
  });

  testApp('with YouTube as the Work app, Shorts raises the Urge', (
    tester,
    db,
  ) async {
    final w = await startOnYouTube(tester, db);
    expect(w.views.keys, [youtube], reason: 'the service looks for Shorts');

    w.onForeground!(youtube, 'YouTube', shorts);
    await tester.pumpAndSettle();
    expect(w.fronts, 1);
    expect(
      find.text(
        voice(Moment.urge, Tone.spicy, 'en', {'app': 'YouTube Shorts'}),
      ),
      findsOne,
    );
  });

  testApp('a Work not on the phone keeps "face down"', (tester, db) async {
    await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    final w = FakeAppWatch();
    await pumpApp(tester, db, watch: w);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.faceDown), findsOne);
    expect(w.views, isEmpty);
  });

  testApp('the Work app can be taken back', (tester, db) async {
    await startOnYouTube(tester, db);
    await tester.tap(find.text(l10n.workAppReading('YouTube')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.workAppNone).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.faceDown), findsOne);
  });
}
