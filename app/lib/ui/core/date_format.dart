import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// [date] as a day and month: "۱۷ مهر" in Persian, on the Solar Hijri
/// calendar, and "Oct 9" in English.
String formatDayMonth(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode != 'fa') {
    return MaterialLocalizations.of(context).formatShortMonthDay(date);
  }
  final d = toSolarHijri(date);
  return '${formatNumber(d.day, locale)} ${_persianMonths[d.month - 1]}';
}

const _persianMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];
