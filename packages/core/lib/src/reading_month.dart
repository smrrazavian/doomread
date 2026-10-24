import 'package:doomread_core/src/calendar.dart';
import 'package:doomread_core/src/session.dart';

/// This month's nights, and how long the user read or watched on each: the
/// month of windows.
///
/// Like the Reading week, it never "breaks". A night without a Session is
/// just not lit, whether it's past or still to come.
class ReadingMonth {
  /// The month holding tonight, measured at [now] (the injected clock), in
  /// the Solar Hijri calendar when [solarHijri] (Persian) and the Gregorian
  /// one otherwise.
  ///
  /// Nights follow [eveningOf], so a Session past midnight lights the
  /// evening before. Any Session lights its night; only stopped ones add
  /// time, so a Session left open can't make a night glow by itself.
  factory ReadingMonth({
    required DateTime now,
    required bool solarHijri,
    required Iterable<Session> sessions,
  }) {
    final tonight = eveningOf(now);
    ({int year, int month}) monthOf(DateTime d) {
      if (!solarHijri) return (year: d.year, month: d.month);
      final s = toSolarHijri(d);
      return (year: s.year, month: s.month);
    }

    DateTime next(DateTime d, int by) => DateTime(d.year, d.month, d.day + by);

    final month = monthOf(tonight);
    var first = tonight;
    while (monthOf(next(first, -1)) == month) {
      first = next(first, -1);
    }
    final nights = [for (var d = first; monthOf(d) == month; d = next(d, 1)) d];
    final lit = <DateTime>{};
    final reading = <DateTime, Duration>{};
    for (final s in sessions) {
      final start = s.startedAt;
      if (start == null) continue;
      final night = eveningOf(start);
      lit.add(night);
      if (s.stopped) {
        reading[night] = (reading[night] ?? Duration.zero) + s.reading;
      }
    }
    return ReadingMonth._(nights, tonight, month, {
      for (final n in nights)
        if (lit.contains(n)) n: reading[n] ?? Duration.zero,
    });
  }

  ReadingMonth._(List<DateTime> nights, this.tonight, this.month, this._reading)
    : nights = List.unmodifiable(nights);

  /// The month's nights in order, as dates.
  final List<DateTime> nights;

  /// The evening it is now.
  final DateTime tonight;

  /// Which month this is, in its own calendar: Aban (8) 1405, or October
  /// (10) 2026.
  final ({int year, int month}) month;

  /// The reading on each lit night.
  final Map<DateTime, Duration> _reading;

  /// Whether [night] had at least one Session.
  bool isLit(DateTime night) => _reading.containsKey(night);

  /// How long the user read on [night]; zero when it isn't lit.
  Duration readingOn(DateTime night) => _reading[night] ?? Duration.zero;

  /// The month's longest night of reading, so a night can glow relative to
  /// the user's own month and nobody else's; zero before any.
  Duration get most =>
      _reading.values.fold(Duration.zero, (most, d) => d > most ? d : most);

  /// How many nights this month had a Session.
  int get count => _reading.length;

  /// How many days of the week come before the month's first night, for a
  /// week that starts on [firstDay] (see [firstDayOfWeek]).
  int leadingDays(int firstDay) => (nights.first.weekday - firstDay) % 7;
}
