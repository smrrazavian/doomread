import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';

/// Stops the Sessions left open on deleted Works, so nothing runs, raises
/// Urges or grows a Stretch for a Work that's gone.
///
/// A stopped Session can never run again, so a Session is only stopped
/// once its Work's delete can't be undone any more: `settled` names a Work
/// whose Undo just went away, and any other Work deleted at least
/// `undoWindow` ago counts as settled too, whichever device deleted it.
/// A Work restored meanwhile isn't deleted, so nothing on it is stopped.
class StopDeletedSessionsUseCase {
  StopDeletedSessionsUseCase(this._works, this._sessions);

  final WorkRepository _works;
  final SessionRepository _sessions;

  /// Longer than the Library's Undo snackbar stays up.
  static const undoWindow = Duration(seconds: 10);

  Future<void> call({String? settled}) async {
    final deleted = await _works.deleted();
    if (deleted.isEmpty) return;
    final now = _sessions.now();
    for (final r in await _sessions.all()) {
      final id = r.road.work.id;
      final at = deleted[id];
      if (at == null || r.at(now).stopped) continue;
      if (id == settled || !at.isAfter(now.subtract(undoWindow))) {
        await _sessions.add(r, SessionEventKind.stop);
      }
    }
  }
}
