import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// One Session under way: its timer, Pause and Resume, Stop, and the way
/// out of an Urge.
class ReadingViewModel extends ChangeNotifier {
  ReadingViewModel(this._sessions, this.id) {
    pause = Command0(() => _add(SessionEventKind.pause));
    resume = Command0(() => _add(SessionEventKind.resume));
    stop = Command0(() => _add(SessionEventKind.stop));
    letPass = Command0(() {
      _letPassed = true;
      return _add(SessionEventKind.letPass);
    });
    finish = Command0(_finish);
    _sub = _sessions.watchAll().listen((all) {
      _record = all.where((r) => r.id == id).firstOrNull;
      _before = all.where((r) => r.id != id).toList();
      notifyListeners();
    });
    // The time shown is always worked out from the journal and the clock, so
    // the tick only redraws; a missed tick loses nothing.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (session?.current != null) notifyListeners();
    });
  }

  final SessionRepository _sessions;
  final String id;
  late final StreamSubscription<List<SessionRecord>> _sub;
  late final Timer _tick;
  List<SessionRecord> _before = const [];

  /// Null until the journal has loaded.
  SessionRecord? get record => _record;
  SessionRecord? _record;

  late final Command0<void> pause;
  late final Command0<void> resume;
  late final Command0<void> stop;

  /// Back to the Work from an Urge. Open anyway is UrgeWatch's, since it
  /// opens the Watched app too.
  late final Command0<void> letPass;

  /// Whether the user let an Urge pass on this screen, so the House can
  /// flicker their Window back on rather than light up all over again.
  bool get letPassed => _letPassed;
  bool _letPassed = false;

  /// "I finished it!": stops the Session and ends it with the Position at
  /// the Work's end, as End of the evening's Finish does. Offered once the
  /// Road is [Road.nearEnd].
  late final Command0<void> finish;

  Session? get session => record?.at(_sessions.now());

  /// The Aim for tonight, from the Sessions before this one on Works read,
  /// or watched, like this one.
  Duration get aim => aimAfter(
    measured(_before, _sessions.now()),
    watched: record?.road.work.kind.watched ?? false,
  );

  /// The House's lit Windows: this Session's, then the user's earlier ones.
  List<HouseWindow> get house {
    final now = _sessions.now();
    return houseWindows(
      now: now,
      before: [for (final r in _before) ?r.at(now).startedAt],
    );
  }

  /// The clock: the Stretch running now, or while paused, the last one.
  Duration get shown => session?.stretches.lastOrNull?.length ?? Duration.zero;

  Future<Result<void>> _add(SessionEventKind kind) async {
    await _sessions.add(record!, kind);
    return const Result.ok(null);
  }

  Future<Result<void>> _finish() async {
    final record = this.record!;
    if (!record.at(_sessions.now()).stopped) {
      await _sessions.add(record, SessionEventKind.stop);
    }
    await _sessions.end(record, page: record.road.work.totalPages);
    return const Result.ok(null);
  }

  @override
  void dispose() {
    _tick.cancel();
    unawaited(_sub.cancel());
    super.dispose();
  }
}
