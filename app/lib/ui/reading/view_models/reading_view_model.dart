import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/ui/core/yalda.dart';
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

  /// The House has flickered the Window back on: a later House, after
  /// a Slip say, lights up as usual. Nothing on screen changes now.
  void backOnShown() => _letPassed = false;

  /// Whether the tour's demo Urge is showing: the real "not yet" screen,
  /// held here only, so nothing about it reaches the journal.
  bool get demo => _demo;
  bool _demo = false;

  void showDemo() {
    _demo = true;
    notifyListeners();
  }

  void endDemo() {
    _demo = false;
    notifyListeners();
  }

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

  /// Whether tonight is Shab-e Yalda, when the House has pomegranates.
  bool get yalda => yaldaAt(_sessions.now());

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
