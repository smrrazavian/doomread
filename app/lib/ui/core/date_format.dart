import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

/// Whether [context] is in Persian, which gets its own layout and
/// calendar.
bool isPersian(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'fa';

/// The user's calendar, from the locale: Solar Hijri with weeks from
/// Saturday in Persian, Gregorian with weeks from Monday otherwise.
({bool solarHijri, int firstDay}) calendarOf(BuildContext context) => (
  solarHijri: isPersian(context),
  firstDay: firstDayOfWeek(Localizations.localeOf(context).languageCode),
);

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

/// [date] with its weekday: "شنبه ۲ آبان" in Persian, on the Solar Hijri
/// calendar, and "Saturday, October 24" in English.
String formatWeekdayDayMonth(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode != 'fa') {
    return DateFormat.MMMMEEEEd(locale.languageCode).format(date);
  }
  final weekday = DateFormat.EEEE('fa').format(date);
  return '$weekday ${formatDayMonth(context, date)}';
}

/// A month and its year, in the calendar of the locale: "آبان ۱۴۰۵" in
/// Persian, where [month] is Solar Hijri, and "October 2026" in English.
String formatMonthYear(BuildContext context, ({int year, int month}) month) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode != 'fa') {
    return DateFormat.yMMMM(locale.languageCode)
        .format(DateTime(month.year, month.month));
  }
  return '${_persianMonths[month.month - 1]} '
      '${NumberFormat('0', 'fa').format(month.year)}';
}

const _persianMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

/// [time] as a 24-hour clock time, in the digits of [locale]: 21:42, or
/// ۲۱:۴۲ in Persian.
String formatTime(DateTime time, Locale locale) =>
    DateFormat.Hm(locale.languageCode).format(time);
