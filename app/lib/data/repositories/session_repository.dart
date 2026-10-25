import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart';

/// A Session as the journal holds it, with its Work as it stands now.
class SessionRecord {
  SessionRecord({
    required this.id,
    required this.road,
    required this.events,
    this.pages,
    this.note = '',
  });

  final String id;

  /// The Session's Work, at its current Position.
  final Road road;
  final List<SessionEvent> events;

  /// The page range it covered, once ended on End of the evening.
  final ({int from, int to})? pages;

  /// The Note written then; empty when there's none.
  final String note;

  /// The Position the Session started at. The Position itself moves on as
  /// Checkpoints are marked done; a Session from before Starts kept the
  /// page started where the Position still is.
  int get startPage =>
      events.where((e) => e.kind == SessionEventKind.start).firstOrNull?.page ??
      road.position;

  /// The Session derived from its journal, measured at [now].
  Session at(DateTime now) => Session.fromEvents(events, now: now);

  /// The same, with its Work and pages, for the domain rules in core.
  WorkSession measured(DateTime now) =>
      (road: road, session: at(now), pages: pages);
}

/// Every Session in [records], measured at [now] once, for the domain rules.
List<WorkSession> measured(Iterable<SessionRecord> records, DateTime now) => [
  for (final r in records) r.measured(now),
];

/// [records] without the Sessions on Tasks. Those are Working, and stay
/// out of reading's places: the Reading week, the House and the Reading
/// month.
Iterable<SessionRecord> withoutTasks(Iterable<SessionRecord> records) =>
    records.where((r) => r.road.work.kind != WorkKind.task);

