import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/poster_image.dart';
import 'package:doomread/ui/share/widgets/glow_up_poster.dart';
import 'package:doomread/ui/share/widgets/month_poster.dart';
import 'package:doomread/ui/share/widgets/note_poster.dart';
import 'package:doomread/ui/share/widgets/receipt_poster.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens for the share cards beyond the Finish poster, drawn the way
/// they're shared: 1080×1920, on a phone of another size.
void main() {
  final boundary = GlobalKey();

  Future<void> pumpCard(WidgetTester tester, String lang, Widget card) async {
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
          child: RepaintBoundary(key: boundary, child: card),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectCard(WidgetTester tester, String golden) async {
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

    testWidgets("tonight's receipt, with a Slip and a break, in $lang", (
      tester,
    ) async {
      DateTime t(int m) =>
          DateTime(2026, 10, 24, 21, 4).add(Duration(minutes: m));
      SessionEvent e(SessionEventKind kind, int m) => SessionEvent(kind, t(m));
      final session = Session.fromEvents([
        e(SessionEventKind.start, 0),
        e(SessionEventKind.urge, 6),
        e(SessionEventKind.letPass, 6),
        e(SessionEventKind.urge, 14),
        e(SessionEventKind.letPass, 14),
        e(SessionEventKind.breakStart, 19),
        e(SessionEventKind.breakEnd, 24),
        e(SessionEventKind.urge, 30),
        e(SessionEventKind.slip, 30),
        e(SessionEventKind.resume, 33),
        e(SessionEventKind.urge, 41),
        e(SessionEventKind.letPass, 41),
        e(SessionEventKind.stop, 52),
      ], now: t(60));
      await pumpCard(
        tester,
        lang,
        ReceiptPoster(
          work: remains,
          session: session,
          pages: (from: 142, to: 168),
          signOff: voice(Moment.receipt, Tone.mom, lang),
        ),
      );
      await expectCard(tester, 'card_receipt_$lang.png');
    });

    testWidgets('the attention glow-up, in $lang', (tester) async {
      await pumpCard(
        tester,
        lang,
        GlowUpPoster(
          rises: [
            for (final (day, minutes) in [
              (2, 5),
              (5, 7),
              (9, 12),
              (13, 14),
              (18, 22),
              (24, 31),
            ])
              (
                evening: DateTime(2026, 10, day),
                longest: Duration(minutes: minutes, seconds: 20),
              ),
          ],
          watched: false,
        ),
      );
      await expectCard(tester, 'card_glow_up_$lang.png');
    });

    testWidgets('the month of windows, in $lang', (tester) async {
      // The 27th night of the month: 1 Aban 1405 is 23 October 2026.
      final first = fa ? DateTime(2026, 10, 23) : DateTime(2026, 10);
      DateTime day(int n) => DateTime(first.year, first.month, first.day + n);
      const minutes = [
        6, 0, 9, 12, 0, 0, 14, 8, 17, 0, 21, 19, 0, 25, //
        11, 0, 0, 28, 22, 30, 0, 26, 33, 18, 0, 35, 31,
      ];
      final sessions = [
        for (final (n, m) in minutes.indexed)
          if (m > 0)
            Session.fromEvents([
              SessionEvent(
                SessionEventKind.start,
                day(n).add(const Duration(hours: 21)),
              ),
              SessionEvent(
                SessionEventKind.stop,
                day(n).add(Duration(hours: 21, minutes: m)),
              ),
            ], now: day(40)),
      ];
      await pumpCard(
        tester,
        lang,
        MonthPoster(
          month: ReadingMonth(
            now: day(26).add(const Duration(hours: 22)),
            solarHijri: fa,
            sessions: sessions,
          ),
          firstDay: firstDayOfWeek(lang),
        ),
      );
      await expectCard(tester, 'card_month_$lang.png');
    });

    testWidgets('a Note on paper, in $lang', (tester) async {
      await pumpCard(
        tester,
        lang,
        NotePoster(
          note: fa
              ? 'استیونز بالاخره قبول می‌کنه دلش برای دوشیزه کنتون تنگ شده، '
                    'ولی فقط پیش خودش.'
              : 'Stevens finally admits he misses Miss Kenton, '
                    'but only to himself.',
          work: remains,
        ),
      );
      await expectCard(tester, 'card_note_$lang.png');
    });
  }
}
