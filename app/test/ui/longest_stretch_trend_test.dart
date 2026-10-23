import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/widgets/longest_stretch_trend.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Five rises through October, from 5 to 18 minutes.
final rises = <StretchRise>[
  for (final (day, minutes, seconds) in [
    (9, 5, 0),
    (12, 7, 20),
    (15, 9, 0),
    (20, 12, 30),
    (22, 18, 10),
  ])
    (
      evening: DateTime(2026, 10, day),
      longest: Duration(minutes: minutes, seconds: seconds),
    ),
];

/// [trend] alone on a Scaffold, in [lang].
Future<void> pumpTrend(
  WidgetTester tester,
  String lang,
  LongestStretchTrend trend,
) async {
  final locale = Locale(lang);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildTheme(locale),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: trend),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final lang in ['en', 'fa']) {
    final l10n = lookupAppLocalizations(Locale(lang));

    testWidgets('the trend in $lang', (tester) async {
      tester.view
        ..physicalSize = const Size(720, 560)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpTrend(tester, lang, LongestStretchTrend(rises: rises));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/longest_stretch_trend_$lang.png'),
      );
    });

    testWidgets('screen readers hear how it grew, and when, in $lang', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTrend(tester, lang, LongestStretchTrend(rises: rises));
      final context = tester.element(find.byType(LongestStretchTrend));
      final first = formatDayMonth(context, rises.first.evening);
      final last = formatDayMonth(context, rises.last.evening);
      // The dates are shown at the two ends of the line, too.
      expect(find.text(first), findsOne);
      expect(find.text(last), findsOne);
      expect(
        find.bySemanticsLabel(
          '${l10n.stretchTrendGrew(5, 18)} '
          '${l10n.stretchTrendDates(first, last)}',
        ),
        findsOne,
      );
      semantics.dispose();
    });

    testWidgets('one evening says what it is so far, in $lang', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpTrend(
        tester,
        lang,
        LongestStretchTrend(rises: rises.sublist(0, 1)),
      );
      expect(find.bySemanticsLabel(l10n.stretchTrendSoFar(5)), findsOne);
      semantics.dispose();
    });

    testWidgets('before any Session it says what will show up, in $lang', (
      tester,
    ) async {
      await pumpTrend(tester, lang, const LongestStretchTrend(rises: []));
      expect(find.text(l10n.stretchTrendEmpty), findsOne);
    });
  }

  testWidgets('Persian dates are on the Solar Hijri calendar', (tester) async {
    await pumpTrend(tester, 'fa', LongestStretchTrend(rises: rises));
    // 9 October is 17 Mehr, 22 October is 30 Mehr.
    expect(find.textContaining('۱۷ '), findsOne);
    expect(find.textContaining('۳۰ '), findsOne);
  });
}
