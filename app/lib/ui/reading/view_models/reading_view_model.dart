import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// One Session under way: its timer, Pause and Resume, and Stop.
class ReadingViewModel extends ChangeNotifier {
  ReadingViewModel(this._sessions, this.id) {
    pause = Command0(() => _add(SessionEventKind.pause));
    resume = Command0(() => _add(SessionEventKind.resume));
    stop = Command0(() => _add(SessionEventKind.stop));
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

  Session? get session => record?.at(_sessions.now());

  /// The Aim for tonight, from the Sessions before this one.
  Duration get aim =>
      aimFor(longestStretch(_before.map((r) => r.at(_sessions.now()))));

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

  @override
  void dispose() {
    _tick.cancel();
    unawaited(_sub.cancel());
    super.dispose();
  }
}
