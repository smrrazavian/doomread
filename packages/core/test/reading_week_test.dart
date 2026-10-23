import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // 19 October 2026 is a Monday; 17 October a Saturday.
  ReadingWeek week(
    DateTime now, {
    String lang = 'en',
    List<DateTime> starts = const [],
  }) => ReadingWeek(
    now: now,
    firstDay: firstDayOfWeek(lang),
    sessionStarts: starts,
  );
  List<int> days(ReadingWeek w) => [for (final n in w.nights) n.day];
  List<int> lit(ReadingWeek w) => [
    for (final n in w.nights)
      if (w.isLit(n)) n.day,
  ];

  test('in English the week runs Monday to Sunday', () {
    final w = week(DateTime(2026, 10, 22, 21));
    expect(days(w), [19, 20, 21, 22, 23, 24, 25]);
    expect(w.nights.first.weekday, DateTime.monday);
    expect(w.tonight, DateTime(2026, 10, 22));
  });

  test('in Persian the week runs Saturday to Friday', () {
    final w = week(DateTime(2026, 10, 22, 21), lang: 'fa');
    expect(days(w), [17, 18, 19, 20, 21, 22, 23]);
    expect(w.nights.first.weekday, DateTime.saturday);
    expect(w.nights.last.weekday, DateTime.friday);
  });

  test('nights with a Session are lit and counted, once each', () {
    final w = week(
      DateTime(2026, 10, 22, 21),
      starts: [
        DateTime(2026, 10, 20, 21),
        DateTime(2026, 10, 20, 23),
        DateTime(2026, 10, 22, 20),
      ],
    );
    expect(lit(w), [20, 22]);
    expect(w.count, 2);
  });

  test('a Session past midnight lights the evening before', () {
    final w = week(
      DateTime(2026, 10, 22, 21),
      starts: [DateTime(2026, 10, 21, 1, 30)],
    );
    expect(lit(w), [20]);
  });

  test('Sessions from other weeks are not counted', () {
    final w = week(
      DateTime(2026, 10, 22, 21),
      starts: [DateTime(2026, 10, 18, 21), DateTime(2026, 10, 26, 21)],
    );
    expect(w.count, 0);
  });

  test('a new week starts with nothing lit', () {
    final w = week(
      DateTime(2026, 10, 26, 21),
      starts: [for (var d = 19; d <= 25; d++) DateTime(2026, 10, d, 21)],
    );
    expect(days(w), [26, 27, 28, 29, 30, 31, 1]);
    expect(w.count, 0);
  });

  group('around the 4 a.m. turnover', () {
    test('Monday 03:59 is still Sunday night of last week', () {
      final w = week(DateTime(2026, 10, 26, 3, 59));
      expect(w.tonight, DateTime(2026, 10, 25));
      expect(days(w), [19, 20, 21, 22, 23, 24, 25]);
    });

    test('Monday 04:00 starts the new week', () {
      final w = week(DateTime(2026, 10, 26, 4));
      expect(w.tonight, DateTime(2026, 10, 26));
      expect(days(w).first, 26);
    });

    test('a Session at Monday 01:00 lights Sunday of last week', () {
      final starts = [DateTime(2026, 10, 26, 1)];
      expect(lit(week(DateTime(2026, 10, 26, 2), starts: starts)), [25]);
      expect(week(DateTime(2026, 10, 26, 21), starts: starts).count, 0);
    });

    test('in Persian, Saturday 03:59 is still Friday, the last night', () {
      final w = week(DateTime(2026, 10, 24, 3, 59), lang: 'fa');
      expect(w.tonight, DateTime(2026, 10, 23));
      expect(w.nights.last, w.tonight);
      expect(days(w), [17, 18, 19, 20, 21, 22, 23]);
    });

    test('in Persian, Saturday 04:00 starts the new week', () {
      final w = week(DateTime(2026, 10, 24, 4), lang: 'fa');
      expect(w.nights.first, w.tonight);
      expect(days(w), [24, 25, 26, 27, 28, 29, 30]);
    });
  });

  test('a week across the new year keeps its dates in order', () {
    final w = week(DateTime(2026, 12, 31, 21));
    expect(w.nights, [for (var d = 28; d <= 34; d++) DateTime(2026, 12, d)]);
  });
}
