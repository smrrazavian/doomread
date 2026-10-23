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
        _rises = longestStretchTrend([for (final r in all) r.at(now)]);
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

  /// Each evening the Longest stretch grew, oldest first.
  List<StretchRise> get rises => _rises;
  List<StretchRise> _rises = const [];

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
