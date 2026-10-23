import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// The user's Building: one floor per Finish.
class BuildingViewModel extends ChangeNotifier {
  BuildingViewModel(SessionRepository sessions) {
    _sub = sessions.watchFinishes().listen((f) {
      _floors = f;
      _loaded = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<Finish>> _sub;

  /// Every Finish, the most recent first: the top floor.
  List<Finish> get floors => _floors;
  List<Finish> _floors = const [];

  bool get loaded => _loaded;
  bool _loaded = false;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
