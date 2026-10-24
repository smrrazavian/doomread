import 'dart:async';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class BooksViewModel extends ChangeNotifier {
  BooksViewModel(this._works, this._stopDeleted) {
    _subs = [
      _works.watchAll().listen((w) {
        _all = w;
        notifyListeners();
      }),
      _works.watchCurrent().listen((r) {
        _currentId = r?.work.id;
        notifyListeners();
      }),
    ];
  }

  final WorkRepository _works;
  final StopDeletedSessionsUseCase _stopDeleted;
  late final List<StreamSubscription<Object?>> _subs;

  List<Work> get works => _all;
  List<Work> _all = const [];

  String? get currentId => _currentId;
  String? _currentId;

  Future<void> makeCurrent(String id) => _works.setCurrent(id);

  /// Deletes [work]. A Session open on it runs on until Undo is gone,
  /// so Undo can bring both back.
  Future<void> delete(Work work) {
    // Gone from the list at once: a swiped-away tile can't wait for the
    // database to say so.
    _all = [..._all.where((w) => w.id != work.id)];
    notifyListeners();
    // A timer, not the snackbar closing: a snackbar on a tab left behind
    // never finishes closing. After an Undo it finds nothing to stop.
    _settling.add(
      Timer(
        StopDeletedSessionsUseCase.undoWindow,
        () => unawaited(_stopDeleted(settled: work.id)),
      ),
    );
    return _works.delete(work.id);
  }

  final _settling = <Timer>[];

  /// Undoes [delete], current again if it was.
  Future<void> restore(Work work, {required bool current}) =>
      _works.restore(work.id, current: current);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    // ponytail: a pending stop is dropped with the Library; the next
    // app start or sync stops it instead.
    for (final t in _settling) {
      t.cancel();
    }
    super.dispose();
  }
}
