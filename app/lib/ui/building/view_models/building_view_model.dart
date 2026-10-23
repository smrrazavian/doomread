import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// The user's Building: one floor per Finish, and how the Longest stretch
/// has risen.
class BuildingViewModel extends ChangeNotifier {
  BuildingViewModel(SessionRepository sessions) {
    _subs = [
      sessions.watchFinishes().listen((f) {
        _floors = f;
        _loaded = true;
        notifyListeners();
      }),
      sessions.watchAll().listen((all) {
        final now = sessions.now();
        List<StretchRise> trend(WorkKind kind) =>
            longestStretchTrend([for (final r in alike(all, kind)) r.at(now)]);
        _rises = trend(WorkKind.paperBook);
        _watchingRises = trend(WorkKind.series);
        notifyListeners();
      }),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;

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

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
