import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart';

/// The Works the user is getting through, and which one is current. Tasks
/// are Works in the same table, kept apart here: they're never in the
/// Library and never current (ADR-0012).
class WorkRepository {
  WorkRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;

  /// Stamps `updatedAt`, which last-write-wins sync compares.
  final DateTime Function() _now;

  static const _currentKey = 'currentWork';

  /// The Library: every Work but the Tasks, the latest changed first.
  Stream<List<Work>> watchAll() =>
      (_db.select(_db.works)
            ..where((w) => w.deleted.not() & _notTask(w))
            ..orderBy([
              (w) => OrderingTerm.desc(w.updatedAt),
              // Same-second rows: the one added last first.
              (_) => OrderingTerm.desc(const CustomExpression<int>('rowid')),
            ]))
          .watch()
          .map((rows) => rows.map(toWork).toList());

  /// Whether any Work was ever added on this device, deleted ones and Tasks
  /// included.
  Future<bool> any() async =>
      await (_db.select(_db.works)..limit(1)).getSingleOrNull() != null;

  /// The current Work on its Road, or null before any Work exists.
  Stream<Road?> watchCurrent() => _current().watchSingleOrNull().map((row) {
    if (row == null) return null;
    final w = row.readTable(_db.works);
    return Road(toWork(w), position: w.position);
  });

  JoinedSelectStatement<HasResultSet, dynamic> _current() =>
      _db.select(_db.works).join([
        innerJoin(
          _db.settings,
          _db.settings.value.equalsExp(_db.works.id) &
              _db.settings.key.equals(_currentKey),
        ),
      ])..where(_db.works.deleted.not() & _notTask(_db.works));

  /// The Work with [id] on its Road, or null if there's no such Work.
  Stream<Road?> watchRoad(String id) =>
      (_db.select(_db.works)..where((w) => w.id.equals(id)))
          .watchSingleOrNull()
          .map((w) => w == null ? null : Road(toWork(w), position: w.position));

  /// Adds a Work and returns its id. The first Work becomes the current one.
  /// The numbers are in the [kind]'s unit.
  Future<String> add({
    required String title,
    required String author,
    required int totalPages,
    required List<int> checkpoints,
    WorkKind kind = WorkKind.paperBook,
  }) => _db.transaction(() async {
    final id = newId();
    final at = _now();
    await _db
        .into(_db.works)
        .insert(
          WorksCompanion.insert(
            id: id,
            title: title,
            author: author,
            kind: Value(kind),
            totalPages: totalPages,
            checkpoints: checkpoints.join(','),
            updatedAt: at,
            positionAt: Value(at),
          ),
        );
    if (await _db.setting(_currentKey) == null) await setCurrent(id);
    return id;
  });

  /// Changes a Work's details. Its kind stays, since the Position already
  /// saved is in that kind's unit.
  Future<void> edit(
    String id, {
    required String title,
    required String author,
    required int totalPages,
    required List<int> checkpoints,
  }) => (_db.update(_db.works)..where((w) => w.id.equals(id))).write(
    WorksCompanion(
      title: Value(title),
      author: Value(author),
      totalPages: Value(totalPages),
      checkpoints: Value(checkpoints.join(',')),
      updatedAt: Value(_now()),
    ),
  );

  Future<void> setCurrent(String id) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _currentKey, value: id),
      );

  /// Deletes a Work, leaving a tombstone for sync. If it was current, the
  /// most recently changed other Work becomes current.
  Future<void> delete(String id) => _db.transaction(() async {
    await _setDeleted(id, true);
    await keepOneCurrent();
  });

  /// Undoes [delete]. The Work becomes current again if it was, or if
  /// none is; a Task never does.
  Future<void> restore(String id, {bool current = false}) =>
      _db.transaction(() async {
        await _setDeleted(id, false);
        final row = await (_db.select(
          _db.works,
        )..where((w) => w.id.equals(id))).getSingle();
        if (row.kind == WorkKind.task) return;
        if (current || await _db.setting(_currentKey) == null) {
          await setCurrent(id);
        }
      });

  Future<void> _setDeleted(String id, bool deleted) {
    final at = _now();
    return (_db.update(_db.works)..where((w) => w.id.equals(id))).write(
      WorksCompanion(
        deleted: Value(deleted),
        deletedChangedAt: Value(at),
        updatedAt: Value(at),
      ),
    );
  }

  /// Each deleted Work's id, with when it was deleted.
  Future<Map<String, DateTime>> deleted() async => {
    for (final w in await (_db.select(
      _db.works,
    )..where((w) => w.deleted)).get())
      w.id: w.deletedChangedAt ?? w.updatedAt,
  };

  /// Makes the most recently changed Work current when none is, or the
  /// current one was deleted, here or by sync. With no Works left, none is.
  Future<void> keepOneCurrent() => _db.transaction(() async {
    if (await _current().getSingleOrNull() != null) return;
    final latest =
        await (_db.select(_db.works)
              ..where((w) => w.deleted.not() & _notTask(w))
              ..orderBy([(w) => OrderingTerm.desc(w.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (latest != null) {
      await setCurrent(latest.id);
      return;
    }
    await (_db.delete(
      _db.settings,
    )..where((s) => s.key.equals(_currentKey))).go();
  });

  static Expression<bool> _notTask($WorksTable w) =>
      w.kind.equalsValue(WorkKind.task).not();

  /// Every Task not deleted, in the order they were added.
  Stream<List<Task>> watchTasks() =>
      (_db.select(_db.works)
            ..where((w) => w.deleted.not() & w.kind.equalsValue(WorkKind.task))
            ..orderBy([
              (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
            ]))
          .watch()
          .map((rows) => rows.map(toTask).toList());

  /// Adds a Task and returns its id. It never becomes current.
  Future<String> addTask({
    required String name,
    DateTime? day,
    Duration? estimate,
  }) async {
    final id = newId();
    final at = _now();
    await _db
        .into(_db.works)
        .insert(
          WorksCompanion.insert(
            id: id,
            title: name,
            author: '',
            kind: const Value(WorkKind.task),
            totalPages: 1,
            checkpoints: '',
            updatedAt: at,
            positionAt: Value(at),
            day: Value(day),
            estimate: Value(estimate?.inMinutes),
          ),
        );
    return id;
  }

  /// Changes a Task's name, day and estimate.
  Future<void> editTask(
    String id, {
    required String name,
    DateTime? day,
    Duration? estimate,
  }) => (_db.update(_db.works)..where((w) => w.id.equals(id))).write(
    WorksCompanion(
      title: Value(name),
      day: Value(day),
      estimate: Value(estimate?.inMinutes),
      updatedAt: Value(_now()),
    ),
  );

  /// Marks a Task Done now, or with [done] false, undone again.
  Future<void> setDone(String id, {bool done = true}) {
    final at = _now();
    return (_db.update(_db.works)..where((w) => w.id.equals(id))).write(
      WorksCompanion(
        doneAt: Value(done ? at : null),
        doneChangedAt: Value(at),
        updatedAt: Value(at),
      ),
    );
  }

  static Task toTask(WorkRow w) => Task(
    id: w.id,
    name: w.title,
    day: w.day,
    estimate: w.estimate == null ? null : Duration(minutes: w.estimate!),
    doneAt: w.doneAt,
  );

  static Work toWork(WorkRow w) => Work(
    id: w.id,
    title: w.title,
    author: w.author,
    kind: w.kind,
    totalPages: w.totalPages,
    checkpoints: [
      for (final c in w.checkpoints.split(','))
        if (c.isNotEmpty) int.parse(c),
    ],
  );
}
