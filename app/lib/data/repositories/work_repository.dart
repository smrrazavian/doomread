import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart';

/// The Works the user is getting through, and which one is current.
class WorkRepository {
  WorkRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;

  /// Stamps `updatedAt`, which last-write-wins sync compares.
  final DateTime Function() _now;

  static const _currentKey = 'currentWork';

  Stream<List<Work>> watchAll() =>
      (_db.select(_db.works)
            ..where((w) => w.deleted.not())
            ..orderBy([
              (w) => OrderingTerm.desc(w.updatedAt),
              // Same-second rows: the one added last first.
              (_) => OrderingTerm.desc(const CustomExpression<int>('rowid')),
            ]))
          .watch()
          .map((rows) => rows.map(toWork).toList());

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
      ])..where(_db.works.deleted.not());

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
  /// none is.
  Future<void> restore(String id, {bool current = false}) =>
      _db.transaction(() async {
        await _setDeleted(id, false);
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
              ..where((w) => w.deleted.not())
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
