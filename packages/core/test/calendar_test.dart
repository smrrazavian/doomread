import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  group('eveningOf', () {
    test('an evening belongs to its own date', () {
      expect(eveningOf(DateTime(2026, 10, 22, 21)), DateTime(2026, 10, 22));
    });

    test('past midnight still belongs to the evening before', () {
      expect(eveningOf(DateTime(2026, 10, 23, 1)), DateTime(2026, 10, 22));
      expect(
        eveningOf(DateTime(2026, 10, 23, 3, 59, 59)),
        DateTime(2026, 10, 22),
      );
    });

    test('the day turns over at 4 in the morning', () {
      expect(eveningOf(DateTime(2026, 10, 23, 4)), DateTime(2026, 10, 23));
    });

    test('past midnight on New Year belongs to the old year', () {
      expect(eveningOf(DateTime(2027, 1, 1, 2)), DateTime(2026, 12, 31));
    });
  });

  test('the week starts on Saturday in Persian and Monday in English', () {
    expect(firstDayOfWeek('fa'), DateTime.saturday);
    expect(firstDayOfWeek('en'), DateTime.monday);
  });

  group('toSolarHijri', () {
    ({int year, int month, int day}) sh(int y, int m, int d) =>
        (year: y, month: m, day: d);

    test('Nowruz falls on the right Gregorian day', () {
      expect(toSolarHijri(DateTime(2017, 3, 21)), sh(1396, 1, 1));
      expect(toSolarHijri(DateTime(2020, 3, 20)), sh(1399, 1, 1));
      expect(toSolarHijri(DateTime(2024, 3, 20)), sh(1403, 1, 1));
      expect(toSolarHijri(DateTime(2025, 3, 21)), sh(1404, 1, 1));
      expect(toSolarHijri(DateTime(2026, 3, 21)), sh(1405, 1, 1));
    });

    test('Esfand has 30 days in a leap year and 29 otherwise', () {
      expect(toSolarHijri(DateTime(2025, 3, 20)), sh(1403, 12, 30));
      expect(toSolarHijri(DateTime(2026, 3, 20)), sh(1404, 12, 29));
    });

    test('Shahrivar ends on its 31st and Mehr starts the next day', () {
      expect(toSolarHijri(DateTime(2026, 9, 22)), sh(1405, 6, 31));
      expect(toSolarHijri(DateTime(2026, 9, 23)), sh(1405, 7, 1));
    });

    test('a date in autumn, with the time of day ignored', () {
      expect(toSolarHijri(DateTime(2026, 10, 9, 23, 59)), sh(1405, 7, 17));
      expect(toSolarHijri(DateTime(2026, 10, 23)), sh(1405, 8, 1));
    });

    test('every day from 1950 to 2100 follows the day before it', () {
      var day = DateTime.utc(1950);
      var prev = toSolarHijri(day);
      while (day.year < 2100) {
        day = day.add(const Duration(days: 1));
        final next = toSolarHijri(day);
        final length = switch (prev.month) {
          <= 6 => 31,
          <= 11 => 30,
          _ => next.year == prev.year ? 30 : prev.day,
        };
        final expected = prev.day < length
            ? sh(prev.year, prev.month, prev.day + 1)
            : prev.month < 12
            ? sh(prev.year, prev.month + 1, 1)
            : sh(prev.year + 1, 1, 1);
        expect(next, expected, reason: '$day');
        if (prev.month == 12 && next.month == 1) {
          expect(prev.day, anyOf(29, 30), reason: 'Esfand before $day');
        }
        prev = next;
      }
    });

    test('years have 365 or 366 days, with a leap year every 4 or 5', () {
      var lastLeap = 1328;
      for (var y = 1330; y < 1478; y++) {
        // The day before Nowruz of the next year is 30 Esfand in a leap year.
        final nowruz = _gregorianNowruz(y + 1);
        final esfand = toSolarHijri(nowruz.subtract(const Duration(days: 1)));
        if (esfand.day == 30) {
          expect(y - lastLeap, anyOf(4, 5), reason: '$y');
          lastLeap = y;
        }
      }
    });
  });

  test(
    'lit evenings: one per night, past midnight counting the night before',
    () {
      expect(
        litEvenings([
          DateTime(2026, 10, 3, 21),
          DateTime(2026, 10, 3, 23),
          DateTime(2026, 10, 4, 1),
          DateTime(2026, 10, 4, 21),
        ]),
        {DateTime(2026, 10, 3), DateTime(2026, 10, 4)},
      );
    },
  );
}

/// Finds 1 Farvardin of [year] by searching around 21 March.
DateTime _gregorianNowruz(int year) {
  for (var d = 19; d <= 22; d++) {
    final date = DateTime.utc(year + 621, 3, d);
    final sh = toSolarHijri(date);
    if (sh.month == 1 && sh.day == 1) return date;
  }
  throw StateError('no Nowruz for $year');
}
