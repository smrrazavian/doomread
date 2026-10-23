import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// The Planned break of [record] at [now], from the journal alone: the
/// Sessions in [all] before it give the Longest stretch, and those in the
/// same Work give the pace. Null when the Finish comes first.
PlannedBreak? plannedBreakOf(
  SessionRecord record,
  List<SessionRecord> all,
  DateTime now,
) {
  final before = [
    for (final r in all)
      if (r.id != record.id) r,
  ];
  final work = record.road.work;
  return plannedBreak(
    record.at(now),
    longestStretch: longestStretch(before.map((r) => r.at(now))),
    startPage: record.pages?.from ?? record.road.position,
    totalPages: work.totalPages,
    checkpoints: work.checkpoints,
    perPage: timePerPage([
      for (final r in before)
        if (r.pages case final p? when r.road.work.id == work.id)
          (
            reading: r
                .at(now)
                .stretches
                .fold(Duration.zero, (sum, s) => sum + s.length),
            pages: p.to - p.from,
          ),
    ]),
  );
}

/// The chapter a Checkpoint ends, counting from 1.
int chapterEndingAt(Work work, int checkpoint) =>
    work.checkpoints.indexOf(checkpoint) + 1;

/// One Session's Planned breaks: the one on offer, taking it, nudging it
/// later, and coming back.
class PlannedBreakViewModel extends ChangeNotifier {
  PlannedBreakViewModel(this._sessions, this.id) {
    take = Command0(() => _add(SessionEventKind.breakStart));
    nudge = Command0(() => _add(SessionEventKind.nudge));
    back = Command0(() => _add(SessionEventKind.breakEnd));
    _sub = _sessions.watchAll().listen((all) {
      _all = all;
      notifyListeners();
    });
    // Like Reading: everything is worked out from the journal and the clock,
    // so the tick only redraws.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = session;
      if (s != null && (s.current != null || s.onBreak)) notifyListeners();
    });
  }

  final SessionRepository _sessions;
  final String id;
  late final StreamSubscription<List<SessionRecord>> _sub;
  late final Timer _tick;
  List<SessionRecord> _all = const [];

  late final Command0<void> take;
  late final Command0<void> nudge;
  late final Command0<void> back;

  DateTime get now => _sessions.now();

  /// Null until the journal has loaded.
  SessionRecord? get record => _all.where((r) => r.id == id).firstOrNull;

  Session? get session => record?.at(now);

  /// The break on offer, or the one the user is on. Null when the Finish
  /// comes first, or before the journal has loaded.
  PlannedBreak? get offer {
    final r = record;
    return r == null ? null : plannedBreakOf(r, _all, now);
  }

  /// Whether the offer can be taken: its reading has been done.
  bool get due {
    final o = offer;
    final s = session;
    return o != null && s != null && s.readingSinceBreak >= o.from;
  }

  /// About how much more reading until the break: zero once it's due where
  /// expected.
  Duration get toGo {
    final o = offer;
    final s = session;
    if (o == null || s == null) return Duration.zero;
    final d = o.at - s.readingSinceBreak;
    return d.isNegative ? Duration.zero : d;
  }

  /// When the break the user is on ends, or would end if taken now.
  DateTime get endsAt {
    final s = session;
    final start = s != null && s.onBreak ? s.breaks.last.start : now;
    return start.add(offer?.length ?? Duration.zero);
  }

  /// Time left on the break the user is on; zero once it's over.
  Duration get left {
    final d = endsAt.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  Future<Result<void>> _add(SessionEventKind kind) async {
    await _sessions.add(record!, kind);
    return const Result.ok(null);
  }

  @override
  void dispose() {
    _tick.cancel();
    unawaited(_sub.cancel());
    super.dispose();
  }
}
