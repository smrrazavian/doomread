import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// [n] in the digits of [locale]: ۲۴۵ in Persian, 245 in English.
String formatNumber(num n, Locale locale) =>
    NumberFormat.decimalPattern(locale.languageCode).format(n);
