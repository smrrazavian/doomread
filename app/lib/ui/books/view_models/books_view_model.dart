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

  /// Deletes [work]. A Session open on it runs on until [settle], so Undo
  /// can bring both back.
  Future<void> delete(Work work) {
    // Gone from the list at once: a swiped-away tile can't wait for the
    // database to say so.
    _all = [..._all.where((w) => w.id != work.id)];
    notifyListeners();
    return _works.delete(work.id);
  }

  /// Undoes [delete], current again if it was.
  Future<void> restore(Work work, {required bool current}) =>
      _works.restore(work.id, current: current);

  /// The chance to undo deleting [work] is gone: stops its open Sessions.
  Future<void> settle(Work work) => _stopDeleted(settled: work.id);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
