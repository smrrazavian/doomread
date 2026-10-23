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
      (_db.select(_db.works)..orderBy([(w) => OrderingTerm.desc(w.updatedAt)]))
          .watch()
          .map((rows) => rows.map(toWork).toList());

  /// The current Work on its Road, or null before any Work exists.
  Stream<Road?> watchCurrent() {
    final query = _db.select(_db.works).join([
      innerJoin(
        _db.settings,
        _db.settings.value.equalsExp(_db.works.id) &
            _db.settings.key.equals(_currentKey),
      ),
    ]);
    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final w = row.readTable(_db.works);
      return Road(toWork(w), position: w.position);
    });
  }

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
            updatedAt: _now(),
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

  /// Makes the most recently changed Work current when none is, as when
  /// sync brings the first Works to a new device.
  Future<void> keepOneCurrent() => _db.transaction(() async {
    if (await _db.setting(_currentKey) != null) return;
    final latest =
        await (_db.select(_db.works)
              ..orderBy([(w) => OrderingTerm.desc(w.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (latest != null) await setCurrent(latest.id);
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
