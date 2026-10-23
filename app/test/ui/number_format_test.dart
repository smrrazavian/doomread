import 'package:doomread/ui/core/number_format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Persian shows Persian digits', () {
    expect(formatNumber(245, const Locale('fa')), '۲۴۵');
  });

  test('English shows Latin digits', () {
    expect(formatNumber(245, const Locale('en')), '245');
  });

  test('the Reading clock shows minutes and seconds, in Persian digits', () {
    const d = Duration(minutes: 5, seconds: 2);
    expect(formatClock(d, const Locale('en')), '5:02');
    expect(formatClock(d, const Locale('fa')), '۵:۰۲');
  });

  test('past an hour the clock shows hours too', () {
    const d = Duration(hours: 1, minutes: 4, seconds: 9);
    expect(formatClock(d, const Locale('en')), '1:04:09');
  });

  test('a timestamp reads as seconds, the way a player shows it', () {
    expect(parseClock('1:12:20'), 4340);
    expect(parseClock('42:30'), 2550);
    expect(parseClock(' 95 '), 95 * 60); // a bare number is minutes
    expect(parseClock('۱:۱۲:۲۰'), 4340);
    expect(parseClock('٤٢:٣٠'), 2550);
  });

  test('a timestamp that a player would never show is unreadable', () {
    for (final bad in ['', '1:75', '1:60:00', '1::2', '1:2:3:4', 'x', '-5']) {
      expect(parseClock(bad), isNull, reason: bad);
    }
  });

  test('a list of timestamps, with Latin or Persian commas', () {
    expect(parseClocks('42:30, 1:15:00'), [2550, 4500]);
    expect(parseClocks('۴۲:۳۰، ۱:۱۵:۰۰'), [2550, 4500]);
    expect(parseClocks(''), isEmpty);
    expect(parseClocks('42:30, 1:99'), isNull);
  });

  test("timestamps prefill in the user's digits", () {
    expect(formatClocks([2550, 4500], const Locale('fa')), '۴۲:۳۰، ۱:۱۵:۰۰');
  });
}
