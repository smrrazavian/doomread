import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// A month on the Calendar: its days, what each holds, and the summary
/// under its title.
typedef CalendarMonthView = ({
  ReadingMonth month,
  Map<DateTime, CalendarDay> days,
  int tasksDone,
  int finishes,
});

/// What the user read or watched on a day: each Work, how far it went (in
/// its own unit; null when no Session that day ended on End of the
/// evening), and the Notes written then.
typedef DayReading = ({
  List<({Work work, int? covered})> works,
  List<String> notes,
});

/// The Calendar: each day of a month, glowing with its focus time, with
/// its Tasks Done, its reading and its Finishes.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._sessions, WorkRepository works) {
    _subs = [
      _sessions.watchAll().listen((all) {
        _history = all;
        notifyListeners();
      }),
      works.watchTasks().listen((t) {
        _tasks = t;
        notifyListeners();
      }),
      _sessions.watchFinishes().listen((f) {
        _finishes = f;
        notifyListeners();
      }),
    ];
  }

  final SessionRepository _sessions;
  late final List<StreamSubscription<Object?>> _subs;
  List<SessionRecord> _history = const [];
  List<Task> _tasks = const [];
  List<Finish> _finishes = const [];

  /// The month [offset] months from tonight's (-1 for the one before), in
  /// the Solar Hijri calendar when [solarHijri].
  CalendarMonthView month(int offset, {required bool solarHijri}) {
    final now = _sessions.now();
    // The nights of reading light a month; Working stays out of it.
    final reading = [for (final r in withoutTasks(_history)) r.at(now)];
    ReadingMonth at(DateTime? showing) => ReadingMonth(
      now: now,
      solarHijri: solarHijri,
      sessions: reading,
      showing: showing,
    );
    var month = at(null);
    for (var i = 0; i < offset.abs(); i++) {
      final edge = offset < 0 ? month.nights.first : month.nights.last;
      month = at(DateTime(edge.year, edge.month, edge.day + offset.sign));
    }
    final days = calendarDays(
      month.nights,
      now: now,
      sessions: [for (final r in _history) r.at(now)],
      tasks: _tasks,
      finishes: [for (final f in _finishes) ?f.at],
    );
    return (
      month: month,
      days: days,
      tasksDone: days.values.fold(0, (n, d) => n + d.tasksDone),
      finishes: days.values.fold(0, (n, d) => n + d.finishes),
    );
  }

  /// What was read or watched on [day], in the order it was.
  DayReading readingOn(DateTime day) {
    final now = _sessions.now();
    final covered = <String, ({Work work, int? covered})>{};
    final notes = <String>[];
    for (final r in withoutTasks(_history)) {
      final start = r.at(now).startedAt;
      if (start == null || eveningOf(start) != day) continue;
      final work = r.road.work;
      final went = r.pages == null ? null : r.pages!.to - r.pages!.from;
      final before = covered[work.id]?.covered;
      covered[work.id] = (
        work: work,
        covered: went == null ? before : (before ?? 0) + went,
      );
      if (r.note.isNotEmpty) notes.add(r.note);
    }
    return (works: covered.values.toList(), notes: notes);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
