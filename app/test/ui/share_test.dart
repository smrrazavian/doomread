import 'dart:typed_data';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/widgets/finish_poster.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fa = lookupAppLocalizations(const Locale('fa'));

  group('the Pictures folder on Linux', () {
    const env = {'HOME': '/home/sara'};

    test(r'is XDG_PICTURES_DIR, with $HOME filled in', () {
      expect(
        picturesDir(
          env,
          '# comment\n'
          r'XDG_PICTURES_DIR="$HOME/Bilder"',
        ),
        '/home/sara/Bilder',
      );
      expect(picturesDir(env, 'XDG_PICTURES_DIR="/mnt/photos"'), '/mnt/photos');
    });

    test('is ~/Pictures without one, or when it points at home', () {
      expect(picturesDir(env, null), '/home/sara/Pictures');
      expect(
        picturesDir(env, r'XDG_PICTURES_DIR="$HOME/"'),
        '/home/sara/Pictures',
      );
    });
  });

  group('the share preview', () {
    /// A finished book with two Sessions on it, the last Note on the second,
    /// and one Urge let pass. Returns its Finish.
    Future<Finish> finished(AppDatabase db, DateTime Function() clock) async {
      final sessions = SessionRepository(db, clock: clock);
      final id = await WorkRepository(db).add(
        title: 'The Remains of the Day',
        author: 'Kazuo Ishiguro',
        totalPages: 245,
        checkpoints: const [],
      );
      final work = Work(
        id: id,
        title: '',
        author: '',
        totalPages: 245,
        checkpoints: const [],
      );
      for (final (page, note) in [
        (120, 'Darlington Hall, in the old days.'),
        (245, 'The pier, the lights, a smile.'),
        (245, ''),
      ]) {
        final record = SessionRecord(
          id: await sessions.start(id),
          road: Road(work, position: 0),
          events: const [],
        );
        if (page == 120) {
          await sessions.add(record, SessionEventKind.urge);
          await sessions.add(record, SessionEventKind.letPass);
        }
        await sessions.add(record, SessionEventKind.stop);
        await sessions.end(record, page: page, note: note);
      }
      await (db.update(db.works)..where((w) => w.id.equals(id))).write(
        const WorksCompanion(position: Value(245)),
      );
      return Finish.of(Road(work, position: 245), const [])!;
    }

    Future<FakeShareSheet> open(
      WidgetTester tester,
      AppDatabase db,
      Finish finish,
    ) async {
      final sheet = FakeShareSheet();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(
              value: SessionRepository(db, clock: () => DateTime(2026, 10, 22)),
            ),
            Provider<ShareSheet>.value(value: sheet),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildTheme(const Locale('en')),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => openFinishPreview(
                  context,
                  finish: finish,
                  floors: 1,
                  floor: 0,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return sheet;
    }

    testApp('shows the last Note, and the Urges let pass, until turned off', (
      tester,
      db,
    ) async {
      final now = DateTime(2026, 10, 22, 21);
      final finish = await finished(db, () => now);
      await open(tester, db, finish);

      FinishPoster poster() => tester.widget(find.byType(FinishPoster));
      expect(poster().note, 'The pier, the lights, a smile.');
      expect(poster().urgesLetPass, 1);
      expect(find.text('The pier, the lights, a smile.'), findsOne);
      expect(find.text(en.sharePosterUrges(1)), findsOne);

      await tester.tap(find.byKey(const Key('showNote')));
      await tester.pumpAndSettle();
      expect(poster().note, isNull);
      expect(find.text('The pier, the lights, a smile.'), findsNothing);
    });

    testApp('shares the poster as a 1080×1920 PNG', (tester, db) async {
      final finish = await finished(db, () => DateTime(2026, 10, 22, 21));
      final sheet = await open(tester, db, finish);

      await tester.tap(find.text(en.shareSend));
      // Drawing the image is real work, outside the test's fake time, and
      // slower while the rest of the suite runs alongside.
      for (var i = 0; i < 50 && sheet.shared.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final png = sheet.shared.single;
      expect(png.name, 'doomread-20261022-000000.png');
      expect(png.title, en.shareSendTo);
      final header = ByteData.sublistView(png.png);
      expect((header.getUint32(16), header.getUint32(20)), (1080, 1920));
      expect(
        find.text(en.shareSavedTo('/home/me/Pictures/${png.name}')),
        findsOne,
      );
    });

    testApp('has no Note switch when there is no Note', (tester, db) async {
      final id = await WorkRepository(db).add(
        title: 'Piranesi',
        author: 'Susanna Clarke',
        totalPages: 10,
        checkpoints: const [],
      );
      final work = Work(
        id: id,
        title: 'Piranesi',
        author: 'Susanna Clarke',
        totalPages: 10,
        checkpoints: const [],
      );
      await open(tester, db, Finish.of(Road(work, position: 10), const [])!);
      expect(find.byKey(const Key('showNote')), findsNothing);
      expect(
        tester.widget<FinishPoster>(find.byType(FinishPoster)).note,
        isNull,
      );
    });
  });

  testApp('Show it off on the Finish opens the poster with the Note on', (
    tester,
    db,
  ) async {
    var now = DateTime(2026, 10, 22, 21);
    final id = await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(id))).write(
      const WorksCompanion(position: Value(230)),
    );
    await SettingsRepository(db).setLocale(const Locale('en'));
    await pumpApp(tester, db, clock: () => now);

    await tester.tap(find.text(en.startReading));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(en.stopForTonight));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('page')), '245');
    await tester.enterText(find.byKey(const Key('note')), 'The pier lights.');
    await tester.tap(find.text(en.saveAndLightsOut));
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.shareAction));
    await tester.pumpAndSettle();
    expect(find.text(en.sharePreviewTitle), findsOne);
    expect(find.text('The pier lights.'), findsOne);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('showNote'))).value,
      isTrue,
    );
  });

  test('Persian poster numbers are in Persian digits', () {
    expect(fa.sharePosterPages(245, 3), '۲۴۵ صفحه توی ۳ شب');
    expect(fa.sharePosterTitle('بوف کور'), '«بوف کور»');
  });
}
