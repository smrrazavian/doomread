import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// [n] in the digits of [locale]: ۲۴۵ in Persian, 245 in English.
String formatNumber(num n, Locale locale) =>
    NumberFormat.decimalPattern(locale.languageCode).format(n);

/// Reads a whole number typed with Latin, Persian (۰–۹) or Arabic-Indic
/// (٠–٩) digits, since a Persian keyboard types the latter two.
int? parseNumber(String text) {
  final latin = text.trim().replaceAllMapped(RegExp('[۰-۹٠-٩]'), (m) {
    final c = m[0]!.codeUnitAt(0);
    return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
  });
  // Digits only: int.tryParse would also take "+5" or "0x1F".
  return RegExp(r'^\d+$').hasMatch(latin) ? int.parse(latin) : null;
}

/// A list of numbers separated by Latin or Persian commas (،) or spaces.
List<int>? parseNumbers(String text) {
  final parts = text.split(RegExp(r'[,،\s]+')).where((p) => p.isNotEmpty);
  final numbers = parts.map(parseNumber).toList();
  return numbers.contains(null) ? null : numbers.cast<int>();
}

/// [numbers] in the digits and list separator of [locale], for prefilling a
/// field the user may edit: "۳۴، ۶۶" in Persian, "34, 66" in English.
String formatNumbers(List<int> numbers, Locale locale) => numbers
    .map((n) => formatNumber(n, locale))
    .join(locale.languageCode == 'fa' ? '، ' : ', ');

/// A timer reading in the digits of [locale]: 5:12, or 1:05:12 past an hour
/// (۵:۱۲ in Persian).
String formatClock(Duration d, Locale locale) {
  final two = NumberFormat('00', locale.languageCode);
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = two.format(d.inSeconds % 60);
  return h > 0
      ? '${formatNumber(h, locale)}:${two.format(m)}:$s'
      : '${formatNumber(m, locale)}:$s';
}

/// Whole minutes in [d], rounded up: 1:48 left to the Aim is "2 minutes".
int minutesUp(Duration d) => (d.inSeconds + 59) ~/ 60;
