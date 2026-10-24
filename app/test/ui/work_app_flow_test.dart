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

  testApp('two reports while Shorts loads raise one Urge', (tester, db) async {
    final w = await startOnYouTube(tester, db);
    w
      ..onForeground!(youtube, 'YouTube', shorts)
      ..onForeground!(youtube, 'YouTube', watchedScreens.single.anyOf);
    await tester.pumpAndSettle();
    final urges = (await db.select(db.sessionEvents).get()).where(
      (e) => e.kind == SessionEventKind.urge,
    );
    expect(urges, hasLength(1));
  });

  /// Tonight with a podcast, current, and a paper book behind it.
  Future<(String, String)> openTonight(
    WidgetTester tester,
    AppDatabase db,
  ) async {
    final works = WorkRepository(db);
    final podcast = await works.add(
      title: 'Lex Fridman #400',
      author: 'Lex Fridman',
      totalPages: 180,
      kind: WorkKind.podcast,
      checkpoints: const [],
    );
    final book = await works.add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(
      tester,
      db,
      clock: () => DateTime(2026, 10, 22, 21),
      watch: FakeAppWatch(
        installed: [
          (package: 'com.instagram.android', label: 'Instagram'),
          (package: 'org.telegram.messenger', label: 'Telegram'),
          (package: youtube, label: 'YouTube'),
        ],
      ),
    );
    return (podcast, book);
  }

  bool selected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  testApp('the Work app picked on Tonight is kept for that Work only', (
    tester,
    db,
  ) async {
    final (podcast, book) = await openTonight(tester, db);
    expect(selected(tester, l10n.whereIsElsewhere('podcast')), isTrue);

    await tester.tap(find.text(l10n.whereIsPhone));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'YouTube'), isTrue);
    expect((await SettingsRepository(db).workApps()).keys, [podcast]);

    await WorkRepository(db).setCurrent(book);
    await tester.pumpAndSettle();
    expect(selected(tester, l10n.whereIsElsewhere('paperBook')), isTrue);
    expect(find.text('YouTube'), findsNothing);

    await WorkRepository(db).setCurrent(podcast);
    await tester.pumpAndSettle();
    expect(selected(tester, 'YouTube'), isTrue);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.workAppReading('YouTube')), findsOne);
    expect(find.text(l10n.faceDown), findsNothing);
  });

  testApp('the picker puts likely apps first and searches by name', (
    tester,
    db,
  ) async {
    await openTonight(tester, db);
    await tester.tap(find.text(l10n.whereIsPhone));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('YouTube')).dy,
      lessThan(tester.getTopLeft(find.text('Instagram')).dy),
    );

    await tester.enterText(find.byType(TextField), 'TEL');
    await tester.pumpAndSettle();
    expect(find.text('Telegram'), findsOne);
    expect(find.text('YouTube'), findsNothing);
    expect(find.text('Instagram'), findsNothing);
    expect(find.text(l10n.workAppNone), findsOne);
  });
}
