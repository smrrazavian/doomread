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

  /// The Session derived from its journal, measured at [now].
  Session at(DateTime now) => Session.fromEvents(events, now: now);
}

/// Sessions: the append-only journal of what happened, and how each ended.
class SessionRepository {
  SessionRepository(this._db, {DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  final AppDatabase _db;

  /// The clock every Session event is stamped with.
  final DateTime Function() now;

  /// Starts a Session with [workId] and returns its id.
  Future<String> start(String workId) async {
    final id = newId();
    await _append(id, workId, SessionEventKind.start);
    return id;
  }

  /// Adds a Pause, Resume or Stop to [session]'s journal.
  Future<void> add(SessionRecord session, SessionEventKind kind) =>
      _append(session.id, session.road.work.id, kind);

  Future<void> _append(String sessionId, String workId, SessionEventKind k) =>
      _db
          .into(_db.sessionEvents)
          .insert(
            SessionEventsCompanion.insert(
              id: newId(),
              sessionId: sessionId,
              workId: workId,
              kind: k,
              at: now(),
            ),
          );

  /// Every Session, oldest first.
  Stream<List<SessionRecord>> watchAll() {
    final e = _db.sessionEvents;
    final query =
        _db.select(e).join([
            innerJoin(_db.works, _db.works.id.equalsExp(e.workId)),
            leftOuterJoin(
              _db.notes,
              _db.notes.sessionId.equalsExp(e.sessionId),
            ),
          ])
          // Same-second events keep the order they were written in.
          ..orderBy([
            OrderingTerm.asc(e.at),
            OrderingTerm.asc(
              const CustomExpression<int>('session_events.rowid'),
            ),
          ]);
    return query.watch().map((rows) {
      final byId = <String, List<TypedResult>>{};
      for (final r in rows) {
        byId.putIfAbsent(r.readTable(e).sessionId, () => []).add(r);
      }
      return [
        for (final MapEntry(key: id, value: rows) in byId.entries)
          _toRecord(id, rows),
      ];
    });
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
    for (final r in all) {
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
  /// Note against the pages it covered.
  Future<void> end(
    SessionRecord session, {
    required int page,
    String note = '',
  }) => _db.transaction(() async {
    final workId = session.road.work.id;
    final work = await (_db.select(
      _db.works,
    )..where((w) => w.id.equals(workId))).getSingle();
    final at = now();
    await _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            id: newId(),
            sessionId: session.id,
            workId: workId,
            fromPage: work.position,
            toPage: page,
            body: note.trim(),
            updatedAt: at,
          ),
        );
    await (_db.update(_db.works)..where((w) => w.id.equals(workId))).write(
      WorksCompanion(position: Value(page), updatedAt: Value(at)),
    );
  });
}
