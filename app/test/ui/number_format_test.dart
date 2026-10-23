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
}
