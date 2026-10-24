import 'package:doomread_core/src/calendar.dart';

/// This week's nights, and which of them had a Session.
///
/// It restarts every week and never "breaks": a night without a Session is
/// just not lit, whether it's past or still to come.
class ReadingWeek {
  /// The week holding tonight, measured at [now] (the injected clock), where
  /// [sessionStarts] are when each Session started and [firstDay] is the
  /// weekday the week starts on (see [firstDayOfWeek]).
  ///
  /// Nights follow [eveningOf], so a Session past midnight lights the
  /// evening before, and the week turns over at 4 in the morning.
  factory ReadingWeek({
    required DateTime now,
    required int firstDay,
    required Iterable<DateTime> sessionStarts,
  }) {
    final tonight = eveningOf(now);
    final back = (tonight.weekday - firstDay) % 7;
    final nights = [
      for (var i = 0; i < 7; i++)
        DateTime(tonight.year, tonight.month, tonight.day - back + i),
    ];
    final read = litEvenings(sessionStarts);
    return ReadingWeek._(nights, tonight, {
      for (final n in nights)
        if (read.contains(n)) n,
    });
  }

  ReadingWeek._(List<DateTime> nights, this.tonight, Set<DateTime> lit)
    : nights = List.unmodifiable(nights),
      _lit = lit;

  /// The week's seven nights in order, as dates, starting on its first day.
  final List<DateTime> nights;

  /// The evening it is now.
  final DateTime tonight;

  final Set<DateTime> _lit;

  /// Whether [night] had at least one Session.
  bool isLit(DateTime night) => _lit.contains(night);

  /// The Reading week: how many nights this week had a Session.
  int get count => _lit.length;
}
