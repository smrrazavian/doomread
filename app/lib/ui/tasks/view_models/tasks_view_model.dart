import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// Today's Tasks: the list, adding, changing and deleting them, and
/// starting one.
class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._works, this._sessions, this._stopDeleted) {
    start = Command1(_start);
    _subs = [
      _works.watchTasks().listen((t) {
        _all = t;
        _loaded = true;
        notifyListeners();
      }),
      _sessions.watchAll().listen((all) {
        _history = all;
        notifyListeners();
      }),
    ];
  }

  final WorkRepository _works;
  final SessionRepository _sessions;
  final StopDeletedSessionsUseCase _stopDeleted;
  late final List<StreamSubscription<Object?>> _subs;
  List<Task> _all = const [];
  List<SessionRecord> _history = const [];

  bool get loaded => _loaded;
  bool _loaded = false;

  /// The day it is, as a date; it turns over at 4 in the morning.
  DateTime get today => eveningOf(_sessions.now());

  /// The Tasks on Today: Done today, then undone, earlier days' included.
  List<Task> get tasks => tasksToday(_all, _sessions.now());

  /// The one to start next, with the filled Start.
  Task? get next => nextTask(tasks);

  /// The longest Stretch in [task]'s Sessions: the Task in one go.
  Duration inOneGo(Task task) {
    final now = _sessions.now();
    return longestStretch([
      for (final r in _history)
        if (r.road.work.id == task.id) r.at(now),
    ]);
  }

  /// Starts a Session on a Task, or goes back to one left open on it; its
  /// result is the Session's id.
  late final Command1<String, String> start;

  Future<Result<String>> _start(String taskId) async {
    final now = _sessions.now();
    for (final r in _history.reversed) {
      if (r.road.work.id == taskId && !r.at(now).stopped) {
        return Result.ok(r.id);
      }
    }
    return Result.ok(await _sessions.start(taskId));
  }

  /// What's wrong with a Task as typed: its [name], and its [estimate] in
  /// minutes, empty for none. Empty when it can be saved.
  static Set<TaskProblem> problems(String name, String estimate) => {
    if (name.trim().isEmpty) TaskProblem.noName,
    if (estimate.trim().isNotEmpty && parseNumber(estimate) == null)
      TaskProblem.estimateUnreadable,
  };

  Future<void> add(String name, {DateTime? day, Duration? estimate}) =>
      _works.addTask(name: name.trim(), day: day, estimate: estimate);

  Future<void> edit(
    Task task, {
    required String name,
    DateTime? day,
    Duration? estimate,
  }) =>
      _works.editTask(task.id, name: name.trim(), day: day, estimate: estimate);

  /// Deletes [task]; as in the Library, a Session open on it runs on until
  /// Undo is gone.
  Future<void> delete(Task task) {
    // Gone from the list at once: a swiped-away row can't wait for the
    // database to say so.
    _all = [..._all.where((t) => t.id != task.id)];
    notifyListeners();
    _settling.add(
      Timer(
        StopDeletedSessionsUseCase.undoWindow,
        () => unawaited(_stopDeleted(settled: task.id)),
      ),
    );
    return _works.delete(task.id);
  }

  final _settling = <Timer>[];

  Future<void> restore(Task task) => _works.restore(task.id);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    // ponytail: as in the Library, a pending stop is dropped with Today;
    // the next app start or sync stops it instead.
    for (final t in _settling) {
      t.cancel();
    }
    super.dispose();
  }
}

enum TaskProblem { noName, estimateUnreadable }