/// Sessions: the append-only journal of what happened, and how each ended.
class SessionRepository {
  SessionRepository(this._db, {DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  final AppDatabase _db;

  /// The clock every Session event is stamped with.
  final DateTime Function() now;

  /// Starts a Session with [workId] and returns its id. The Start keeps
  /// the Position it began at, since marking a Checkpoint moves the
  /// Position before the Session ends.
  Future<String> start(String workId) => _db.transaction(() async {
    final id = newId();
    await _append(
      id,
      workId,
      SessionEventKind.start,
      page: (await _work(workId)).position,
    );
    return id;
  });

  /// Adds a Pause, Resume or Stop to [session]'s journal.
  Future<void> add(SessionRecord session, SessionEventKind kind) =>
      _append(session.id, session.road.work.id, kind);

  /// The user says they reached the next Checkpoint: it goes in the journal,
  /// where it makes the Planned break due, and the Position moves to it
  /// now. When it was an estimate, it moves to the [page] the chapter really
  /// ended on, if given, and the estimates after it spread on from there
  /// (see [reachCheckpoint]). Nothing happens when no Checkpoint is ahead
  /// short of the end; the end is the Finish, which End of the evening saves.
  Future<void> markCheckpoint(SessionRecord session, {int? page}) =>
      _db.transaction(() async {
        final workId = session.road.work.id;
        final row = await _work(workId);
        final work = WorkRepository.toWork(row);
        final next = Road(work, position: row.position).next;
        if (next == null || next >= work.totalPages) return;
        final reached = work.isEstimate(next)
            ? reachCheckpoint(work, position: row.position, page: page ?? next)
            : null;
        final at = reached == null ? next : page ?? next;
        await _append(
          session.id,
          workId,
          SessionEventKind.checkpoint,
          page: at,
        );
        final now = this.now();
        await (_db.update(_db.works)..where((w) => w.id.equals(workId))).write(
          WorksCompanion(
            position: Value(at),
            positionAt: Value(now),
            updatedAt: Value(now),
            checkpoints: reached == null
                ? const Value.absent()
                : Value(reached.checkpoints.join(',')),
            estimated: reached == null
                ? const Value.absent()
                : Value(reached.estimated),
          ),
        );
      });

  Future<WorkRow> _work(String id) =>
      (_db.select(_db.works)..where((w) => w.id.equals(id))).getSingle();

  Future<void> _append(
    String sessionId,
    String workId,
    SessionEventKind k, {
    int? page,
  }) => _db
      .into(_db.sessionEvents)
      .insert(
        SessionEventsCompanion.insert(
          id: newId(),
          sessionId: sessionId,
          workId: workId,
          kind: k,
          at: now(),
          page: Value(page),
        ),
      );

  /// The Session running on a Work other than [workId], if any. Only one
  /// runs at a time, so it's stopped before another starts.
  Future<SessionRecord?> runningElsewhere(String workId) async {
    final now = this.now();
    return (await all()).reversed.where((r) {
      final s = r.at(now);
      return r.road.work.id != workId && s.startedAt != null && !s.stopped;
    }).firstOrNull;
  }

  /// Every Session, oldest first.
  Stream<List<SessionRecord>> watchAll() => _all().watch().map(_records);

  /// The same, read once.
  Future<List<SessionRecord>> all() => _all().get().then(_records);

  JoinedSelectStatement<HasResultSet, dynamic> _all() {
    final e = _db.sessionEvents;
    return _db.select(e).join([
        innerJoin(_db.works, _db.works.id.equalsExp(e.workId)),
        leftOuterJoin(_db.notes, _db.notes.sessionId.equalsExp(e.sessionId)),
      ])
      // Same-second events keep the order they were written in.
      ..orderBy([
        OrderingTerm.asc(e.at),
        OrderingTerm.asc(const CustomExpression<int>('session_events.rowid')),
      ]);
  }

  List<SessionRecord> _records(List<TypedResult> rows) {
    final byId = <String, List<TypedResult>>{};
    for (final r in rows) {
      byId
          .putIfAbsent(r.readTable(_db.sessionEvents).sessionId, () => [])
          .add(r);
    }
    return [
      for (final MapEntry(key: id, value: rows) in byId.entries)
        _toRecord(id, rows),
    ];
  }

  SessionRecord _toRecord(String id, List<TypedResult> rows) {
    final work = rows.first.readTable(_db.works);
    final note = rows.first.readTableOrNull(_db.notes);
    return SessionRecord(
      id: id,
      road: Road(WorkRepository.toWork(work), position: work.position),
      events: [
        for (final r in rows)
          SessionEvent(
            r.readTable(_db.sessionEvents).kind,
            r.readTable(_db.sessionEvents).at,
            page: r.readTable(_db.sessionEvents).page,
          ),
      ],
      pages: note == null ? null : (from: note.fromPage, to: note.toPage),
      note: note?.body ?? '',
    );
  }

  /// Every Finish, the most recent first. Each is worked out from its Work's
  /// Position and Sessions; none is stored.
  Stream<List<Finish>> watchFinishes() => watchAll().map((all) {
    final now = this.now();
    final byWork = <String, List<SessionRecord>>{};
    // A Task's Done is no Finish: it adds no floor to the Building.
    for (final r in withoutTasks(all)) {
      byWork.putIfAbsent(r.road.work.id, () => []).add(r);
    }
    return newestFirst([
      for (final records in byWork.values)
        ?Finish.of(records.first.road, [
          for (final r in records)
            (session: r.at(now), toPage: r.pages?.to, note: r.note),
        ]),
    ]);
  });

  /// Ends [session] at [page]: moves the Work's Position there and saves the
  /// Note against the pages it covered, from where the Session started.
  Future<void> end(
    SessionRecord session, {
    required int page,
    String note = '',
  }) => _db.transaction(() async {
    final workId = session.road.work.id;
    // From the journal itself, so a record read before the Start can't
    // move the range.
    final start =
        await (_db.select(_db.sessionEvents)..where(
              (e) =>
                  e.sessionId.equals(session.id) &
                  e.kind.equalsValue(SessionEventKind.start),
            ))
            .get();
    final from = start.firstOrNull?.page ?? (await _work(workId)).position;
    final at = now();
    await _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            id: newId(),
            sessionId: session.id,
            workId: workId,
            fromPage: from,
            toPage: page,
            body: note.trim(),
            updatedAt: at,
          ),
        );
    await (_db.update(_db.works)..where((w) => w.id.equals(workId))).write(
      WorksCompanion(
        position: Value(page),
        positionAt: Value(at),
        updatedAt: Value(at),
      ),
    );
  });
}
