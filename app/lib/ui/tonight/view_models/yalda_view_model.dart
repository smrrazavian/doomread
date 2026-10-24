import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// What Yalda's poster needs, from the journal and the clock: whether
/// tonight is Yalda at all, what was read tonight and for how long, and the
/// House as it stands.
class YaldaViewModel extends ChangeNotifier {
  YaldaViewModel(this._sessions) {
    _sub = _sessions.watchAll().listen((all) {
      _history = all;
      notifyListeners();
    });
  }

  final SessionRepository _sessions;
  late final StreamSubscription<Object?> _sub;
  List<SessionRecord> _history = const [];

  /// Whether tonight is Shab-e Yalda.
  bool get yalda => yaldaAt(_sessions.now());

  /// Tonight's Sessions, by when they started, each with its start.
  List<(SessionRecord, DateTime)> _tonight(DateTime now) {
    final evening = eveningOf(now);
    return [
      for (final r in _history)
        if (r.at(now).startedAt case final at?
            when !at.isAfter(now) && eveningOf(at) == evening)
          (r, at),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
  }

  /// Whole minutes in tonight's Stretches, across every Session.
  int get minutes {
    final now = _sessions.now();
    return _tonight(now)
        .fold(
          Duration.zero,
          (sum, s) => sum + s.$1.at(now).readingBetween(s.$2, null),
        )
        .inMinutes;
  }

  /// The Work of tonight's last Session; null before any.
  Work? get work => _tonight(_sessions.now()).lastOrNull?.$1.road.work;

  /// The House on the poster: the user's Window is tonight's last Session,
  /// and every other light is from the journal.
  List<HouseWindow> get house {
    final now = _sessions.now();
    final last = _tonight(now).lastOrNull?.$1.id;
    return houseWindows(
      now: now,
      before: [
        for (final r in _history)
          if (r.id != last) ?r.at(now).startedAt,
      ],
    );
  }

  /// Tonight's date, for the poster's date line.
  DateTime get evening => eveningOf(_sessions.now());

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
