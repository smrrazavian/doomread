import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/task_done_use_case.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// A Task's Done moment: what it took, the next Task, and Undo.
class DoneViewModel extends ChangeNotifier {
  DoneViewModel(
    WorkRepository works,
    this._sessions,
    this._taskDone,
    this.taskId,
  ) {
    undo = Command0(() async {
      await _taskDone.undo(taskId);
      return const Result.ok(null);
    });
    startNext = Command0(_startNext);
    _subs = [
      works.watchTasks().listen((t) {
        _tasks = t;
        notifyListeners();
      }),
      _sessions.watchAll().listen((all) {
        _records = [
          for (final r in all)
            if (r.road.work.id == taskId) r,
        ];
        _sessionsLoaded = true;
        notifyListeners();
      }),
    ];
  }

  final SessionRepository _sessions;
  final TaskDoneUseCase _taskDone;
  final String taskId;
  late final List<StreamSubscription<Object?>> _subs;
  List<Task>? _tasks;
  List<SessionRecord> _records = const [];
  bool _sessionsLoaded = false;

  bool get loaded => _tasks != null && _sessionsLoaded;

  /// Null once it's deleted, or before it has loaded.
  Task? get task => _tasks?.where((t) => t.id == taskId).firstOrNull;

  List<Session> get _measured {
    final now = _sessions.now();
    return [for (final r in _records) r.at(now)];
  }

  /// Every Session spent on it, for its Tone line.
  List<Session> get sessions => _measured;

  /// The minutes spent on it, across its Sessions, without Pauses or
  /// Planned breaks.
  int get minutes =>
      _measured.fold(Duration.zero, (sum, s) => sum + s.reading).inMinutes;

  /// Its Longest stretch, in minutes.
  int get longest => longestStretch(_measured).inMinutes;

  /// The Urges let pass while on it.
  int get urgesLetPass => _measured.fold(0, (sum, s) => sum + s.urgesLetPass);

  /// The Task to go on with: the first undone one on Today; null when none
  /// is left.
  Task? get next => nextTask(
    tasksToday(
      (_tasks ?? const []).where((t) => t.id != taskId),
      _sessions.now(),
    ),
  );

  /// Makes the Task undone again. Its Session stays stopped.
  late final Command0<void> undo;

  /// Starts a Session on [next], or goes back to one left open on it; its
  /// result is the Session's id.
  late final Command0<String> startNext;

  Future<Result<String>> _startNext() async {
    final id = next!.id;
    final now = _sessions.now();
    for (final r in (await _sessions.all()).reversed) {
      if (r.road.work.id == id && !r.at(now).stopped) return Result.ok(r.id);
    }
    return Result.ok(await _sessions.start(id));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
