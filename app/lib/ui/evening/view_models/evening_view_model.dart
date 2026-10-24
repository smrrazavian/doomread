import 'dart:async';
import 'dart:math';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// End of the evening: the page the user stopped at, and their Note.
class EveningViewModel extends ChangeNotifier {
  EveningViewModel(this._sessions, this.id) {
    save = Command1(_save);
    _sub = _sessions.watchAll().listen((all) {
      // Read once: saving moves the Position, which must not change what
      // this screen shows as the start.
      if (_record != null) return;
      _record = all.where((r) => r.id == id).firstOrNull;
      _before = all.where((r) => r.id != id).toList();
      notifyListeners();
    });
  }

  final SessionRepository _sessions;
  final String id;
  late final StreamSubscription<List<SessionRecord>> _sub;
  List<SessionRecord> _before = const [];

  /// Null until the journal has loaded.
  SessionRecord? get record => _record;
  SessionRecord? _record;

  /// This Session as saved, with the pages it covered, measured now: what
  /// tonight's receipt shows. Null if it isn't in the journal.
  Future<(SessionRecord, Session)?> saved() async {
    final record = (await _sessions.all()).where((r) => r.id == id).firstOrNull;
    return record == null ? null : (record, record.at(_sessions.now()));
  }

  /// Saves the page and the Note.
  late final Command1<void, ({int? page, String note})> save;

  /// What's wrong with what the user last tried to save.
  Set<SessionEndProblem> get problems => _problems;
  Set<SessionEndProblem> _problems = const {};

  /// The longest Stretch in this Session.
  Duration get longestTonight =>
      record?.at(_sessions.now()).longestStretch ?? Duration.zero;

  /// Whether the saved page reached the end of the Work: the Finish. Saving
  /// the last page again on a Work already finished isn't a new one.
  bool get finished => _finished;
  bool _finished = false;

  /// Whether this Session grew the Longest stretch, for reading or for
  /// watching, whichever its Work is.
  bool get newBest {
    final record = this.record;
    if (record == null) return false;
    final now = _sessions.now();
    final before = alike(
      measured(_before, now),
      watched: record.road.work.kind.watched,
    );
    return isNewBest(record.at(now), before);
  }

  /// Where the user most likely stopped, to prefill the page: the Position
  /// plus tonight's reading at their pace for this Work. Without a pace it's
  /// the Position itself. It stays short of the end, since the Finish is its
  /// own action.
  int get suggested {
    final record = this.record!;
    final from = record.road.position;
    final session = record.at(_sessions.now());
    final perPage = timePerPage(
      sittingsOf(record.road.work, measured(_before, _sessions.now())),
    );
    if (perPage == null || perPage <= Duration.zero) return from;
    final tonight = session.readingBetween(session.startedAt, null);
    final guess = from + tonight.inMicroseconds ~/ perPage.inMicroseconds;
    return max(from, min(guess, record.road.work.totalPages - 1));
  }

  /// [value] moved one step by the −/+ buttons ([by] is -1 or 1), kept
  /// between where tonight started and the end. A minute for a timed Work,
  /// one page or episode otherwise; with nothing readable, the suggestion.
  int step(int? value, int by) {
    final road = record!.road;
    final unit = road.work.kind.unit == WorkUnit.second ? 60 : 1;
    final next = (value ?? suggested) + by * unit;
    return next.clamp(road.position, road.work.totalPages);
  }

  Future<Result<void>> _save(({int? page, String note}) input) async {
    final record = this.record!;
    _problems = SessionEndDraft(
      page: input.page,
      fromPage: record.road.position,
      totalPages: record.road.work.totalPages,
    ).problems;
    notifyListeners();
    if (_problems.isNotEmpty) {
      return Result.error(InvalidSessionEnd(_problems));
    }
    await _sessions.end(record, page: input.page!, note: input.note);
    _finished =
        !record.road.finished && input.page! >= record.road.work.totalPages;
    return const Result.ok(null);
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

class InvalidSessionEnd implements Exception {
  InvalidSessionEnd(this.problems);
  final Set<SessionEndProblem> problems;
}
