import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// The Planned break of [record] at [now], from the journal alone, with
/// every other Session in [all] before it (see [plannedBreakOf]).
PlannedBreak? plannedBreakOfRecord(
  SessionRecord record,
  List<SessionRecord> all,
  DateTime now,
) => plannedBreakOf(
  record.measured(now),
  before: measured(all.where((r) => r.id != record.id), now),
);

/// One Session's Planned breaks: the one on offer, taking it, nudging it
/// later, and coming back.
class PlannedBreakViewModel extends ChangeNotifier {
  PlannedBreakViewModel(this._sessions, this.id) {
    take = Command0(() => _add(SessionEventKind.breakStart));
    nudge = Command0(() => _add(SessionEventKind.nudge));
    back = Command0(() => _add(SessionEventKind.breakEnd));
    markDone = Command1((page) async {
      await _sessions.markCheckpoint(record!, page: page);
      return const Result.ok(null);
    });
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

  /// The user reached the next Checkpoint: the break is due there, and the
  /// Position moves to it. When it's an estimate, the page given is where
  /// the chapter really ended (see [SessionRepository.markCheckpoint]).
  late final Command1<void, int?> markDone;

  DateTime get now => _sessions.now();

  /// Null until the journal has loaded.
  SessionRecord? get record => _all.where((r) => r.id == id).firstOrNull;

  Session? get session => record?.at(now);

  /// The break on offer, or the one the user is on. Null when the Finish
  /// comes first, or before the journal has loaded.
  PlannedBreak? get offer {
    final r = record;
    return r == null ? null : plannedBreakOfRecord(r, _all, now);
  }

  /// The Checkpoint the user can mark done next, while reading or paused:
  /// the next one on the Road, short of the end, which is the Finish. Null
  /// while the break on offer is already at a marked one, and for a
  /// timestamp, which the player shows.
  int? get markable {
    final r = record;
    final s = session;
    if (r == null || s == null || s.stopped || s.onBreak) return null;
    if (offer?.reached ?? false) return null;
    if (r.road.work.kind.unit == WorkUnit.second) return null;
    final next = r.road.next;
    return next != null && next < r.road.work.totalPages ? next : null;
  }

  /// Whether [markable] is only an estimate, so marking it asks the page
  /// the chapter really ended on.
  bool get markableEstimated {
    final m = markable;
    return m != null && record!.road.work.isEstimate(m);
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
