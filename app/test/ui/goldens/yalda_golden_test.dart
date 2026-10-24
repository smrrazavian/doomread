import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/poster_image.dart';
import 'package:doomread/ui/share/widgets/yalda_poster.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// Shab-e Yalda: Tonight's line, and the poster as it's shared.
void main() {
  for (final lang in ['en', 'fa']) {
    final fa = lang == 'fa';
    final title = fa ? 'بازمانده‌ی روز' : 'The Remains of the Day';
    final author = fa ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro';

    testWidgets('the Yalda poster, in $lang', (tester) async {
      final boundary = GlobalKey();
      tester.view
        ..physicalSize = const Size(720, 1560)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final locale = Locale(lang);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildTheme(locale),
          home: FittedBox(
            child: RepaintBoundary(
              key: boundary,
              child: YaldaPoster(
                work: Work(
                  id: 'remains',
                  title: title,
                  author: author,
                  totalPages: 245,
                  checkpoints: const [],
                ),
                minutes: 47,
                house: const [
                  HouseWindow.yours,
                  HouseWindow.earlierTonight,
                  HouseWindow.pastEvening,
                  HouseWindow.pastEvening,
                  HouseWindow.pastEvening,
                  HouseWindow.pastEvening,
                ],
                evening: DateTime(2026, 12, 21),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await tester.runAsync(() => posterImage(render)))!;
      addTearDown(image.dispose);
      expect((image.width, image.height), (1080, 1920));
      await expectLater(image, matchesGoldenFile('yalda_poster_$lang.png'));
    });

    testApp('Tonight on Yalda, after reading, in $lang', (tester, db) async {
      tester.view
        ..physicalSize = const Size(720, 1560)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      var now = DateTime(2026, 12, 21, 21);
      final id = await WorkRepository(db).add(
        title: title,
        author: author,
        totalPages: 245,
        checkpoints: [34, 66, 98, 128, 156, 194, 222],
      );
      await SettingsRepository(db).setLocale(Locale(lang));
      final sessions = SessionRepository(db, clock: () => now);
      final record = SessionRecord(
        id: await sessions.start(id),
        road: Road(
          Work(id: id, title: '', author: '', totalPages: 245, checkpoints: []),
          position: 0,
        ),
        events: const [],
      );
      now = DateTime(2026, 12, 21, 21, 47);
      await sessions.add(record, SessionEventKind.stop);
      await sessions.end(record, page: 38);
      await pumpApp(tester, db, clock: () => now);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('tonight_yalda_$lang.png'),
      );
    });
  }
}
