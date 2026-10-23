import 'dart:async';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class TonightViewModel extends ChangeNotifier {
  TonightViewModel(WorkRepository works) {
    _sub = works.watchCurrent().listen((r) {
      road = r;
      loaded = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<Road?> _sub;

  /// The current Work on its Road; null when there's no Work yet.
  Road? road;
  bool loaded = false;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
