import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/poster_image.dart';
import 'package:doomread/ui/share/widgets/finish_poster.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens for the Finish poster, drawn the way it's shared: 1080×1920,
/// on a phone of another size.
void main() {
  final boundary = GlobalKey();

  /// [work] finished over [minutes], one Session per evening in October.
  Finish finished(Work work, List<int> minutes) {
    final sittings = [
      for (final (i, m) in minutes.indexed)
        (
          session: Session.fromEvents([
            SessionEvent(
              SessionEventKind.start,
              DateTime(2026, 10, 10 + i, 21),
            ),
            SessionEvent(
              SessionEventKind.stop,
              DateTime(2026, 10, 10 + i, 21, m),
            ),
          ], now: DateTime(2026, 10, 22)),
          toPage: i == minutes.length - 1 ? work.totalPages : i + 1,
          note: '',
        ),
    ];
    return Finish.of(Road(work, position: work.totalPages), sittings)!;
  }

  Future<void> pumpPoster(
    WidgetTester tester,
    String lang,
    FinishPoster poster,
  ) async {
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
        // Scaled down to fit, as in the preview.
        home: FittedBox(
          child: RepaintBoundary(key: boundary, child: poster),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The image as it's shared.
  Future<void> expectPoster(WidgetTester tester, String golden) async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => posterImage(render)))!;
    addTearDown(image.dispose);
    expect((image.width, image.height), (1080, 1920));
    await expectLater(image, matchesGoldenFile(golden));
  }

  for (final lang in ['en', 'fa']) {
    final fa = lang == 'fa';
    final remains = Work(
      id: 'remains',
      title: fa ? 'بازمانده‌ی روز' : 'The Remains of the Day',
      author: fa ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );

    testWidgets('the Finish poster with a Note, in $lang', (tester) async {
      await pumpPoster(
        tester,
        lang,
        FinishPoster(
          finish: finished(remains, [6, 14, 9, 23]),
          floors: 3,
          floor: 0,
          urgesLetPass: 7,
          note: fa
              ? 'استیونز بالاخره قبول می‌کنه دلش برای دوشیزه کنتون تنگ شده، '
                    'ولی فقط پیش خودش.'
              : 'Stevens finally admits he misses Miss Kenton, '
                    'but only to himself.',
        ),
      );
      await expectPoster(tester, 'poster_$lang.png');
    });

    testWidgets('the Finish poster for a podcast, no Note, in $lang', (
      tester,
    ) async {
      final podcast = Work(
        id: 'podcast',
        title: fa
            ? 'رادیو مرز: قسمت ویژه‌ی شب‌های طولانی زمستون '
                  'و آدم‌هایی که نخوابیدن'
            : 'The Long Night Special: Everyone Who Stayed Up Until Morning',
        author: fa ? 'رادیو مرز' : 'Radiolab',
        totalPages: 9660,
        checkpoints: const [],
        kind: WorkKind.podcast,
      );
      await pumpPoster(
        tester,
        lang,
        FinishPoster(
          finish: finished(podcast, [31, 52]),
          floors: 7,
          floor: 0,
          urgesLetPass: 0,
        ),
      );
      await expectPoster(tester, 'poster_podcast_$lang.png');
    });
  }
}
