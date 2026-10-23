import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart';

/// The Works the user is getting through, and which one is current.
class WorkRepository {
  WorkRepository(this._db);

  final AppDatabase _db;

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

  /// Adds a Work and returns its id. The first Work becomes the current one.
  Future<String> add({
    required String title,
    required String author,
    required int totalPages,
    required List<int> checkpoints,
  }) => _db.transaction(() async {
    final id = newId();
    await _db
        .into(_db.works)
        .insert(
          WorksCompanion.insert(
            id: id,
            title: title,
            author: author,
            totalPages: totalPages,
            checkpoints: checkpoints.join(','),
            updatedAt: DateTime.now(),
          ),
        );
    final current = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_currentKey))).getSingleOrNull();
    if (current == null) await setCurrent(id);
    return id;
  });

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
      updatedAt: Value(DateTime.now()),
    ),
  );

  Future<void> setCurrent(String id) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _currentKey, value: id),
      );

  static Work toWork(WorkRow w) => Work(
    id: w.id,
    title: w.title,
    author: w.author,
    totalPages: w.totalPages,
    checkpoints: [
      for (final c in w.checkpoints.split(','))
        if (c.isNotEmpty) int.parse(c),
    ],
  );
}
