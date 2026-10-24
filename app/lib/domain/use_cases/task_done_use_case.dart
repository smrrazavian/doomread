import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';

/// A Task is Done: its Session ends and the Task is marked Done, from the
/// Session screen or the Session notification alike.
class TaskDoneUseCase {
  TaskDoneUseCase(this._works, this._sessions);

  final WorkRepository _works;
  final SessionRepository _sessions;

  /// Ends the Session [sessionId] if it's still on, and marks its Task Done.
  /// Returns the Task's id, or null when the Session isn't on a Task.
  Future<String?> call(String sessionId) async {
    final record = (await _sessions.all())
        .where((r) => r.id == sessionId)
        .firstOrNull;
    if (record == null || record.road.work.kind != WorkKind.task) return null;
    if (!record.at(_sessions.now()).stopped) {
      await _sessions.add(record, SessionEventKind.stop);
    }
    await _works.setDone(record.road.work.id);
    return record.road.work.id;
  }

  /// Undoes [call]: the Task is undone again. Its Session stays stopped.
  Future<void> undo(String taskId) => _works.setDone(taskId, done: false);
}
