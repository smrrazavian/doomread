import 'package:doomread_core/src/calendar.dart';
import 'package:doomread_core/src/session.dart';
import 'package:doomread_core/src/task.dart';

/// What one day holds on the Calendar: its focus time across every kind of
/// attention, the Tasks Done on it, the Tasks planned for it while it's
/// still to come, and the Finishes on it.
typedef CalendarDay = ({
  Duration focus,
  int tasksDone,
  int planned,
  int finishes,
});

/// Each of [days] and what it holds, at [now] (the injected clock).
///
/// Days follow [eveningOf], so a Task Done at 1 a.m. belongs to the day
/// before. As for the Reading month, only stopped Sessions add focus time.
/// Planned Tasks count only on days after today: an undone one from an
/// earlier day carries over to Today, unmarked. A day with nothing holds
/// nothing; there's no mark for a dark day.
///
/// [finishes] are when each Finish happened.
Map<DateTime, CalendarDay> calendarDays(
  Iterable<DateTime> days, {
  required DateTime now,
  required Iterable<Session> sessions,
  required Iterable<Task> tasks,
  required Iterable<DateTime> finishes,
}) {
  final today = eveningOf(now);
  final focus = <DateTime, Duration>{};
  for (final s in sessions) {
    if (!s.stopped || s.startedAt == null) continue;
    final day = eveningOf(s.startedAt!);
    focus[day] = (focus[day] ?? Duration.zero) + s.reading;
  }
  final done = <DateTime, int>{};
  final planned = <DateTime, int>{};
  for (final t in tasks) {
    if (t.doneAt case final at?) {
      final day = eveningOf(at);
      done[day] = (done[day] ?? 0) + 1;
    } else if (t.day case final d?) {
      final day = DateTime(d.year, d.month, d.day);
      if (day.isAfter(today)) planned[day] = (planned[day] ?? 0) + 1;
    }
  }
  final finished = <DateTime, int>{};
  for (final f in finishes) {
    final day = eveningOf(f);
    finished[day] = (finished[day] ?? 0) + 1;
  }
  return {
    for (final d in days)
      d: (
        focus: focus[d] ?? Duration.zero,
        tasksDone: done[d] ?? 0,
        planned: planned[d] ?? 0,
        finishes: finished[d] ?? 0,
      ),
  };
}
