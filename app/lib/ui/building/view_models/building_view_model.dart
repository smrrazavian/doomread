import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// The user's Building: one floor per Finish, and how the Longest stretch
/// has risen.
class BuildingViewModel extends ChangeNotifier {
  BuildingViewModel(SessionRepository sessions) : _now = sessions.now {
    _subs = [
      sessions.watchFinishes().listen((f) {
        _floors = f;
        _loaded = true;
        notifyListeners();
      }),
      sessions.watchAll().listen((all) {
        final measuredAll = measured(all, sessions.now());
        _sessions = [for (final s in measuredAll) s.session];
        List<StretchRise> trend({required bool watched}) =>
            longestStretchTrend(alike(measuredAll, watched: watched));
        _rises = trend(watched: false);
        _watchingRises = trend(watched: true);
        notifyListeners();
      }),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;
  final DateTime Function() _now;
  List<Session> _sessions = const [];

  /// Every Finish, the most recent first: the top floor.
  List<Finish> get floors => _floors;
  List<Finish> _floors = const [];

  bool get loaded => _loaded;
  bool _loaded = false;

  /// Each evening the Longest stretch for reading grew, oldest first.
  List<StretchRise> get rises => _rises;
  List<StretchRise> _rises = const [];

  /// The same for watching, kept apart; empty until something is watched.
  List<StretchRise> get watchingRises => _watchingRises;
  List<StretchRise> _watchingRises = const [];

  /// This month's nights, read or watched: Solar Hijri when [solarHijri].
  ReadingMonth month({required bool solarHijri}) =>
      ReadingMonth(now: _now(), solarHijri: solarHijri, sessions: _sessions);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
