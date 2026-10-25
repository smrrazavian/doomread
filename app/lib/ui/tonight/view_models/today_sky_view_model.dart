import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

/// The sky over Today: the time it shows and the Tasks still to do. The
/// time is read when Today opens, when the Tasks change and when the app
/// comes back; it never ticks.
class TodaySkyViewModel extends ChangeNotifier {
  TodaySkyViewModel(WorkRepository works, this._sessions)
    : _now = _sessions.now() {
    _lifecycle = AppLifecycleListener(onResume: _look);
    _sub = works.watchTasks().listen((t) {
      _tasks = t;
      _loaded = true;
      _look();
    });
  }

  final SessionRepository _sessions;
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<List<Task>> _sub;
  List<Task> _tasks = const [];

  /// Whether the Tasks have come in yet.
  bool get loaded => _loaded;
  bool _loaded = false;

  /// The time the sky shows.
  DateTime get now => _now;
  DateTime _now;

  /// The Tasks on Today not yet Done.
  int get undone => tasksToday(_tasks, _now).where((t) => !t.done).length;

  void _look() {
    _now = _sessions.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_sub.cancel());
    super.dispose();
  }
}
