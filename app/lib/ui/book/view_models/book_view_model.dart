import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// One Note on the Book page, with the pages its Session covered.
typedef BookNote = ({int from, int to, String text});

/// The Book page: a Work's Road and the user's Notes about it.
class BookViewModel extends ChangeNotifier {
  BookViewModel(WorkRepository works, SessionRepository sessions, String id) {
    _subs = [
      works.watchRoad(id).listen((r) {
        _road = r;
        notifyListeners();
      }),
      sessions.watchAll().listen((all) {
        _notes = [
          for (final r in all.reversed)
            if (r.pages case final p?
                when r.road.work.id == id && r.note.isNotEmpty)
              (from: p.from, to: p.to, text: r.note),
        ];
        notifyListeners();
      }),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;

  /// The Work on its Road; null until it has loaded.
  Road? get road => _road;
  Road? _road;

  /// The Notes the user wrote, newest first. A Session ended without one
  /// leaves nothing here.
  List<BookNote> get notes => _notes;
  List<BookNote> _notes = const [];

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
