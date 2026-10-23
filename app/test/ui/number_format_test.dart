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
}
