/// The evening a time belongs to, as a date. Reading past midnight still
/// counts toward the evening before, so the day turns over at 4 in the
/// morning.
DateTime eveningOf(DateTime t) {
  final shifted = t.subtract(const Duration(hours: 4));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// The day a week starts on for [languageCode], as a [DateTime] weekday:
/// Saturday in Persian, as in Iran, and Monday otherwise.
int firstDayOfWeek(String languageCode) =>
    languageCode == 'fa' ? DateTime.saturday : DateTime.monday;

/// [date]'s day in the Solar Hijri calendar: 23 October 2026 is
/// 1 Aban (month 8) 1405.
///
/// Only the calendar date of [date] is used, not its time.
({int year, int month, int day}) toSolarHijri(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  var year = date.year - 621;
  var k = d.difference(_nowruz(year)).inDays;
  if (k < 0) {
    year -= 1;
    k = d.difference(_nowruz(year)).inDays;
  }
  // Farvardin to Shahrivar have 31 days, Mehr to Bahman 30, Esfand the rest.
  return k < 186
      ? (year: year, month: 1 + k ~/ 31, day: k % 31 + 1)
      : (year: year, month: 7 + (k - 186) ~/ 30, day: (k - 186) % 30 + 1);
}

/// Years where the 33-year leap cycle of the Solar Hijri calendar shifts,
/// so the arithmetic matches the astronomical calendar Iran uses. From
/// Borkowski's algorithm, as in jalaali-js.
const _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, //
  1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

/// 1 Farvardin of Solar Hijri [year], in the Gregorian calendar.
DateTime _nowruz(int year) {
  if (year < _breaks.first || year >= _breaks.last) {
    throw RangeError.range(year, _breaks.first, _breaks.last - 1, 'year');
  }
  var leaps = -14;
  var from = _breaks.first;
  var jump = 0;
  for (final to in _breaks.skip(1)) {
    jump = to - from;
    if (year < to) break;
    leaps += jump ~/ 33 * 8 + jump % 33 ~/ 4;
    from = to;
  }
  final n = year - from;
  leaps += n ~/ 33 * 8 + (n % 33 + 3) ~/ 4;
  if (jump % 33 == 4 && jump - n == 4) leaps += 1;
  final gy = year + 621;
  final gregorianLeaps = gy ~/ 4 - (gy ~/ 100 + 1) * 3 ~/ 4 - 150;
  return DateTime.utc(gy, 3, 20 + leaps - gregorianLeaps);
}
