import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class BooksViewModel extends ChangeNotifier {
  BooksViewModel(this._works, this._sessions) {
    _subs = [
      _works.watchAll().listen((w) {
        _all = w;
        notifyListeners();
      }),
      _works.watchCurrent().listen((r) {
        _currentId = r?.work.id;
        notifyListeners();
      }),
      _sessions.watchAll().listen((h) => _history = h),
    ];
  }

  final WorkRepository _works;
  final SessionRepository _sessions;
  late final List<StreamSubscription<Object?>> _subs;
  List<SessionRecord> _history = const [];

  List<Work> get works => _all;
  List<Work> _all = const [];

  String? get currentId => _currentId;
  String? _currentId;

  Future<void> makeCurrent(String id) => _works.setCurrent(id);

  /// Deletes [work], stopping any Session left open on it so nothing keeps
  /// running for a Work that's gone.
  Future<void> delete(Work work) async {
    // Gone from the list at once: a swiped-away tile can't wait for the
    // database to say so.
    _all = [..._all.where((w) => w.id != work.id)];
    notifyListeners();
    final now = _sessions.now();
    for (final r in _history) {
      if (r.road.work.id == work.id && !r.at(now).stopped) {
        await _sessions.add(r, SessionEventKind.stop);
      }
    }
    await _works.delete(work.id);
  }

  Future<void> restore(String id) => _works.restore(id);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
