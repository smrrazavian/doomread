import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class TonightViewModel extends ChangeNotifier {
  TonightViewModel(WorkRepository works, this._sessions) {
    start = Command0(_start);
    _subs = [
      works.watchCurrent().listen((r) {
        _road = r;
        _loaded = true;
        notifyListeners();
      }),
      _sessions.watchAll().listen((all) {
        _history = all;
        notifyListeners();
      }),
    ];
  }

  final SessionRepository _sessions;
  late final List<StreamSubscription<Object?>> _subs;
  List<SessionRecord> _history = const [];

  /// The current Work on its Road; null when there's no Work yet.
  Road? get road => _road;
  Road? _road;

  bool get loaded => _loaded;
  bool _loaded = false;

  /// Starts a Session with the current Work; its result is the Session's id.
  late final Command0<String> start;

  /// Tonight's Aim: the Longest stretch plus one minute.
  // ponytail: every Work is a book until #12 adds watching, so all Sessions
  // are one kind; filter by kind here once there are two.
  Duration get aim =>
      aimFor(longestStretch(_history.map((r) => r.at(_sessions.now()))));

  /// About how many evenings until the Finish; null until there's a pace.
  int? get evenings {
    final road = this.road;
    if (road == null) return null;
    final now = _sessions.now();
    return eveningsLeft(
      pagesLeft: road.work.totalPages - road.position,
      sittings: [
        for (final r in _history)
          if (r.road.work.id == road.work.id)
            if ((r.pages, r.at(now).startedAt) case (final p?, final at?))
              (startedAt: at, pages: p.to - p.from),
      ],
    );
  }

  /// A Session with the current Work that was never stopped, say because the
  /// app was closed during it. Tonight offers to go back to it.
  String? get openSession {
    final now = _sessions.now();
    for (final r in _history.reversed) {
      if (r.road.work.id == road?.work.id && !r.at(now).stopped) return r.id;
    }
    return null;
  }

  Future<Result<String>> _start() async =>
      Result.ok(openSession ?? await _sessions.start(road!.work.id));

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
